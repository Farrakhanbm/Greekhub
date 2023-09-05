import Foundation

// MARK: - User & Auth

struct User: Identifiable, Hashable {
    let id: String
    var name: String
    var username: String
    var avatarInitials: String
    var avatarColor: String
    var chapter: String
    var role: MemberRole
    var points: Int
    var pledgeClass: String
    var major: String
    var year: String
    var bio: String
    var isActive: Bool

    static let mock = User(
        id: "u1",
        name: "Marcus Webb",
        username: "marcuswebb",
        avatarInitials: "MW",
        avatarColor: "#C9A84C",
        chapter: "Alpha Phi Alpha — Theta Chapter",
        role: .executiveChair,
        points: 142,
        pledgeClass: "Fall 2022",
        major: "Business Administration",
        year: "Senior",
        bio: "Executive Chair. Finance lead. Lover of good food and better brotherhood.",
        isActive: true
    )
}

enum MemberRole: String, CaseIterable {
    case executiveChair  = "Executive Chair"
    case vicePresident   = "Vice President"
    case treasurer       = "Treasurer"
    case secretary       = "Secretary"
    case member          = "Member"
    case pledge          = "Pledge"

    var isOfficer: Bool {
        self != .member && self != .pledge
    }

    var icon: String {
        switch self {
        case .executiveChair: return "crown.fill"
        case .vicePresident:  return "star.fill"
        case .treasurer:      return "dollarsign.circle.fill"
        case .secretary:      return "doc.fill"
        case .member:         return "person.fill"
        case .pledge:         return "person.badge.clock.fill"
        }
    }
}

// MARK: - Feed

struct Post: Identifiable {
    let id: String
    let author: User
    var content: String
    var imageURL: String?
    var likes: Int
    var comments: [Comment]
    var isLiked: Bool
    var postedAt: Date
    var isOfficerPost: Bool
    var tag: PostTag?

    static var mockFeed: [Post] = [
        Post(
            id: "p1",
            author: .mock,
            content: "Big W at the step show last night 🔥 Theta chapter WENT OFF. Shoutout to every brother who showed up and represented. That energy was unmatched.",
            imageURL: nil,
            likes: 47,
            comments: Comment.mockSet,
            isLiked: false,
            postedAt: Date().addingTimeInterval(-3600),
            isOfficerPost: true,
            tag: .announcement
        ),
        Post(
            id: "p2",
            author: User(id: "u2", name: "Darius King", username: "dariusk", avatarInitials: "DK", avatarColor: "#4C6BC9", chapter: "Alpha Phi Alpha", role: .vicePresident, points: 98, pledgeClass: "Spring 2023", major: "Political Science", year: "Junior", bio: "", isActive: true),
            content: "Community service hours at the literacy center this Saturday. We need 15 brothers to hit our semester goal. Sign up on the events tab — this counts for 3 service points.",
            imageURL: nil,
            likes: 31,
            comments: [],
            isLiked: true,
            postedAt: Date().addingTimeInterval(-7200),
            isOfficerPost: true,
            tag: .service
        ),
        Post(
            id: "p3",
            author: User(id: "u3", name: "Javon Miles", username: "javonm", avatarInitials: "JM", avatarColor: "#4CC99A", chapter: "Alpha Phi Alpha", role: .member, points: 55, pledgeClass: "Fall 2023", major: "Computer Science", year: "Sophomore", bio: "", isActive: true),
            content: "Just finished my chapter feature — GreekHub beta is actually clean 👀 excited to see what the officers roll out next semester with the points system",
            imageURL: nil,
            likes: 22,
            comments: [],
            isLiked: false,
            postedAt: Date().addingTimeInterval(-18000),
            isOfficerPost: false,
            tag: nil
        ),
    ]
}

enum PostTag: String {
    case announcement = "Announcement"
    case service      = "Service"
    case social       = "Social"
    case urgent       = "Urgent"

    var color: String {
        switch self {
        case .announcement: return "#C9A84C"
        case .service:      return "#4CC99A"
        case .social:       return "#C94C8A"
        case .urgent:       return "#C94C4C"
        }
    }
}

struct Comment: Identifiable {
    let id: String
    let author: User
    var text: String
    var postedAt: Date

    static var mockSet: [Comment] = [
        Comment(id: "c1", author: User(id: "u4", name: "Elijah Ross", username: "elijahr", avatarInitials: "ER", avatarColor: "#C94C4C", chapter: "Alpha Phi Alpha", role: .member, points: 60, pledgeClass: "Fall 2022", major: "Music", year: "Senior", bio: "", isActive: true), text: "NPHC step show every year never misses 🔥", postedAt: Date().addingTimeInterval(-1800)),
        Comment(id: "c2", author: User(id: "u5", name: "Trey Coleman", username: "treyc", avatarInitials: "TC", avatarColor: "#8A4CC9", chapter: "Alpha Phi Alpha", role: .member, points: 44, pledgeClass: "Spring 2024", major: "Finance", year: "Sophomore", bio: "", isActive: true), text: "We ate 💪🏾", postedAt: Date().addingTimeInterval(-900)),
    ]
}

