import Foundation

// MARK: - PNM (Potential New Member)

struct PNM: Identifiable, Hashable {
    let id: String
    var firstName: String
    var lastName: String
    var email: String
    var phone: String
    var major: String
    var year: String
    var gpa: Double
    var hometown: String
    var bio: String
    var interests: [String]
    var avatarColor: String
    var status: PNMStatus
    var addedBy: String
    var addedAt: Date
    var votes: [OfficerVote]
    var photoURLs: [String]
    var notes: [PNMNote]

    var fullName: String { "\(firstName) \(lastName)" }
    var initials: String {
        let f = firstName.prefix(1)
        let l = lastName.prefix(1)
        return "\(f)\(l)".uppercased()
    }

    var averageScore: Double {
        guard !votes.isEmpty else { return 0 }
        return Double(votes.reduce(0) { $0 + $1.score }) / Double(votes.count)
    }

    var voteBreakdown: (yes: Int, no: Int, abstain: Int) {
        let yes     = votes.filter { $0.recommendation == .yes }.count
        let no      = votes.filter { $0.recommendation == .no }.count
        let abstain = votes.filter { $0.recommendation == .abstain }.count
        return (yes, no, abstain)
    }

    static var mockList: [PNM] = [
        PNM(id: "pnm1", firstName: "Jordan", lastName: "Davis", email: "jdavis@nsu.edu",
            phone: "(757) 555-0201", major: "Political Science", year: "Sophomore",
            gpa: 3.7, hometown: "Richmond, VA", bio: "Student body VP, debate team captain.",
            interests: ["Politics", "Public Speaking", "Community Service"],
            avatarColor: "#4C6BC9", status: .interviewing,
            addedBy: "Marcus Webb", addedAt: Date().addingTimeInterval(-86400 * 5),
            votes: [
                OfficerVote(id: "v1", officerId: "u1", officerName: "Marcus Webb", score: 9, recommendation: .yes, note: "Strong leader, excellent GPA", votedAt: Date().addingTimeInterval(-3600)),
                OfficerVote(id: "v2", officerId: "u2", officerName: "Darius King", score: 8, recommendation: .yes, note: "Great fit culturally", votedAt: Date().addingTimeInterval(-7200)),
            ],
            photoURLs: [], notes: [PNMNote(id: "n1", authorName: "Marcus Webb", text: "Met at info session. Very engaged.", createdAt: Date().addingTimeInterval(-86400 * 5))]),

        PNM(id: "pnm2", firstName: "Cameron", lastName: "Wright", email: "cwright@nsu.edu",
            phone: "(757) 555-0202", major: "Engineering", year: "Freshman",
            gpa: 3.4, hometown: "Norfolk, VA", bio: "First-gen college student, STEM tutor.",
            interests: ["Engineering", "Tutoring", "Basketball"],
            avatarColor: "#4CC99A", status: .pending,
            addedBy: "Darius King", addedAt: Date().addingTimeInterval(-86400 * 3),
            votes: [], photoURLs: [], notes: []),

        PNM(id: "pnm3", firstName: "Isaiah", lastName: "Monroe", email: "imonroe@nsu.edu",
            phone: "(757) 555-0203", major: "Business", year: "Junior",
            gpa: 3.1, hometown: "Virginia Beach, VA", bio: "Entrepreneur. Runs a small clothing brand.",
            interests: ["Business", "Fashion", "Networking"],
            avatarColor: "#8A4CC9", status: .bidOffered,
            addedBy: "Marcus Webb", addedAt: Date().addingTimeInterval(-86400 * 10),
            votes: [
                OfficerVote(id: "v3", officerId: "u1", officerName: "Marcus Webb", score: 7, recommendation: .yes, note: "Entrepreneurial spirit is a plus", votedAt: Date().addingTimeInterval(-86400)),
                OfficerVote(id: "v4", officerId: "u6", officerName: "Andre Thompson", score: 6, recommendation: .abstain, note: "GPA is borderline", votedAt: Date().addingTimeInterval(-86400 + 3600)),
            ],
            photoURLs: [], notes: []),

        PNM(id: "pnm4", firstName: "Malik", lastName: "Foster", email: "mfoster@nsu.edu",
            phone: "(757) 555-0204", major: "Pre-Med", year: "Sophomore",
            gpa: 3.9, hometown: "Atlanta, GA", bio: "Pre-med honor student, volunteers at free clinic.",
            interests: ["Medicine", "Community Health", "Track & Field"],
            avatarColor: "#C94C8A", status: .accepted,
            addedBy: "Marcus Webb", addedAt: Date().addingTimeInterval(-86400 * 14),
            votes: [
                OfficerVote(id: "v5", officerId: "u1", officerName: "Marcus Webb", score: 10, recommendation: .yes, note: "Outstanding in every category", votedAt: Date().addingTimeInterval(-86400 * 2)),
                OfficerVote(id: "v6", officerId: "u2", officerName: "Darius King", score: 9, recommendation: .yes, note: "Top candidate of the season", votedAt: Date().addingTimeInterval(-86400 * 2 + 1800)),
            ],
            photoURLs: [], notes: []),
    ]
}

