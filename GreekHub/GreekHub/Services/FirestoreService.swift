import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Firestore Collections

enum FSCollection {
    static let users    = "users"
    static let chapters = "chapters"
    static let posts    = "posts"
    static let events   = "events"
    static let channels = "channels"
    static let messages = "messages"   // subcollection under channels
    static let rsvps    = "rsvps"      // subcollection under events
}

// MARK: - Firestore Service

final class FirestoreService {
    static let shared = FirestoreService()
    let db = Firestore.firestore()

    // MARK: - Users

    /// Create a user document on first sign-up
    func createUser(_ user: User) async throws {
        let data: [String: Any] = [
            "id":              user.id,
            "name":            user.name,
            "username":        user.username,
            "avatarInitials":  user.avatarInitials,
            "avatarColor":     user.avatarColor,
            "chapter":         user.chapter,
            "role":            user.role.rawValue,
            "points":          user.points,
            "pledgeClass":     user.pledgeClass,
            "major":           user.major,
            "year":            user.year,
            "bio":             user.bio,
            "isActive":        user.isActive,
            "createdAt":       FieldValue.serverTimestamp()
        ]
        try await db.collection(FSCollection.users).document(user.id).setData(data)
    }

    /// Fetch a single user by UID
    func fetchUser(uid: String) async throws -> User {
        let snap = try await db.collection(FSCollection.users).document(uid).getDocument()
        guard let data = snap.data() else {
            throw FirestoreError.documentNotFound("User \(uid)")
        }
        return try User.from(data)
    }

    /// Update specific user fields
    func updateUser(uid: String, fields: [String: Any]) async throws {
        try await db.collection(FSCollection.users).document(uid).updateData(fields)
    }

    /// Fetch all members in a chapter
    func fetchRoster(chapter: String) async throws -> [User] {
        let snap = try await db.collection(FSCollection.users)
            .whereField("chapter", isEqualTo: chapter)
            .whereField("isActive", isEqualTo: true)
            .order(by: "name")
            .getDocuments()
        return try snap.documents.map { try User.from($0.data()) }
    }

    // MARK: - Posts

    /// Post a new feed item
    func createPost(_ post: Post) async throws {
        let data: [String: Any] = [
            "id":           post.id,
            "authorId":     post.author.id,
            "authorName":   post.author.name,
            "authorInitials": post.author.avatarInitials,
            "authorColor":  post.author.avatarColor,
            "authorRole":   post.author.role.rawValue,
            "content":      post.content,
            "imageURL":     post.imageURL ?? "",
            "likes":        post.likes,
            "isOfficerPost": post.isOfficerPost,
            "tag":          post.tag?.rawValue ?? "",
            "chapter":      post.author.chapter,
            "postedAt":     FieldValue.serverTimestamp()
        ]
        try await db.collection(FSCollection.posts).document(post.id).setData(data)
    }

    /// Real-time listener for chapter feed
    func feedListener(chapter: String, onChange: @escaping ([Post]) -> Void) -> ListenerRegistration {
        db.collection(FSCollection.posts)
            .whereField("chapter", isEqualTo: chapter)
            .order(by: "postedAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { snap, _ in
                guard let docs = snap?.documents else { return }
                let posts = docs.compactMap { Post.from($0.data()) }
                onChange(posts)
            }
    }

