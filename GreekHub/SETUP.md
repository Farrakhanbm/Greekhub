# GreekHub — Complete Setup Guide
### All Phases: MVP → Firebase → Phase 2 → Phase 3 → Phase 4

---

## Table of Contents
1. [Project Overview](#overview)
2. [Xcode Setup](#xcode)
3. [Firebase Project Setup](#firebase)
4. [Phase 1 — MVP](#phase1)
5. [Phase 2 — Points, QR Check-In, Officer Dashboard](#phase2)
6. [Phase 3 — Rush, Notifications, Media Wall](#phase3)
7. [Phase 4 — Dues, Alumni, Badges](#phase4)
8. [Cloud Functions Deployment](#functions)
9. [Firestore Indexes](#indexes)
10. [File Reference](#files)

---

## 1. Project Overview <a name="overview"></a>

GreekHub is a full-stack iOS app for Greek chapter management. It is built with:

- **SwiftUI** — iOS 16+, dark mode, MVVM architecture
- **Firebase Auth** — email/password authentication
- **Firestore** — real-time database with chapter-scoped data
- **Firebase Storage** — photo uploads for media wall
- **Firebase Cloud Messaging (FCM)** — push notifications
- **Cloud Functions (Node.js 20)** — server-side triggers

### Role system
| Role | Access |
|------|--------|
| Executive Chair | All officer tools + Rush + Dues + Badges + Dashboard |
| Vice President / Treasurer / Secretary | Same as Executive Chair |
| Member | Feed, Events, Chat, Media, Roster, Profile, Badges |
| Pledge | Same as Member |

---

## 2. Xcode Setup <a name="xcode"></a>

### Step 1 — Create the Xcode project

1. Open Xcode → **File → New → Project**
2. Choose **iOS → App**
3. Configure:
   - **Product Name:** `GreekHub`
   - **Bundle Identifier:** `com.greekhub.app`
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Minimum Deployments:** iOS 16.0
4. Click **Create** and save the project

### Step 2 — Delete the default file

Delete `ContentView.swift` (it will conflict with our entry point).

### Step 3 — Add source files

Drag the entire `GreekHub/` folder from this zip into your Xcode project.  
When prompted: ✅ **Copy items if needed** · ✅ **Create groups** · Target: GreekHub

Your project navigator should look like this:
```
GreekHub/
├── App/
│   └── GreekHubApp.swift
├── Models/
│   ├── Models.swift
│   ├── Phase2Models.swift
│   ├── Phase3Models.swift
│   └── Phase4Models.swift
├── Services/
│   ├── AuthService.swift
│   ├── FirestoreService.swift
│   ├── FirestoreExtensions.swift
│   ├── FirestorePhase2.swift
│   ├── FirestorePhase3.swift
│   └── FirestorePhase4.swift
├── ViewModels/
│   ├── ViewModels.swift
│   ├── Phase2ViewModels.swift
│   ├── Phase3ViewModels.swift
│   └── Phase4ViewModels.swift
├── Views/
│   ├── MainTabView.swift
│   ├── Auth/LoginView.swift
│   ├── Feed/FeedView.swift
│   ├── Events/EventsView.swift
│   ├── Chat/ChatView.swift
│   ├── Roster/RosterView.swift
│   ├── Profile/ProfileView.swift
│   ├── Officer/OfficerDashboardView.swift
│   ├── Officer/OfficerPointsView.swift
│   ├── CheckIn/QRCheckInView.swift
│   ├── Rush/RushView.swift
│   ├── Media/MediaWallView.swift
│   ├── Notifications/NotificationsView.swift
│   ├── Dues/DuesView.swift
│   ├── Alumni/AlumniView.swift
│   └── Badges/BadgesView.swift
└── Resources/
    └── Theme.swift
```

### Step 4 — Add Firebase SDK via Swift Package Manager

1. Xcode → **File → Add Package Dependencies**
2. Paste URL: `https://github.com/firebase/firebase-ios-sdk.git`
3. Version rule: **Up to Next Major** from `10.25.0`
4. Add these products to the **GreekHub** target:
   - `FirebaseAuth`
   - `FirebaseFirestore`
   - `FirebaseStorage`
   - `FirebaseMessaging`

### Step 5 — Add Push Notification capabilities

1. Select the **GreekHub** target → **Signing & Capabilities**
2. Click **+ Capability** and add:
   - **Push Notifications**
   - **Background Modes** → check **Remote notifications**

### Step 6 — Add camera permission (for QR scanning)

In `Info.plist`, add:
```xml
<key>NSCameraUsageDescription</key>
<string>GreekHub uses your camera to scan event check-in QR codes.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>GreekHub uses your photo library to upload photos to the media wall.</string>
```

---

## 3. Firebase Project Setup <a name="firebase"></a>

### Step 1 — Create the project

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. **Add project** → name it `GreekHub` → Continue
3. Disable Google Analytics (optional) → **Create project**

### Step 2 — Add your iOS app

1. Console home → **Add app** → iOS icon
2. **iOS bundle ID:** `com.greekhub.app`
3. **App nickname:** `GreekHub iOS`
4. Click **Register app**
5. **Download `GoogleService-Info.plist`**
6. Drag it into the root of your Xcode project (check **Copy items if needed**)

### Step 3 — Enable Authentication

Console → **Authentication** → **Get started** → **Sign-in method**  
Enable: ✅ **Email/Password**

### Step 4 — Create Firestore Database

Console → **Firestore Database** → **Create database**
- Select **Start in production mode**
- Choose region: **us-east1** (recommended for East Coast chapters)
- Click **Enable**

### Step 5 — Enable Firebase Storage

Console → **Storage** → **Get started**
- Select **Start in production mode**
- Same region as Firestore
- Click **Done**

### Step 6 — Deploy security rules

Install Firebase CLI (requires Node.js):
```bash
npm install -g firebase-tools
firebase login
firebase init   # select Firestore + Storage + Functions, link to your project
```

Then deploy all rules at once:
```bash
firebase deploy --only firestore:rules,storage
```

Or paste the contents of `firestore.rules` and `storage.rules` directly in the Firebase console.

### Step 7 — Configure APNs for push notifications

1. Go to [developer.apple.com](https://developer.apple.com) → **Certificates, IDs & Profiles**
2. **Keys** → **+** → check **Apple Push Notifications service (APNs)**
3. Name it `GreekHub APNs`, click **Continue** → **Register** → **Download** the `.p8` file
4. Firebase Console → **Project Settings** (gear icon) → **Cloud Messaging** tab
5. Under **Apple app configuration** → **APNs Authentication Key** → **Upload**
6. Upload the `.p8` file, enter your **Key ID** and **Team ID** (from Apple Developer)

### Step 8 — Register for push in your AppDelegate

Add this to `GreekHubApp.swift` or create an `AppDelegate.swift`:
```swift
import FirebaseMessaging
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate {
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        Messaging.messaging().token { token, error in
            guard let token, error == nil else { return }
            Task {
                try? await FirestoreService.shared.saveFCMToken(
                    token, userId: AuthService.shared.currentUID ?? ""
                )
            }
        }
    }
}
```

And in `GreekHubApp.swift`:
```swift
@UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
```

---

## 4. Phase 1 — MVP <a name="phase1"></a>

**What's included:**
- Login / Register / Forgot Password
- Chapter Feed with posts, likes, comments, officer announcements
- Events with RSVP, type filters, full detail view
- Chat — channel list and real-time messaging
- Roster — searchable member list with role filters and member detail
- Profile with stats and leaderboard sheet
- Custom dark tab bar

**First run checklist:**
- [ ] `GoogleService-Info.plist` added to Xcode project
- [ ] Firebase Auth Email/Password enabled
- [ ] Firestore database created
- [ ] App builds and runs on simulator or device
- [ ] Register a test account via the app's "Request Access" flow
- [ ] Verify user document appears in Firestore `users` collection

**Seed default chat channels** (run once after first officer registers):
```swift
// Add this temporarily to OfficerHubView.onAppear or a setup button:
Task {
    try? await FirestoreService.shared.createDefaultChannels(
        chapter: "Alpha Phi Alpha — Theta Chapter"
    )
}
```

---

## 5. Phase 2 — Points, QR Check-In, Officer Dashboard <a name="phase2"></a>

**What's included:**
- Points leaderboard backed by Firestore
- Officer points manager — award/deduct with reason, amount stepper, audit log
- QR check-in — officer displays event QR, member scans it to auto-earn points
- Officer dashboard — attendance bar charts, top performers, at-risk members, points distribution
- Executive Chair role (replaces "President" — legacy data auto-migrated on read)

**Firestore indexes needed** (Firestore will show an error link to create these automatically):

| Collection | Fields |
|-----------|--------|
| `posts` | `chapter` ASC + `postedAt` DESC |
| `events` | `chapter` ASC + `date` ASC |
| `users` | `chapter` ASC + `name` ASC |
| `pointsLog` | `userId` ASC + `awardedAt` DESC |
| `pointsLog` | `chapter` ASC + `awardedAt` DESC |

**How QR Check-In works:**
1. Officer opens an event → taps the QR icon → a QR code is generated using CoreImage
2. The QR encodes a JSON payload: `{ eventId, eventTitle, pointValue, chapter }`
3. Member taps "Scan to Check In" on the Events tab → camera opens
4. On successful scan: check-in recorded, RSVP auto-created, points awarded atomically via Firestore transaction
5. Duplicate scans are blocked — second scan shows "Already checked in"

---

## 6. Phase 3 — Rush, Notifications, Media Wall <a name="phase3"></a>

**What's included:**
- Rush/Recruitment mode (officer-only) — PNM pipeline, officer voting, bid tracking
- Push notifications via FCM — event reminders, points awards, new posts, chat messages, bid offers
- Media Wall — 3-column photo grid with Firebase Storage uploads, full-screen viewer, likes
- 6 Cloud Functions (see Section 8)

**Rush data structure:**
```
pnms/{pnmId}
  ├── firstName, lastName, email, phone, major, year, gpa
  ├── status: Pending | Interviewing | Bid Offered | Accepted | Declined | Withdrawn
  ├── addedBy, addedAt, chapter
  ├── votes/{officerId}         ← one vote per officer
  │     ├── score (1–10)
  │     ├── recommendation: Yes | No | Abstain
  │     └── note
  └── notes/{noteId}            ← officer observations
```

**Add Rush rules to Firestore:**
```javascript
match /pnms/{pnmId} {
  allow read, write: if isSignedIn() && isOfficer();
  match /votes/{officerId} {
    allow read, write: if isSignedIn() && isOfficer();
  }
  match /notes/{noteId} {
    allow read, write: if isSignedIn() && isOfficer();
  }
}
```

**Media indexes needed:**
| Collection | Fields |
|-----------|--------|
| `media` | `chapter` ASC + `uploadedAt` DESC |

**Storage rules** — already in `storage.rules`:
- Images only (MIME type check)
- 10MB max per upload
- Auth required

---

## 7. Phase 4 — Dues, Alumni, Badges <a name="phase4"></a>

**What's included:**
- Dues dashboard — semester dues, collection progress bar, per-member payment recording
- Payment methods: Stripe (manual confirm), Cash App, Zelle, Venmo, Cash
- Dues waiver with officer note
- Pledge auto-discount (60% of standard rate)
- Alumni network — searchable directory, mentor filter, LinkedIn + email deep links
- Gamification badges — 10 badges, earned/locked shelf, progress ring, officer award tool
- 2 additional Cloud Functions: dues overdue reminders, auto-award Century Club badge

**Add Dues + Alumni rules to Firestore:**
```javascript
match /dues/{duesId} {
  allow read: if isSignedIn() &&
    (isOfficer() || resource.data.userId == request.auth.uid);
  allow create, update, delete: if isSignedIn() && isOfficer();
}
match /alumni/{alumniId} {
  allow read:  if isSignedIn();
  allow write: if isSignedIn() && isOfficer();
}
```

**Firestore indexes needed:**
| Collection | Fields |
|-----------|--------|
| `dues` | `chapter` ASC + `semester` ASC + `userName` ASC |
| `alumni` | `chapter` ASC + `graduationYear` DESC |

**Badge data structure:**
```
users/{uid}/badges/{badgeId}
  ├── badgeId
  ├── awardedBy ("system" or officer name)
  └── earnedAt (Timestamp)
```

**Stripe integration (to add later):**
The dues module is built to receive payment confirmation from an officer — it does not process cards directly. To add real Stripe payments:
1. Add `Stripe iOS SDK` via SPM: `https://github.com/stripe/stripe-ios`
2. Create a Cloud Function `createPaymentIntent` that returns a `client_secret`
3. Replace the manual `RecordPaymentSheet` amount entry with `STPPaymentCardTextField`
4. On successful payment, call `vm.recordPayment()` with `method: .stripe`

---

## 8. Cloud Functions Deployment <a name="functions"></a>

### Prerequisites
```bash
node --version   # must be 18+
npm install -g firebase-tools
firebase login
```

### Deploy
```bash
cd /path/to/GreekHub   # root of this project (where firebase.json lives)
cd functions && npm install && cd ..
firebase deploy --only functions
```

### All 8 functions deployed:

| Function | Trigger | Description |
|----------|---------|-------------|
| `onNewOfficerPost` | Firestore write: `posts/{id}` | Notifies all chapter members when an officer posts |
| `onCheckIn` | Firestore write: `events/{id}/checkIns/{uid}` | Sends `+N pts` push to the member who checked in |
| `onPointsAwarded` | Firestore write: `pointsLog/{id}` | Notifies member of manual point award/deduction |
| `eventReminders` | Scheduled: every 60 min | Finds events starting in ~1 hour, sends reminders to chapter |
| `onNewMessage` | Firestore write: `channels/{id}/messages/{id}` | Badges members on new messages in key channels |
| `onBidOffered` | Firestore update: `pnms/{id}` | Notifies officers when a bid status changes to "Bid Offered" |
| `duesOverdueReminder` | Scheduled: daily 9am ET | Marks overdue dues + sends push reminders to members |
| `onPointsUpdated` | Firestore update: `users/{id}` | Auto-awards Century Club badge when points ≥ 100 |

### Test locally before deploying:
```bash
firebase emulators:start --only functions,firestore,auth
```

---

## 9. Firestore Indexes <a name="indexes"></a>

The easiest way to create indexes is to just run the app — Firestore will print a link in the Xcode console that takes you directly to create each missing index. Click it and it creates automatically.

Alternatively, deploy `firestore.indexes.json`:
```json
{
  "indexes": [
    { "collectionGroup": "posts",    "fields": [{"fieldPath":"chapter","order":"ASCENDING"},{"fieldPath":"postedAt","order":"DESCENDING"}] },
    { "collectionGroup": "events",   "fields": [{"fieldPath":"chapter","order":"ASCENDING"},{"fieldPath":"date","order":"ASCENDING"}] },
    { "collectionGroup": "users",    "fields": [{"fieldPath":"chapter","order":"ASCENDING"},{"fieldPath":"name","order":"ASCENDING"}] },
    { "collectionGroup": "pointsLog","fields": [{"fieldPath":"userId","order":"ASCENDING"},{"fieldPath":"awardedAt","order":"DESCENDING"}] },
    { "collectionGroup": "pointsLog","fields": [{"fieldPath":"chapter","order":"ASCENDING"},{"fieldPath":"awardedAt","order":"DESCENDING"}] },
    { "collectionGroup": "media",    "fields": [{"fieldPath":"chapter","order":"ASCENDING"},{"fieldPath":"uploadedAt","order":"DESCENDING"}] },
    { "collectionGroup": "dues",     "fields": [{"fieldPath":"chapter","order":"ASCENDING"},{"fieldPath":"semester","order":"ASCENDING"},{"fieldPath":"userName","order":"ASCENDING"}] },
    { "collectionGroup": "alumni",   "fields": [{"fieldPath":"chapter","order":"ASCENDING"},{"fieldPath":"graduationYear","order":"DESCENDING"}] }
  ],
  "fieldOverrides": []
}
```

Then run: `firebase deploy --only firestore:indexes`

---

## 10. File Reference <a name="files"></a>

### Swift files (34 total)

| File | Phase | Purpose |
|------|-------|---------|
| `App/GreekHubApp.swift` | 1 | App entry point, Firebase init, splash screen |
| `Models/Models.swift` | 1 | User, Post, Event, Chat, Roster, Points models + mock data |
| `Models/Phase2Models.swift` | 2 | PointsEvent, CheckInRecord, ChapterAnalytics, MemberStat |
| `Models/Phase3Models.swift` | 3 | PNM, OfficerVote, RushSeason, GHNotification, MediaPost |
| `Models/Phase4Models.swift` | 4 | DuesRecord, PaymentRecord, AlumniMember, GHBadge |
| `Models/CheckInModels.swift` | 2 | Check-in payload model |
| `Resources/Theme.swift` | 1 | Colors, fonts, AvatarView, ghCard(), ghPill() modifiers |
| `Services/AuthService.swift` | 1 | Firebase Auth wrapper — sign in/up/out, password reset |
| `Services/FirestoreService.swift` | 1 | Core Firestore ops — users, posts, events, channels, messages |
| `Services/FirestoreExtensions.swift` | 1 | Firestore ↔ Swift model serialization |
| `Services/FirestorePhase2.swift` | 2 | Points history, check-in recording, analytics aggregation |
| `Services/FirestorePhase3.swift` | 3 | Rush, notifications, media wall Firestore ops |
| `Services/FirestorePhase4.swift` | 4 | Dues, alumni, badges Firestore ops |
| `ViewModels/ViewModels.swift` | 1 | Auth, Feed, Events, Chat, Roster, Points ViewModels |
| `ViewModels/Phase2ViewModels.swift` | 2 | OfficerPoints, CheckIn, OfficerDashboard ViewModels |
| `ViewModels/Phase3ViewModels.swift` | 3 | Rush, Notifications, Media ViewModels |
| `ViewModels/Phase4ViewModels.swift` | 4 | Dues, Alumni, Badges ViewModels |
| `Views/MainTabView.swift` | 1–4 | Tab bar, Officer Hub, Create Event |
| `Views/Auth/LoginView.swift` | 1 | Login, Register, Forgot Password, form components |
| `Views/Feed/FeedView.swift` | 1 | Feed, PostCard, CommentRow, ComposePost |
| `Views/Events/EventsView.swift` | 1 | Events list, EventCard, EventDetail, FilterChip |
| `Views/Chat/ChatView.swift` | 1 | Channel list, ChatRoom, MessageBubble |
| `Views/Roster/RosterView.swift` | 1 | Member list, MemberRow, MemberDetail |
| `Views/Profile/ProfileView.swift` | 1–4 | Profile, badges shelf, edit bio, leaderboard |
| `Views/Officer/OfficerDashboardView.swift` | 2 | Analytics tabs — Overview, Attendance, Points |
| `Views/Officer/OfficerPointsView.swift` | 2 | Points manager, AwardPointsSheet |
| `Views/CheckIn/QRCheckInView.swift` | 2 | QR generator (CoreImage), AVFoundation scanner |
| `Views/Rush/RushView.swift` | 3 | PNM list, PNMDetail, VoteSheet, AddPNM |
| `Views/Media/MediaWallView.swift` | 3 | Photo grid, MediaDetail, UploadPhotoView |
| `Views/Notifications/NotificationsView.swift` | 3 | Notification center, permission banner |
| `Views/Dues/DuesView.swift` | 4 | Dues dashboard, RecordPayment, CreateDues |
| `Views/Alumni/AlumniView.swift` | 4 | Alumni directory, AlumniDetail, AddAlumni |
| `Views/Badges/BadgesView.swift` | 4 | Badge shelf, BadgeTile, OfficerBadgeAward |
| `Package.swift` | 1 | Swift Package Manager — Firebase dependencies |

### Backend files

| File | Purpose |
|------|---------|
| `firebase.json` | Firebase deployment config |
| `firestore.rules` | Firestore security rules (all phases) |
| `storage.rules` | Firebase Storage security rules |
| `functions/src/index.js` | 8 Cloud Functions |
| `functions/package.json` | Node.js dependencies |

---

## Quick Start Checklist

```
[ ] 1. Create Xcode project (iOS App, SwiftUI, iOS 16)
[ ] 2. Delete ContentView.swift
[ ] 3. Drag GreekHub/ source files into Xcode
[ ] 4. Add Firebase SDK via SPM (Auth, Firestore, Storage, Messaging)
[ ] 5. Add Push Notifications + Background Modes capabilities
[ ] 6. Add camera/photo NSUsageDescription keys to Info.plist
[ ] 7. Create Firebase project at console.firebase.google.com
[ ] 8. Download GoogleService-Info.plist → drag into Xcode root
[ ] 9. Enable Email/Password Auth in Firebase console
[ ] 10. Create Firestore database (production mode, us-east1)
[ ] 11. Enable Firebase Storage
[ ] 12. Deploy firestore.rules and storage.rules
[ ] 13. Upload APNs .p8 key to Firebase Cloud Messaging settings
[ ] 14. Add AppDelegate for FCM token registration
[ ] 15. npm install -g firebase-tools && firebase login
[ ] 16. cd functions && npm install && cd .. && firebase deploy --only functions
[ ] 17. Build and run — register first account, verify Firestore user doc
[ ] 18. Seed default channels (one-time setup call)
[ ] 19. Create composite indexes (click links from Xcode console errors)
[ ] 20. Set your chapter's Executive Chair role in Firestore manually for first account
```

### Set first officer role manually

After the first user registers, go to Firebase console → Firestore → `users/{uid}` → Edit:
```
role: "Executive Chair"
```

That user will now see the Crown tab with all officer tools.
