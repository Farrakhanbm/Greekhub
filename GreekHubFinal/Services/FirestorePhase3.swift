import Foundation
import FirebaseFirestore
import UserNotifications

// MARK: - Phase 3 Firestore Operations

extension FirestoreService {

    // MARK: - Rush / Recruitment

    func rushListener(chapter: String, onChange: @escaping ([PNM]) -> Void) -> ListenerRegistration {
        db.collection("pnms")
            .whereField("chapter", isEqualTo: chapter)
            .order(by: "addedAt", descending: true)
            .addSnapshotListener { snap, _ in
                guard let docs = snap?.documents else { return }
                let pnms = docs.compactMap { PNM.from($0.data()) }
                onChange(pnms)
            }
    }

    func createPNM(_ pnm: PNM, chapter: String) async throws {
        var data = pnm.toFirestore()
        data["chapter"] = chapter
        try await db.collection("pnms").document(pnm.id).setData(data)
    }

    func updatePNMStatus(pnmId: String, status: PNMStatus) async throws {
        try await db.collection("pnms").document(pnmId)
            .updateData(["status": status.rawValue])
    }

    func submitVote(pnmId: String, vote: OfficerVote) async throws {
        let data: [String: Any] = [
            "id":             vote.id,
            "officerId":      vote.officerId,
            "officerName":    vote.officerName,
            "score":          vote.score,
            "recommendation": vote.recommendation.rawValue,
            "note":           vote.note,
            "votedAt":        FieldValue.serverTimestamp()
        ]
        try await db.collection("pnms").document(pnmId)
            .collection("votes").document(vote.officerId)
            .setData(data)
    }

    func addPNMNote(pnmId: String, note: PNMNote) async throws {
        let data: [String: Any] = [
            "id":         note.id,
            "authorName": note.authorName,
            "text":       note.text,
            "createdAt":  FieldValue.serverTimestamp()
        ]
        try await db.collection("pnms").document(pnmId)
            .collection("notes").document(note.id)
            .setData(data)
    }

    // MARK: - Notifications

    func saveFCMToken(_ token: String, userId: String) async throws {
        try await db.collection(FSCollection.users).document(userId)
            .updateData(["fcmToken": token, "fcmUpdatedAt": FieldValue.serverTimestamp()])
    }

    func fetchNotifications(userId: String) async throws -> [GHNotification] {
        let snap = try await db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .order(by: "sentAt", descending: true)
            .limit(to: 50)
            .getDocuments()

        return snap.documents.compactMap { doc -> GHNotification? in
            let d = doc.data()
            guard
                let id    = d["id"]    as? String,
                let title = d["title"] as? String,
                let body  = d["body"]  as? String,
                let typeR = d["type"]  as? String,
                let ts    = d["sentAt"] as? Timestamp
            else { return nil }

            return GHNotification(
                id:       id,
                type:     NotificationType(rawValue: typeR) ?? .newPost,
                title:    title,
                body:     body,
                deepLink: d["deepLink"] as? String,
                sentAt:   ts.dateValue(),
                isRead:   d["isRead"] as? Bool ?? false
            )
        }
    }

    func markNotificationRead(notifId: String, userId: String) async throws {
        let snap = try await db.collection("notifications")
            .whereField("id", isEqualTo: notifId)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        for doc in snap.documents {
            try await doc.reference.updateData(["isRead": true])
        }
    }

    // MARK: - Media

    func mediaListener(chapter: String, onChange: @escaping ([MediaPost]) -> Void) -> ListenerRegistration {
        db.collection("media")
            .whereField("chapter", isEqualTo: chapter)
            .order(by: "uploadedAt", descending: true)
            .limit(to: 60)
            .addSnapshotListener { snap, _ in
                guard let docs = snap?.documents else { return }
                let posts = docs.compactMap { MediaPost.from($0.data()) }
                onChange(posts)
            }
    }

