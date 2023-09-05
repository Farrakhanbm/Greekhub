import Foundation
import FirebaseFirestore

// MARK: - Phase 4 Firestore Operations

extension FirestoreService {

    // MARK: - Dues

    func fetchDuesRecords(chapter: String, semester: String) async throws -> [DuesRecord] {
        let snap = try await db.collection("dues")
            .whereField("chapter",  isEqualTo: chapter)
            .whereField("semester", isEqualTo: semester)
            .order(by: "userName")
            .getDocuments()

        return snap.documents.compactMap { doc -> DuesRecord? in
            let d = doc.data()
            guard
                let id       = d["id"]       as? String,
                let userId   = d["userId"]   as? String,
                let userName = d["userName"] as? String,
                let amount   = d["amount"]   as? Double,
                let amtPaid  = d["amountPaid"] as? Double,
                let semStr   = d["semester"] as? String,
                let statusRaw = d["status"]  as? String,
                let dueTS    = d["dueDate"]  as? Timestamp
            else { return nil }

            let paymentsData = d["payments"] as? [[String: Any]] ?? []
            let payments: [PaymentRecord] = paymentsData.compactMap { p in
                guard
                    let pid    = p["id"]     as? String,
                    let pAmt   = p["amount"] as? Double,
                    let mRaw   = p["method"] as? String,
                    let paidTS = p["paidAt"] as? Timestamp
                else { return nil }
                return PaymentRecord(
                    id:          pid,
                    amount:      pAmt,
                    method:      PaymentMethod(rawValue: mRaw) ?? .cash,
                    paidAt:      paidTS.dateValue(),
                    confirmedBy: p["confirmedBy"] as? String ?? "",
                    note:        p["note"]        as? String ?? ""
                )
            }

            return DuesRecord(
                id:           id,
                userId:       userId,
                userName:     userName,
                userInitials: d["userInitials"] as? String ?? "",
                userColor:    d["userColor"]    as? String ?? "#888780",
                semester:     semStr,
                amount:       amount,
                amountPaid:   amtPaid,
                dueDate:      dueTS.dateValue(),
                status:       DuesStatus(rawValue: statusRaw) ?? .unpaid,
                payments:     payments,
                notes:        d["notes"] as? String ?? ""
            )
        }
    }

    func createDuesRecord(_ record: DuesRecord, chapter: String) async throws {
        let data: [String: Any] = [
            "id":           record.id,
            "userId":       record.userId,
            "userName":     record.userName,
            "userInitials": record.userInitials,
            "userColor":    record.userColor,
            "chapter":      chapter,
            "semester":     record.semester,
            "amount":       record.amount,
            "amountPaid":   record.amountPaid,
            "dueDate":      Timestamp(date: record.dueDate),
            "status":       record.status.rawValue,
            "payments":     [],
            "notes":        record.notes,
            "createdAt":    FieldValue.serverTimestamp()
        ]
        try await db.collection("dues").document(record.id).setData(data)
    }

    func recordDuesPayment(duesId: String, payment: PaymentRecord,
                           newAmountPaid: Double, newStatus: DuesStatus) async throws {
        let paymentData: [String: Any] = [
            "id":          payment.id,
            "amount":      payment.amount,
            "method":      payment.method.rawValue,
            "paidAt":      Timestamp(date: payment.paidAt),
            "confirmedBy": payment.confirmedBy,
            "note":        payment.note
        ]
        try await db.collection("dues").document(duesId).updateData([
            "amountPaid": newAmountPaid,
            "status":     newStatus.rawValue,
            "payments":   FieldValue.arrayUnion([paymentData]),
            "updatedAt":  FieldValue.serverTimestamp()
        ])
    }

    func updateDuesStatus(duesId: String, status: DuesStatus, notes: String) async throws {
        try await db.collection("dues").document(duesId).updateData([
            "status": status.rawValue,
            "notes":  notes
        ])
    }

    // MARK: - Alumni

    func fetchAlumni(chapter: String) async throws -> [AlumniMember] {
        let snap = try await db.collection("alumni")
            .whereField("chapter", isEqualTo: chapter)
            .order(by: "graduationYear", descending: true)
            .getDocuments()

        return snap.documents.compactMap { doc -> AlumniMember? in
            let d = doc.data()
            guard
                let id   = d["id"]   as? String,
                let name = d["name"] as? String
            else { return nil }

            return AlumniMember(
                id:             id,
                name:           name,
                initials:       d["initials"]       as? String ?? "",
                avatarColor:    d["avatarColor"]    as? String ?? "#C9A84C",
                graduationYear: d["graduationYear"] as? Int    ?? 2020,
                major:          d["major"]          as? String ?? "",
                currentRole:    d["currentRole"]    as? String ?? "",
                company:        d["company"]        as? String ?? "",
                city:           d["city"]           as? String ?? "",
                email:          d["email"]          as? String ?? "",
                linkedIn:       d["linkedIn"]       as? String ?? "",
                bio:            d["bio"]            as? String ?? "",
                canMentor:      d["canMentor"]      as? Bool   ?? false,
                interests:      d["interests"]      as? [String] ?? [],
                pledgeClass:    d["pledgeClass"]    as? String ?? ""
            )
        }
    }

    func createAlumni(_ alumni: AlumniMember, chapter: String) async throws {
        let data: [String: Any] = [
            "id":             alumni.id,
            "name":           alumni.name,
            "initials":       alumni.initials,
            "avatarColor":    alumni.avatarColor,
            "chapter":        chapter,
            "graduationYear": alumni.graduationYear,
            "major":          alumni.major,
            "currentRole":    alumni.currentRole,
            "company":        alumni.company,
            "city":           alumni.city,
            "email":          alumni.email,
            "linkedIn":       alumni.linkedIn,
            "bio":            alumni.bio,
            "canMentor":      alumni.canMentor,
            "interests":      alumni.interests,
            "pledgeClass":    alumni.pledgeClass,
            "createdAt":      FieldValue.serverTimestamp()
        ]
        try await db.collection("alumni").document(alumni.id).setData(data)
    }

    // MARK: - Badges

    func fetchEarnedBadges(userId: String) async throws -> [GHBadge] {
        let snap = try await db.collection("users")
            .document(userId)
            .collection("badges")
            .getDocuments()

        return snap.documents.compactMap { doc -> GHBadge? in
            let d  = doc.data()
            guard let badgeId = d["badgeId"] as? String else { return nil }
            let ts = d["earnedAt"] as? Timestamp

            return GHBadge.allBadges.first(where: { $0.id == badgeId }).map { badge in
                var b = badge
                b.earnedAt = ts?.dateValue()
                return b
            }
        }
    }

    func awardBadge(badgeId: String, userId: String, awardedBy: String) async throws {
        let data: [String: Any] = [
            "badgeId":   badgeId,
            "awardedBy": awardedBy,
            "earnedAt":  FieldValue.serverTimestamp()
        ]
        try await db.collection("users")
            .document(userId)
            .collection("badges")
            .document(badgeId)
            .setData(data, merge: true)
    }
}
