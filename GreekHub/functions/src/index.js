const functions = require("firebase-functions");
const admin     = require("firebase-admin");

admin.initializeApp();
const db  = admin.firestore();
const fcm = admin.messaging();

// ─── Helpers ──────────────────────────────────────────────────────────────────

async function getFCMTokensForChapter(chapter) {
  const snap = await db.collection("users")
    .where("chapter", "==", chapter)
    .where("isActive", "==", true)
    .get();

  return snap.docs
    .map(d => d.data().fcmToken)
    .filter(Boolean);
}

async function getOfficerTokensForChapter(chapter) {
  const officerRoles = ["Executive Chair", "Vice President", "Treasurer", "Secretary"];
  const snap = await db.collection("users")
    .where("chapter", "==", chapter)
    .where("isActive", "==", true)
    .get();

  return snap.docs
    .filter(d => officerRoles.includes(d.data().role))
    .map(d => d.data().fcmToken)
    .filter(Boolean);
}

async function saveNotification(userId, type, title, body, deepLink = null) {
  const notif = {
    id:       db.collection("notifications").doc().id,
    userId,
    type,
    title,
    body,
    deepLink,
    isRead:   false,
    sentAt:   admin.firestore.FieldValue.serverTimestamp(),
  };
  await db.collection("notifications").doc(notif.id).set(notif);
  return notif;
}

async function sendToTokens(tokens, title, body, data = {}) {
  if (!tokens.length) return;

  const message = {
    notification: { title, body },
    data:         { ...data, click_action: "FLUTTER_NOTIFICATION_CLICK" },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: 1,
        },
      },
    },
  };

  const chunks = [];
  for (let i = 0; i < tokens.length; i += 500) {
    chunks.push(tokens.slice(i, i + 500));
  }
  for (const chunk of chunks) {
    await fcm.sendEachForMulticast({ ...message, tokens: chunk });
  }
}

// ─── Trigger 1: New Officer Post ──────────────────────────────────────────────
// Fires when a post with isOfficerPost=true is created

exports.onNewOfficerPost = functions.firestore
  .document("posts/{postId}")
  .onCreate(async (snap, ctx) => {
    const post = snap.data();
    if (!post.isOfficerPost) return null;

    const tokens = await getFCMTokensForChapter(post.chapter);
    const title  = "New announcement";
    const body   = `${post.authorName}: ${post.content.slice(0, 80)}`;

    await sendToTokens(tokens, title, body, {
      type:     "new_post",
      deepLink: `greekhub://feed/${ctx.params.postId}`,
    });

    // Write notification docs for each member
    const snap2 = await db.collection("users")
      .where("chapter", "==", post.chapter)
      .where("isActive", "==", true)
      .get();

    const batch = db.batch();
    snap2.docs.forEach(userDoc => {
      if (userDoc.id === post.authorId) return; // skip author
      const ref = db.collection("notifications").doc();
      batch.set(ref, {
        id:       ref.id,
        userId:   userDoc.id,
        type:     "new_post",
        title,
        body,
        deepLink: `greekhub://feed/${ctx.params.postId}`,
        isRead:   false,
        sentAt:   admin.firestore.FieldValue.serverTimestamp(),
      });
    });
    return batch.commit();
  });

// ─── Trigger 2: Event Check-In → Points Awarded ───────────────────────────────

exports.onCheckIn = functions.firestore
  .document("events/{eventId}/checkIns/{userId}")
  .onCreate(async (snap, ctx) => {
    const checkIn    = snap.data();
    const { userId } = ctx.params;
    if (!checkIn.pointsAwarded) return null;

    const userSnap = await db.collection("users").doc(userId).get();
    if (!userSnap.exists) return null;
    const user = userSnap.data();
    if (!user.fcmToken) return null;

    const title = `+${checkIn.pointsAwarded} points awarded!`;
    const body  = `QR check-in: ${checkIn.eventTitle || "event"}`;

    await sendToTokens([user.fcmToken], title, body, { type: "points_awarded" });
    await saveNotification(userId, "points_awarded", title, body);
    return null;
  });

// ─── Trigger 3: Manual Points Award ──────────────────────────────────────────

exports.onPointsAwarded = functions.firestore
  .document("pointsLog/{logId}")
  .onCreate(async (snap) => {
    const log = snap.data();
    if (log.awardedBy === "system") return null; // handled by onCheckIn

    const userSnap = await db.collection("users").doc(log.userId).get();
    if (!userSnap.exists) return null;
    const user = userSnap.data();
    if (!user.fcmToken) return null;

    const isPositive = log.amount >= 0;
    const title = isPositive
      ? `+${log.amount} points from ${log.awardedBy}`
      : `${log.amount} points — ${log.reason}`;
    const body = log.note || log.reason;

    await sendToTokens([user.fcmToken], title, body, { type: "points_awarded" });
    await saveNotification(log.userId, "points_awarded", title, body);
    return null;
  });

// ─── Trigger 4: Event Reminder (1 hour before) ───────────────────────────────
// Scheduled function — runs every hour and finds events starting in ~60 min