    func createMediaPost(_ post: MediaPost) async throws {
        let data: [String: Any] = [
            "id":               post.id,
            "uploaderName":     post.uploaderName,
            "uploaderInitials": post.uploaderInitials,
            "uploaderColor":    post.uploaderColor,
            "uploaderId":       post.uploaderId,
            "eventId":          post.eventId ?? "",
            "eventTitle":       post.eventTitle ?? "",
            "imageURL":         post.imageURL,
            "caption":          post.caption,
            "likes":            0,
            "likedBy":          [String](),
            "chapter":          post.chapter,
            "uploadedAt":       FieldValue.serverTimestamp()
        ]
        try await db.collection("media").document(post.id).setData(data)
    }

    func toggleMediaLike(postId: String, userId: String) async throws {
        let ref = db.collection("media").document(postId)
        try await db.runTransaction { transaction, errorPointer in
            let snap: DocumentSnapshot
            do { snap = try transaction.getDocument(ref) }
            catch let e as NSError { errorPointer?.pointee = e; return nil }

            var likedBy = snap.data()?["likedBy"] as? [String] ?? []
            var count   = snap.data()?["likes"]   as? Int ?? 0

            if likedBy.contains(userId) {
                likedBy.removeAll { $0 == userId }
                count -= 1
            } else {
                likedBy.append(userId)
                count += 1
            }
            transaction.updateData(["likes": count, "likedBy": likedBy], forDocument: ref)
            return nil
        }
    }
}

// MARK: - Model Firestore Extensions

extension PNM {
    static func from(_ data: [String: Any]) -> PNM? {
        guard
            let id        = data["id"]        as? String,
            let firstName = data["firstName"]  as? String,
            let lastName  = data["lastName"]   as? String
        else { return nil }

        let statusRaw = data["status"] as? String ?? PNMStatus.pending.rawValue
        let ts        = data["addedAt"] as? Timestamp

        return PNM(
            id: id, firstName: firstName, lastName: lastName,
            email:       data["email"]       as? String ?? "",
            phone:       data["phone"]       as? String ?? "",
            major:       data["major"]       as? String ?? "",
            year:        data["year"]        as? String ?? "",
            gpa:         data["gpa"]         as? Double ?? 0,
            hometown:    data["hometown"]    as? String ?? "",
            bio:         data["bio"]         as? String ?? "",
            interests:   data["interests"]   as? [String] ?? [],
            avatarColor: data["avatarColor"] as? String ?? "#888780",
            status:      PNMStatus(rawValue: statusRaw) ?? .pending,
            addedBy:     data["addedBy"]     as? String ?? "",
            addedAt:     ts?.dateValue() ?? Date(),
            votes: [], notes: [], photoURLs: []
        )
    }

    func toFirestore() -> [String: Any] {
        [
            "id":          id,
            "firstName":   firstName,
            "lastName":    lastName,
            "email":       email,
            "phone":       phone,
            "major":       major,
            "year":        year,
            "gpa":         gpa,
            "hometown":    hometown,
            "bio":         bio,
            "interests":   interests,
            "avatarColor": avatarColor,
            "status":      status.rawValue,
            "addedBy":     addedBy,
            "addedAt":     FieldValue.serverTimestamp()
        ]
    }
}

extension MediaPost {
    static func from(_ data: [String: Any]) -> MediaPost? {
        guard
            let id       = data["id"]       as? String,
            let imageURL = data["imageURL"] as? String,
            let chapter  = data["chapter"]  as? String
        else { return nil }

        let ts        = data["uploadedAt"] as? Timestamp
        let currentUID = AuthService.shared.currentUID ?? ""
        let likedBy    = data["likedBy"] as? [String] ?? []

        return MediaPost(
            id:               id,
            uploaderName:     data["uploaderName"]     as? String ?? "",
            uploaderInitials: data["uploaderInitials"] as? String ?? "?",
            uploaderColor:    data["uploaderColor"]    as? String ?? "#888780",
            uploaderId:       data["uploaderId"]       as? String ?? "",
            eventId:          data["eventId"]          as? String,
            eventTitle:       data["eventTitle"]       as? String,
            imageURL:         imageURL,
            caption:          data["caption"]          as? String ?? "",
            likes:            data["likes"]            as? Int ?? 0,
            isLiked:          likedBy.contains(currentUID),
            uploadedAt:       ts?.dateValue() ?? Date(),
            chapter:          chapter
        )
    }
}