// MARK: - Events

struct ChapterEvent: Identifiable {
    let id: String
    var title: String
    var description: String
    var location: String
    var date: Date
    var endDate: Date
    var type: EventType
    var pointValue: Int
    var rsvpCount: Int
    var capacity: Int?
    var isRSVPed: Bool
    var requiresCheckIn: Bool
    var organizerName: String

    static var mockEvents: [ChapterEvent] = [
        ChapterEvent(id: "e1", title: "Community Literacy Drive", description: "Join us at the Norfolk Public Library to tutor K-8 students. Bring your ID and sign the volunteer log.", location: "Norfolk Public Library, Main Branch", date: Date().addingTimeInterval(86400 * 2), endDate: Date().addingTimeInterval(86400 * 2 + 7200), type: .service, pointValue: 3, rsvpCount: 9, capacity: 15, isRSVPed: true, requiresCheckIn: true, organizerName: "Darius King"),
        ChapterEvent(id: "e2", title: "Chapter Meeting", description: "Bi-weekly chapter meeting. Attendance mandatory for all active members. Budget review + event planning for spring.", location: "Student Union Rm. 204", date: Date().addingTimeInterval(86400 * 4), endDate: Date().addingTimeInterval(86400 * 4 + 5400), type: .meeting, pointValue: 2, rsvpCount: 24, capacity: nil, isRSVPed: false, requiresCheckIn: true, organizerName: "Marcus Webb"),
        ChapterEvent(id: "e3", title: "Alumni Mixer", description: "Annual alumni networking event. Business casual dress. Bring a copy of your resume if you're looking for opportunities.", location: "The Harbor Club, Downtown Norfolk", date: Date().addingTimeInterval(86400 * 7), endDate: Date().addingTimeInterval(86400 * 7 + 10800), type: .social, pointValue: 1, rsvpCount: 31, capacity: 50, isRSVPed: false, requiresCheckIn: false, organizerName: "Marcus Webb"),
        ChapterEvent(id: "e4", title: "Probate Show Prep", description: "Final rehearsal before the probate. All brothers required. No phones on the floor.", location: "Recreation Center Dance Studio", date: Date().addingTimeInterval(86400 * 10), endDate: Date().addingTimeInterval(86400 * 10 + 7200), type: .other, pointValue: 2, rsvpCount: 18, capacity: nil, isRSVPed: true, requiresCheckIn: true, organizerName: "Marcus Webb"),
    ]
}

enum EventType: String, CaseIterable {
    case meeting    = "Meeting"
    case service    = "Service"
    case social     = "Social"
    case philanthropy = "Philanthropy"
    case other      = "Other"

    var icon: String {
        switch self {
        case .meeting:      return "person.3.fill"
        case .service:      return "heart.fill"
        case .social:       return "party.popper.fill"
        case .philanthropy: return "dollarsign.circle.fill"
        case .other:        return "star.fill"
        }
    }

    var color: String {
        switch self {
        case .meeting:      return "#C9A84C"
        case .service:      return "#4CC99A"
        case .social:       return "#C94C8A"
        case .philanthropy: return "#4C6BC9"
        case .other:        return "#8A4CC9"
        }
    }
}

// MARK: - Chat

struct ChatChannel: Identifiable {
    let id: String
    var name: String
    var description: String
    var icon: String
    var lastMessage: String
    var lastMessageTime: Date
    var unreadCount: Int
    var isOfficerOnly: Bool

    static var mockChannels: [ChatChannel] = [
        ChatChannel(id: "ch1", name: "general", description: "Chapter-wide announcements", icon: "megaphone.fill", lastMessage: "Marcus: See everyone at the meeting Thursday", lastMessageTime: Date().addingTimeInterval(-1200), unreadCount: 3, isOfficerOnly: false),
        ChatChannel(id: "ch2", name: "officers", description: "Officer coordination", icon: "crown.fill", lastMessage: "Darius: Budget approved ✅", lastMessageTime: Date().addingTimeInterval(-3600), unreadCount: 0, isOfficerOnly: true),
        ChatChannel(id: "ch3", name: "events", description: "Event planning & logistics", icon: "calendar", lastMessage: "Javon: Confirmed venue for the mixer", lastMessageTime: Date().addingTimeInterval(-7200), unreadCount: 1, isOfficerOnly: false),
        ChatChannel(id: "ch4", name: "service", description: "Service hours & opportunities", icon: "heart.fill", lastMessage: "Sign-up sheet is live", lastMessageTime: Date().addingTimeInterval(-14400), unreadCount: 0, isOfficerOnly: false),
        ChatChannel(id: "ch5", name: "pledges", description: "New member education", icon: "person.badge.clock.fill", lastMessage: "Line meeting moved to 8pm", lastMessageTime: Date().addingTimeInterval(-21600), unreadCount: 5, isOfficerOnly: false),
    ]
}