enum PNMStatus: String, CaseIterable {
    case pending      = "Pending"
    case interviewing = "Interviewing"
    case bidOffered   = "Bid Offered"
    case accepted     = "Accepted"
    case declined     = "Declined"
    case withdrawn    = "Withdrawn"

    var color: String {
        switch self {
        case .pending:      return "#888780"
        case .interviewing: return "#C9A84C"
        case .bidOffered:   return "#4C6BC9"
        case .accepted:     return "#4CC99A"
        case .declined:     return "#C94C4C"
        case .withdrawn:    return "#888780"
        }
    }

    var icon: String {
        switch self {
        case .pending:      return "clock.fill"
        case .interviewing: return "person.fill.questionmark"
        case .bidOffered:   return "envelope.fill"
        case .accepted:     return "checkmark.seal.fill"
        case .declined:     return "xmark.circle.fill"
        case .withdrawn:    return "minus.circle.fill"
        }
    }
}

// MARK: - Officer Vote

struct OfficerVote: Identifiable, Hashable {
    let id: String
    let officerId: String
    let officerName: String
    let score: Int              // 1–10
    let recommendation: VoteRecommendation
    let note: String
    let votedAt: Date
}

enum VoteRecommendation: String, CaseIterable {
    case yes     = "Yes"
    case no      = "No"
    case abstain = "Abstain"

    var color: String {
        switch self {
        case .yes:     return "#4CC99A"
        case .no:      return "#C94C4C"
        case .abstain: return "#C9A84C"
        }
    }

    var icon: String {
        switch self {
        case .yes:     return "checkmark.circle.fill"
        case .no:      return "xmark.circle.fill"
        case .abstain: return "minus.circle.fill"
        }
    }
}

// MARK: - PNM Note

struct PNMNote: Identifiable, Hashable {
    let id: String
    let authorName: String
    let text: String
    let createdAt: Date
}

// MARK: - Rush Season

struct RushSeason: Identifiable {
    let id: String
    var name: String            // e.g. "Fall 2025 Rush"
    var chapter: String
    var isActive: Bool
    var startDate: Date
    var endDate: Date
    var pnmCount: Int
    var acceptedCount: Int

    static let mock = RushSeason(
        id: "rs1",
        name: "Spring 2025 Rush",
        chapter: "Alpha Phi Alpha — Theta Chapter",
        isActive: true,
        startDate: Date().addingTimeInterval(-86400 * 14),
        endDate: Date().addingTimeInterval(86400 * 14),
        pnmCount: 4,
        acceptedCount: 1
    )
}

// MARK: - Notification Models

struct GHNotification: Identifiable {
    let id: String
    let type: NotificationType
    let title: String
    let body: String
    let deepLink: String?       // e.g. "greekhub://event/e1"
    let sentAt: Date
    var isRead: Bool

