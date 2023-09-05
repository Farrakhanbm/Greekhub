import Foundation
import FirebaseFirestore

// MARK: - Phase 2 Firestore Operations
// Add these methods to FirestoreService via extension

extension FirestoreService {

    // MARK: - Points History

    func fetchPointsHistory(userId: String) async throws -> [PointsEvent] {
        let snap = try await db.collection("pointsLog")
            .whereField("userId", isEqualTo: userId)
            .order(by: "awardedAt", descending: true)
            .limit(to: 50)
            .getDocuments()

        return snap.documents.compactMap { doc -> PointsEvent? in
            let d = doc.data()
            guard
                let id        = d["id"]        as? String,
                let userId    = d["userId"]    as? String,
                let amount    = d["amount"]    as? Int,
                let reasonRaw = d["reason"]    as? String,
                let ts        = d["awardedAt"] as? Timestamp
            else { return nil }

            return PointsEvent(
                id:           id,
                userId:       userId,
                amount:       amount,
                reason:       PointsReason(rawValue: reasonRaw) ?? .manualAward,
                eventTitle:   d["eventTitle"]  as? String,
                awardedBy:    d["awardedBy"]   as? String ?? "system",
                awardedAt:    ts.dateValue()
            )
        }
    }

    func fetchRecentAwards(chapter: String) async throws -> [PointsEvent] {
        let snap = try await db.collection("pointsLog")
            .whereField("chapter", isEqualTo: chapter)
            .order(by: "awardedAt", descending: true)
            .limit(to: 30)
            .getDocuments()

        return snap.documents.compactMap { doc -> PointsEvent? in
            let d = doc.data()
            guard
                let id        = d["id"]        as? String,
                let userId    = d["userId"]    as? String,
                let amount    = d["amount"]    as? Int,
                let reasonRaw = d["reason"]    as? String,
                let ts        = d["awardedAt"] as? Timestamp
            else { return nil }

            return PointsEvent(
                id:         id,
                userId:     userId,
                amount:     amount,
                reason:     PointsReason(rawValue: reasonRaw) ?? .manualAward,
                eventTitle: d["eventTitle"] as? String,
                awardedBy:  d["awardedBy"]  as? String ?? "system",
                awardedAt:  ts.dateValue()
            )
        }
    }

    // MARK: - Enhanced awardPoints (with chapter + note)

    func awardPoints(userId: String, amount: Int, reason: String,
                     note: String = "", awardedBy: String = "officer") async throws {
        // Atomically update user's point total
        let userRef = db.collection(FSCollection.users).document(userId)
        try await db.runTransaction { transaction, errorPointer in
            let snap: DocumentSnapshot
            do { snap = try transaction.getDocument(userRef) }
            catch let e as NSError { errorPointer?.pointee = e; return nil }

            let current = snap.data()?["points"] as? Int ?? 0
            transaction.updateData(["points": current + amount], forDocument: userRef)
            return nil
        }

        // Write audit log entry
        let logId   = UUID().uuidString
        var logData: [String: Any] = [
            "id":         logId,
            "userId":     userId,
            "amount":     amount,
            "reason":     reason,
            "awardedBy":  awardedBy,
            "awardedAt":  FieldValue.serverTimestamp()
        ]
        if !note.isEmpty { logData["note"] = note }

        try await db.collection("pointsLog").document(logId).setData(logData)
    }

    // MARK: - Check-In

    func isCheckedIn(eventId: String, userId: String) async throws -> Bool {
        let ref = db.collection(FSCollection.events)
            .document(eventId)
            .collection("checkIns")
            .document(userId)
        return try await ref.getDocument().exists
    }

    func recordCheckIn(eventId: String, eventTitle: String, user: User, points: Int) async throws {
        let now = FieldValue.serverTimestamp()

        // Write check-in record
        let checkInRef = db.collection(FSCollection.events)
            .document(eventId)
            .collection("checkIns")
            .document(user.id)

        try await checkInRef.setData([
            "userId":      user.id,
            "userName":    user.name,
            "checkedInAt": now,
            "pointsAwarded": points,
            "method":      CheckInMethod.qrScan.rawValue
        ])

        // Auto-RSVP if not already
        try await toggleRSVP(eventId: eventId, userId: user.id, userName: user.name)

        // Award points
        if points > 0 {
            try await awardPoints(
                userId:    user.id,
                amount:    points,
                reason:    PointsReason.eventAttendance.rawValue,
                note:      "QR check-in: \(eventTitle)",
                awardedBy: "system"
            )
        }
    }

    func fetchCheckIns(eventId: String) async throws -> [CheckInRecord] {
        let snap = try await db.collection(FSCollection.events)
            .document(eventId)
            .collection("checkIns")
            .order(by: "checkedInAt", descending: false)
            .getDocuments()

        return snap.documents.compactMap { doc -> CheckInRecord? in
            let d = doc.data()
            guard
                let userId    = d["userId"]    as? String,
                let userName  = d["userName"]  as? String,
                let ts        = d["checkedInAt"] as? Timestamp
            else { return nil }

            return CheckInRecord(
                id:            doc.documentID,
                eventId:       eventId,
                eventTitle:    "",
                userId:        userId,
                userName:      userName,
                checkedInAt:   ts.dateValue(),
                pointsAwarded: d["pointsAwarded"] as? Int ?? 0,
                method:        CheckInMethod(rawValue: d["method"] as? String ?? "") ?? .manual
            )
        }
    }

    // MARK: - Analytics

    func fetchAnalytics(chapter: String) async throws -> ChapterAnalytics {
        async let usersTask   = fetchRoster(chapter: chapter)
        async let eventsTask  = fetchEventCount(chapter: chapter)

        let users  = try await usersTask
        let events = try await eventsTask

        let totalMembers  = users.count
        let activeMembers = users.filter { $0.isActive }.count
        let totalPoints   = users.reduce(0) { $0 + $1.points }
        let avgPoints     = totalMembers > 0 ? Double(totalPoints) / Double(totalMembers) : 0

        let sorted     = users.sorted { $0.points > $1.points }
        let topStats   = sorted.prefix(3).map {
            MemberStat(id: $0.id, name: $0.name, initials: $0.avatarInitials,
                       color: $0.avatarColor, points: $0.points, attendanceRate: 0.8)
        }
        let atRisk     = sorted.filter { $0.points < 30 }.prefix(5).map {
            MemberStat(id: $0.id, name: $0.name, initials: $0.avatarInitials,
                       color: $0.avatarColor, points: $0.points, attendanceRate: 0.3)
        }

        return ChapterAnalytics(
            chapter:               chapter,
            semesterLabel:         "Spring 2025",
            totalMembers:          totalMembers,
            activeMembers:         activeMembers,
            averageAttendanceRate: avgPoints / 150.0,
            totalServiceHours:     0,
            eventsThisSemester:    events,
            topPerformers:         Array(topStats),
            atRiskMembers:         Array(atRisk),
            eventTurnout:          EventTurnoutPoint.mockSeries,
            pointsDistribution:    PointsBucket.mockBuckets
        )
    }

    private func fetchEventCount(chapter: String) async throws -> Int {
        let snap = try await db.collection(FSCollection.events)
            .whereField("chapter", isEqualTo: chapter)
            .getDocuments()
        return snap.documents.count
    }
}