struct ChatMessage: Identifiable {
    let id: String
    let author: User
    var text: String
    var sentAt: Date
    var isFromCurrentUser: Bool

    static func mockMessages(channelName: String) -> [ChatMessage] {
        [
            ChatMessage(id: "m1", author: .mock, text: "See everyone at the meeting Thursday — agenda will be posted tonight", sentAt: Date().addingTimeInterval(-3600), isFromCurrentUser: true),
            ChatMessage(id: "m2", author: User(id: "u2", name: "Darius King", username: "dariusk", avatarInitials: "DK", avatarColor: "#4C6BC9", chapter: "Alpha Phi Alpha", role: .vicePresident, points: 98, pledgeClass: "Spring 2023", major: "Political Science", year: "Junior", bio: "", isActive: true), text: "Budget approved ✅ We're good for spring events", sentAt: Date().addingTimeInterval(-2400), isFromCurrentUser: false),
            ChatMessage(id: "m3", author: User(id: "u3", name: "Javon Miles", username: "javonm", avatarInitials: "JM", avatarColor: "#4CC99A", chapter: "Alpha Phi Alpha", role: .member, points: 55, pledgeClass: "Fall 2023", major: "Computer Science", year: "Sophomore", bio: "", isActive: true), text: "Confirmed venue for the mixer 🙌🏾", sentAt: Date().addingTimeInterval(-1800), isFromCurrentUser: false),
            ChatMessage(id: "m4", author: .mock, text: "Let's keep the energy up this semester. Big things coming.", sentAt: Date().addingTimeInterval(-1200), isFromCurrentUser: true),
        ]
    }
}

// MARK: - Roster

struct RosterMember: Identifiable {
    let id: String
    var user: User
    var phone: String
    var email: String
    var isActive: Bool

    static var mockRoster: [RosterMember] = [
        RosterMember(id: "r1", user: .mock, phone: "(757) 555-0101", email: "mwebb@greekhu b.app", isActive: true),
        RosterMember(id: "r2", user: User(id: "u2", name: "Darius King", username: "dariusk", avatarInitials: "DK", avatarColor: "#4C6BC9", chapter: "Alpha Phi Alpha", role: .vicePresident, points: 98, pledgeClass: "Spring 2023", major: "Political Science", year: "Junior", bio: "", isActive: true), phone: "(757) 555-0102", email: "dking@greekhub.app", isActive: true),
        RosterMember(id: "r3", user: User(id: "u3", name: "Javon Miles", username: "javonm", avatarInitials: "JM", avatarColor: "#4CC99A", chapter: "Alpha Phi Alpha", role: .member, points: 55, pledgeClass: "Fall 2023", major: "Computer Science", year: "Sophomore", bio: "", isActive: true), phone: "(757) 555-0103", email: "jmiles@greekhub.app", isActive: true),
        RosterMember(id: "r4", user: User(id: "u4", name: "Elijah Ross", username: "elijahr", avatarInitials: "ER", avatarColor: "#C94C4C", chapter: "Alpha Phi Alpha", role: .member, points: 60, pledgeClass: "Fall 2022", major: "Music", year: "Senior", bio: "", isActive: true), phone: "(757) 555-0104", email: "eross@greekhub.app", isActive: true),
        RosterMember(id: "r5", user: User(id: "u5", name: "Trey Coleman", username: "treyc", avatarInitials: "TC", avatarColor: "#8A4CC9", chapter: "Alpha Phi Alpha", role: .pledge, points: 44, pledgeClass: "Spring 2024", major: "Finance", year: "Sophomore", bio: "", isActive: true), phone: "(757) 555-0105", email: "tcoleman@greekhub.app", isActive: true),
        RosterMember(id: "r6", user: User(id: "u6", name: "Andre Thompson", username: "andret", avatarInitials: "AT", avatarColor: "#C94C8A", chapter: "Alpha Phi Alpha", role: .treasurer, points: 115, pledgeClass: "Fall 2021", major: "Accounting", year: "Senior", bio: "", isActive: true), phone: "(757) 555-0106", email: "athompson@greekhub.app", isActive: true),
    ]
}

// MARK: - Points Leaderboard

struct PointsEntry: Identifiable {
    let id: String
    var member: RosterMember
    var rank: Int
    var pointsThisSemester: Int
    var attendanceRate: Int
    var serviceHours: Int

    static var mockLeaderboard: [PointsEntry] {
        RosterMember.mockRoster.enumerated().map { i, m in
            PointsEntry(id: "pts_\(m.id)", member: m, rank: i + 1, pointsThisSemester: m.user.points, attendanceRate: Int.random(in: 70...100), serviceHours: Int.random(in: 4...20))
        }.sorted { $0.pointsThisSemester > $1.pointsThisSemester }.enumerated().map { i, e in
            var updated = e; updated.rank = i + 1; return updated
        }
    }
}