    static var mockList: [GHNotification] = [
        GHNotification(id: "notif1", type: .eventReminder,
                       title: "Chapter Meeting in 1 hour",
                       body: "Student Union Rm. 204 · 2 pts",
                       deepLink: "greekhub://event/e2",
                       sentAt: Date().addingTimeInterval(-3600), isRead: false),
        GHNotification(id: "notif2", type: .pointsAwarded,
                       title: "+3 points awarded",
                       body: "Marcus Webb: Community Literacy Drive attendance",
                       deepLink: nil,
                       sentAt: Date().addingTimeInterval(-7200), isRead: false),
        GHNotification(id: "notif3", type: .newPost,
                       title: "New officer announcement",
                       body: "Marcus Webb posted in the chapter feed",
                       deepLink: "greekhub://feed/p1",
                       sentAt: Date().addingTimeInterval(-14400), isRead: true),
        GHNotification(id: "notif4", type: .chatMessage,
                       title: "New message in #general",
                       body: "Darius King: See everyone at the meeting Thursday",
                       deepLink: "greekhub://chat/ch1",
                       sentAt: Date().addingTimeInterval(-21600), isRead: true),
        GHNotification(id: "notif5", type: .rushUpdate,
                       title: "Bid offered to Isaiah Monroe",
                       body: "Rush update from Marcus Webb",
                       deepLink: "greekhub://rush/pnm3",
                       sentAt: Date().addingTimeInterval(-86400), isRead: true),
    ]
}

enum NotificationType: String {
    case eventReminder  = "event_reminder"
    case pointsAwarded  = "points_awarded"
    case newPost        = "new_post"
    case chatMessage    = "chat_message"
    case rushUpdate     = "rush_update"
    case emergency      = "emergency"

    var icon: String {
        switch self {
        case .eventReminder:  return "calendar.badge.clock"
        case .pointsAwarded:  return "bolt.fill"
        case .newPost:        return "megaphone.fill"
        case .chatMessage:    return "bubble.left.fill"
        case .rushUpdate:     return "person.badge.plus.fill"
        case .emergency:      return "exclamationmark.triangle.fill"
        }
    }

    var color: String {
        switch self {
        case .eventReminder:  return "#C9A84C"
        case .pointsAwarded:  return "#4CC99A"
        case .newPost:        return "#4C6BC9"
        case .chatMessage:    return "#8A4CC9"
        case .rushUpdate:     return "#C94C8A"
        case .emergency:      return "#C94C4C"
        }
    }
}

// MARK: - Media Post

struct MediaPost: Identifiable {
    let id: String
    let uploaderName: String
    let uploaderInitials: String
    let uploaderColor: String
    let uploaderId: String
    let eventId: String?
    let eventTitle: String?
    let imageURL: String
    let caption: String
    let likes: Int
    let isLiked: Bool
    let uploadedAt: Date
    let chapter: String

    static var mockWall: [MediaPost] = [
        MediaPost(id: "mp1", uploaderName: "Marcus Webb", uploaderInitials: "MW",
                  uploaderColor: "#C9A84C", uploaderId: "u1",
                  eventId: "e1", eventTitle: "Community Literacy Drive",
                  imageURL: "https://images.unsplash.com/photo-1529390079861-591de354faf5?w=400",
                  caption: "Brothers showing up for the community 💪🏾",
                  likes: 18, isLiked: false, uploadedAt: Date().addingTimeInterval(-86400), chapter: "Alpha Phi Alpha — Theta Chapter"),
        MediaPost(id: "mp2", uploaderName: "Darius King", uploaderInitials: "DK",
                  uploaderColor: "#4C6BC9", uploaderId: "u2",
                  eventId: "e3", eventTitle: "Alumni Mixer",
                  imageURL: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=400",
                  caption: "Alumni mixer was 🔥 Networking with the legends",
                  likes: 31, isLiked: true, uploadedAt: Date().addingTimeInterval(-86400 * 2), chapter: "Alpha Phi Alpha — Theta Chapter"),
        MediaPost(id: "mp3", uploaderName: "Javon Miles", uploaderInitials: "JM",
                  uploaderColor: "#4CC99A", uploaderId: "u3",
                  eventId: nil, eventTitle: nil,
                  imageURL: "https://images.unsplash.com/photo-1523240795612-9a054b0db644?w=400",
                  caption: "Brotherhood hits different when you put in the work 🙌🏾",
                  likes: 22, isLiked: false, uploadedAt: Date().addingTimeInterval(-86400 * 3), chapter: "Alpha Phi Alpha — Theta Chapter"),
    ]
}