exports.eventReminders = functions.pubsub
  .schedule("every 60 minutes")
  .onRun(async () => {
    const now    = admin.firestore.Timestamp.now();
    const oneHr  = new Date(now.toDate().getTime() + 60 * 60 * 1000);
    const twoHr  = new Date(now.toDate().getTime() + 120 * 60 * 1000);

    const snap = await db.collection("events")
      .where("date", ">=", admin.firestore.Timestamp.fromDate(oneHr))
      .where("date", "<=", admin.firestore.Timestamp.fromDate(twoHr))
      .get();

    for (const doc of snap.docs) {
      const event   = doc.data();
      const tokens  = await getFCMTokensForChapter(event.chapter);
      const title   = `${event.title} in 1 hour`;
      const body    = `${event.location}${event.pointValue > 0 ? ` · +${event.pointValue} pts` : ""}`;

      await sendToTokens(tokens, title, body, {
        type:     "event_reminder",
        deepLink: `greekhub://event/${doc.id}`,
      });
    }
    return null;
  });

// ─── Trigger 5: New Chat Message (badge update) ───────────────────────────────

exports.onNewMessage = functions.firestore
  .document("channels/{channelId}/messages/{messageId}")
  .onCreate(async (snap, ctx) => {
    const msg = snap.data();
    const { channelId } = ctx.params;

    const channelSnap = await db.collection("channels").doc(channelId).get();
    if (!channelSnap.exists) return null;
    const channel = channelSnap.data();

    // Only notify for officer-only or general channels; skip noisy channels
    const notifyChannels = ["general", "events", "officers"];
    if (!notifyChannels.includes(channel.name)) return null;

    const tokens = channel.isOfficerOnly
      ? await getOfficerTokensForChapter(channel.chapter)
      : await getFCMTokensForChapter(channel.chapter);

    const filtered = tokens.filter(t => t !== undefined);
    if (!filtered.length) return null;

    const title = `#${channel.name}`;
    const body  = `${msg.authorName}: ${msg.text.slice(0, 80)}`;

    await sendToTokens(filtered, title, body, {
      type:     "chat_message",
      deepLink: `greekhub://chat/${channelId}`,
    });
    return null;
  });

// ─── Trigger 6: Bid Offered to PNM ───────────────────────────────────────────

exports.onBidOffered = functions.firestore
  .document("pnms/{pnmId}")
  .onUpdate(async (change, ctx) => {
    const before = change.before.data();
    const after  = change.after.data();

    if (before.status === after.status) return null;
    if (after.status !== "Bid Offered")  return null;

    const officerTokens = await getOfficerTokensForChapter(after.chapter);
    const title = `Bid offered to ${after.firstName} ${after.lastName}`;
    const body  = `Rush update · ${after.major}, ${after.year}`;

    await sendToTokens(officerTokens, title, body, {
      type:     "rush_update",
      deepLink: `greekhub://rush/${ctx.params.pnmId}`,
    });
    return null;
  });

// ─── Trigger 7: Dues Overdue Reminder (daily at 9am) ─────────────────────────

exports.duesOverdueReminder = functions.pubsub
  .schedule("every day 09:00")
  .timeZone("America/New_York")
  .onRun(async () => {
    const now  = admin.firestore.Timestamp.now();
    const snap = await db.collection("dues")
      .where("status", "in", ["Unpaid", "Partial"])
      .where("dueDate", "<=", now)
      .get();

    for (const doc of snap.docs) {
      const record   = doc.data();
      const userSnap = await db.collection("users").doc(record.userId).get();
      if (!userSnap.exists) continue;
      const user = userSnap.data();
      if (!user.fcmToken) continue;

      const balance = (record.amount - record.amountPaid).toFixed(2);
      const title   = `Dues overdue — $${balance} remaining`;
      const body    = `${record.semester} dues were due on ${new Date(record.dueDate.toDate()).toLocaleDateString()}`;

      await sendToTokens([user.fcmToken], title, body, { type: "dues_overdue" });

      // Mark as overdue in Firestore
      await doc.reference.update({ status: "Overdue" });
    }
    return null;
  });

// ─── Trigger 8: Auto-Award Badges ────────────────────────────────────────────
// Re-evaluate badges whenever a user's points field changes

exports.onPointsUpdated = functions.firestore
  .document("users/{userId}")
  .onUpdate(async (change, ctx) => {
    const before = change.before.data();
    const after  = change.after.data();
    if (before.points === after.points) return null;

    const { userId } = ctx.params;
    const points      = after.points || 0;

    // Century Club badge
    if (points >= 100) {
      await awardBadgeIfNotEarned(userId, "b_century", "system");
    }

    return null;
  });

async function awardBadgeIfNotEarned(userId, badgeId, awardedBy) {
  const ref  = db.collection("users").document(userId)
                 .collection("badges").document(badgeId);
  // Use a sub-path-safe approach
  const badgePath = db.doc(`users/${userId}/badges/${badgeId}`);
  const snap = await badgePath.get();
  if (snap.exists) return; // already earned

  await badgePath.set({
    badgeId,
    awardedBy,
    earnedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Notify user
  const userSnap = await db.collection("users").doc(userId).get();
  const user     = userSnap.data();
  if (!user?.fcmToken) return;

  const badgeNames = {
    b_century:   "Century Club",
    b_service10: "Service Star",
    b_officer:   "Officer",
  };
  const name  = badgeNames[badgeId] || "New Badge";
  const title = `🏅 Badge earned: ${name}`;
  const body  = "Tap to view your badge shelf";

  await sendToTokens([user.fcmToken], title, body, {
    type:     "badge_earned",
    badgeId,
    deepLink: "greekhub://profile/badges",
  });
}