    /// Toggle like on a post (transaction to avoid race conditions)
    func toggleLike(postId: String, userId: String) async throws {
        let ref = db.collection(FSCollection.posts).document(postId)
        try await db.runTransaction { transaction, errorPointer in
            let snap: DocumentSnapshot
            do { snap = try transaction.getDocument(ref) }
            catch let e as NSError { errorPointer?.pointee = e; return nil }

            var likedBy = snap.data()?["likedBy"] as? [String] ?? []
            var count = snap.data()?["likes"] as? Int ?? 0

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

    // MARK: - Events

    /// Create a chapter event
    func createEvent(_ event: ChapterEvent, chapter: String) async throws {
        let data: [String: Any] = [
            "id":               event.id,
            "title":            event.title,
            "description":      event.description,
            "location":         event.location,
            "date":             Timestamp(date: event.date),
            "endDate":          Timestamp(date: event.endDate),
            "type":             event.type.rawValue,
            "pointValue":       event.pointValue,
            "capacity":         event.capacity as Any,
            "requiresCheckIn":  event.requiresCheckIn,
            "organizerName":    event.organizerName,
            "chapter":          chapter,
            "createdAt":        FieldValue.serverTimestamp()
        ]
        try await db.collection(FSCollection.events).document(event.id).setData(data)
    }

    /// Real-time listener for chapter events
    func eventsListener(chapter: String, onChange: @escaping ([ChapterEvent]) -> Void) -> ListenerRegistration {
        db.collection(FSCollection.events)
            .whereField("chapter", isEqualTo: chapter)
            .order(by: "date")
            .addSnapshotListener { snap, _ in
                guard let docs = snap?.documents else { return }
                let events = docs.compactMap { ChapterEvent.from($0.data()) }
                onChange(events)
            }
    }

    /// RSVP subcollection — toggle presence
    func toggleRSVP(eventId: String, userId: String, userName: String) async throws {
        let ref = db.collection(FSCollection.events)
            .document(eventId)
            .collection(FSCollection.rsvps)
            .document(userId)

        let snap = try await ref.getDocument()
        if snap.exists {
            try await ref.delete()
            try await db.collection(FSCollection.events).document(eventId)
                .updateData(["rsvpCount": FieldValue.increment(Int64(-1))])
        } else {
            try await ref.setData(["userId": userId, "name": userName, "rsvpedAt": FieldValue.serverTimestamp()])
            try await db.collection(FSCollection.events).document(eventId)
                .updateData(["rsvpCount": FieldValue.increment(Int64(1))])
        }
    }

    /// Check if current user has RSVPed
    func isRSVPed(eventId: String, userId: String) async throws -> Bool {
        let ref = db.collection(FSCollection.events)
            .document(eventId)
            .collection(FSCollection.rsvps)
            .document(userId)
        return try await ref.getDocument().exists
    }

    // MARK: - Chat

    /// Create a default channel set for a new chapter
    func createDefaultChannels(chapter: String) async throws {
        let defaults: [(name: String, icon: String, officerOnly: Bool)] = [
            ("general",  "megaphone.fill",          false),
            ("officers", "crown.fill",               true),
            ("events",   "calendar",                 false),
            ("service",  "heart.fill",               false),
            ("pledges",  "person.badge.clock.fill",  false),
        ]
        for ch in defaults {
            let id = "\(chapter)_\(ch.name)".replacingOccurrences(of: " ", with: "_").lowercased()
            let data: [String: Any] = [
                "id":            id,
                "name":          ch.name,
                "description":   "# \(ch.name) channel",
                "icon":          ch.icon,
                "chapter":       chapter,
                "isOfficerOnly": ch.officerOnly,
                "lastMessage":   "",
                "lastMessageAt": FieldValue.serverTimestamp()
            ]
            try await db.collection(FSCollection.channels).document(id).setData(data, merge: true)
        }
    }

    /// Fetch channels for a chapter
    func fetchChannels(chapter: String) async throws -> [ChatChannel] {
        let snap = try await db.collection(FSCollection.channels)
            .whereField("chapter", isEqualTo: chapter)
            .order(by: "name")
            .getDocuments()
        return snap.documents.compactMap { ChatChannel.from($0.data()) }
    }

    /// Real-time messages listener for a channel
    func messagesListener(channelId: String, onChange: @escaping ([ChatMessage]) -> Void) -> ListenerRegistration {
        db.collection(FSCollection.channels)
            .document(channelId)
            .collection(FSCollection.messages)
            .order(by: "sentAt")
            .limit(toLast: 100)
            .addSnapshotListener { snap, _ in
                guard let docs = snap?.documents else { return }
                let messages = docs.compactMap { ChatMessage.from($0.data()) }
                onChange(messages)
            }
    }

    /// Send a message
    func sendMessage(channelId: String, message: ChatMessage) async throws {
        let msgId = UUID().uuidString
        let data: [String: Any] = [
            "id":             msgId,
            "authorId":       message.author.id,
            "authorName":     message.author.name,
            "authorInitials": message.author.avatarInitials,
            "authorColor":    message.author.avatarColor,
            "text":           message.text,
            "sentAt":         FieldValue.serverTimestamp()
        ]
        try await db.collection(FSCollection.channels)
            .document(channelId)
            .collection(FSCollection.messages)
            .document(msgId)
            .setData(data)

        // Update channel preview
        try await db.collection(FSCollection.channels).document(channelId).updateData([
            "lastMessage":   "\(message.author.name): \(message.text)",
            "lastMessageAt": FieldValue.serverTimestamp()
        ])
    }

    // MARK: - Points

    /// Award points to a user (called on check-in or manual award)
    func awardPoints(userId: String, amount: Int, reason: String) async throws {
        let ref = db.collection(FSCollection.users).document(userId)
        try await db.runTransaction { transaction, errorPointer in
            let snap: DocumentSnapshot
            do { snap = try transaction.getDocument(ref) }
            catch let e as NSError { errorPointer?.pointee = e; return nil }

            let current = snap.data()?["points"] as? Int ?? 0
            transaction.updateData(["points": current + amount], forDocument: ref)
            return nil
        }

        // Log the points event
        let logData: [String: Any] = [
            "userId":    userId,
            "amount":    amount,
            "reason":    reason,
            "awardedAt": FieldValue.serverTimestamp()
        ]
        try await db.collection("pointsLog").addDocument(data: logData)
    }
}

// MARK: - Firestore Errors

enum FirestoreError: LocalizedError {
    case documentNotFound(String)
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .documentNotFound(let id): return "Document not found: \(id)"
        case .decodingFailed(let msg):  return "Failed to decode: \(msg)"
        }
    }
}
