import Foundation
import FirebaseFirestore

// MARK: - User

extension User {
    static func from(_ data: [String: Any]) throws -> User {
        guard
            let id    = data["id"]    as? String,
            let name  = data["name"]  as? String,
            let uname = data["username"] as? String
        else { throw FirestoreError.decodingFailed("User missing required fields") }

        let roleRaw = data["role"] as? String ?? MemberRole.member.rawValue
        // Handle legacy "President" value from older documents
        let normalizedRole = roleRaw == "President" ? "Executive Chair" : roleRaw
        let role    = MemberRole(rawValue: normalizedRole) ?? .member

        return User(
            id:              id,
            name:            name,
            username:        uname,
            avatarInitials:  data["avatarInitials"]  as? String ?? String(name.prefix(2)).uppercased(),
            avatarColor:     data["avatarColor"]     as? String ?? "#C9A84C",
            chapter:         data["chapter"]         as? String ?? "",
            role:            role,
            points:          data["points"]          as? Int    ?? 0,
            pledgeClass:     data["pledgeClass"]     as? String ?? "",
            major:           data["major"]           as? String ?? "",
            year:            data["year"]            as? String ?? "",
            bio:             data["bio"]             as? String ?? "",
            isActive:        data["isActive"]        as? Bool   ?? true
        )
    }

    func toFirestore() -> [String: Any] {
        [
            "id":             id,
            "name":           name,
            "username":       username,
            "avatarInitials": avatarInitials,
            "avatarColor":    avatarColor,
            "chapter":        chapter,
            "role":           role.rawValue,
            "points":         points,
            "pledgeClass":    pledgeClass,
            "major":          major,
            "year":           year,
            "bio":            bio,
            "isActive":       isActive
        ]
    }
}

// MARK: - Post

extension Post {
    static func from(_ data: [String: Any]) -> Post? {
        guard
            let id        = data["id"]        as? String,
            let authorId  = data["authorId"]  as? String,
            let authorName = data["authorName"] as? String,
            let content   = data["content"]   as? String
        else { return nil }

        let roleRaw = data["authorRole"] as? String ?? MemberRole.member.rawValue
        let normalizedRole = roleRaw == "President" ? "Executive Chair" : roleRaw
        let author = User(
            id:             authorId,
            name:           authorName,
            username:       data["authorUsername"]  as? String ?? "",
            avatarInitials: data["authorInitials"]  as? String ?? "",
            avatarColor:    data["authorColor"]     as? String ?? "#888888",
            chapter:        data["chapter"]         as? String ?? "",
            role:           MemberRole(rawValue: normalizedRole) ?? .member,
            points:         0,
            pledgeClass:    "",
            major:          "",
            year:           "",
            bio:            "",
            isActive:       true
        )

        let tagRaw   = data["tag"] as? String ?? ""
        let tag      = PostTag(rawValue: tagRaw)
        let ts       = data["postedAt"] as? Timestamp
        let date     = ts?.dateValue() ?? Date()
        let likedBy  = data["likedBy"]  as? [String] ?? []
        let currentUID = AuthService.shared.currentUID ?? ""

        return Post(
            id:            id,
            author:        author,
            content:       content,
            imageURL:      data["imageURL"] as? String,
            likes:         data["likes"]    as? Int ?? 0,
            comments:      [],
            isLiked:       likedBy.contains(currentUID),
            postedAt:      date,
            isOfficerPost: data["isOfficerPost"] as? Bool ?? false,
            tag:           tag
        )
    }
}

// MARK: - ChapterEvent

extension ChapterEvent {
    static func from(_ data: [String: Any]) -> ChapterEvent? {
        guard
            let id    = data["id"]    as? String,
            let title = data["title"] as? String,
            let dateTS = data["date"] as? Timestamp
        else { return nil }

        let typeRaw = data["type"] as? String ?? EventType.other.rawValue
        let endTS   = data["endDate"] as? Timestamp ?? dateTS

        return ChapterEvent(
            id:              id,
            title:           title,
            description:     data["description"]    as? String ?? "",
            location:        data["location"]       as? String ?? "",
            date:            dateTS.dateValue(),
            endDate:         endTS.dateValue(),
            type:            EventType(rawValue: typeRaw) ?? .other,
            pointValue:      data["pointValue"]     as? Int ?? 0,
            rsvpCount:       data["rsvpCount"]      as? Int ?? 0,
            capacity:        data["capacity"]       as? Int,
            isRSVPed:        false,  // fetched separately
            requiresCheckIn: data["requiresCheckIn"] as? Bool ?? false,
            organizerName:   data["organizerName"]  as? String ?? ""
        )
    }
}

// MARK: - ChatChannel

extension ChatChannel {
    static func from(_ data: [String: Any]) -> ChatChannel? {
        guard
            let id   = data["id"]   as? String,
            let name = data["name"] as? String
        else { return nil }

        let ts = data["lastMessageAt"] as? Timestamp
        return ChatChannel(
            id:              id,
            name:            name,
            description:     data["description"]    as? String ?? "",
            icon:            data["icon"]           as? String ?? "bubble.left.fill",
            lastMessage:     data["lastMessage"]    as? String ?? "",
            lastMessageTime: ts?.dateValue() ?? Date(),
            unreadCount:     0,
            isOfficerOnly:   data["isOfficerOnly"]  as? Bool ?? false
        )
    }
}

// MARK: - ChatMessage

extension ChatMessage {
    static func from(_ data: [String: Any]) -> ChatMessage? {
        guard
            let id       = data["id"]       as? String,
            let authorId = data["authorId"] as? String,
            let text     = data["text"]     as? String
        else { return nil }

        let ts = data["sentAt"] as? Timestamp
        let author = User(
            id:             authorId,
            name:           data["authorName"]     as? String ?? "Member",
            username:       "",
            avatarInitials: data["authorInitials"] as? String ?? "?",
            avatarColor:    data["authorColor"]    as? String ?? "#888888",
            chapter:        "",
            role:           .member,
            points:         0,
            pledgeClass:    "",
            major:          "",
            year:           "",
            bio:            "",
            isActive:       true
        )

        let currentUID = AuthService.shared.currentUID ?? ""
        return ChatMessage(
            id:                id,
            author:            author,
            text:              text,
            sentAt:            ts?.dateValue() ?? Date(),
            isFromCurrentUser: authorId == currentUID
        )
    }
}
