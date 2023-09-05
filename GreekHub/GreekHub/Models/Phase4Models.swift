import Foundation

// MARK: - Dues & Payments

struct DuesRecord: Identifiable {
    let id: String
    let userId: String
    let userName: String
    let userInitials: String
    let userColor: String
    var semester: String
    var amount: Double
    var amountPaid: Double
    var dueDate: Date
    var status: DuesStatus
    var payments: [PaymentRecord]
    var notes: String

    var balance: Double { amount - amountPaid }
    var isPaidInFull: Bool { amountPaid >= amount }
    var percentPaid: Double { amount > 0 ? min(amountPaid / amount, 1.0) : 0 }

    static var mockList: [DuesRecord] = [
        DuesRecord(id: "d1", userId: "u1", userName: "Marcus Webb",
                   userInitials: "MW", userColor: "#C9A84C",
                   semester: "Spring 2025", amount: 250, amountPaid: 250,
                   dueDate: Date().addingTimeInterval(86400 * 30),
                   status: .paid, payments: [
                    PaymentRecord(id: "p1", amount: 250, method: .stripe,
                                  paidAt: Date().addingTimeInterval(-86400 * 10),
                                  confirmedBy: "system", note: "Full semester dues")
                   ], notes: ""),
        DuesRecord(id: "d2", userId: "u2", userName: "Darius King",
                   userInitials: "DK", userColor: "#4C6BC9",
                   semester: "Spring 2025", amount: 250, amountPaid: 125,
                   dueDate: Date().addingTimeInterval(86400 * 14),
                   status: .partial, payments: [
                    PaymentRecord(id: "p2", amount: 125, method: .cashApp,
                                  paidAt: Date().addingTimeInterval(-86400 * 5),
                                  confirmedBy: "Marcus Webb", note: "First installment")
                   ], notes: "Second half due Feb 28"),
        DuesRecord(id: "d3", userId: "u3", userName: "Javon Miles",
                   userInitials: "JM", userColor: "#4CC99A",
                   semester: "Spring 2025", amount: 250, amountPaid: 0,
                   dueDate: Date().addingTimeInterval(-86400 * 5),
                   status: .overdue, payments: [], notes: ""),
        DuesRecord(id: "d4", userId: "u4", userName: "Elijah Ross",
                   userInitials: "ER", userColor: "#C94C4C",
                   semester: "Spring 2025", amount: 250, amountPaid: 250,
                   dueDate: Date().addingTimeInterval(86400 * 30),
                   status: .paid, payments: [], notes: ""),
        DuesRecord(id: "d5", userId: "u5", userName: "Trey Coleman",
                   userInitials: "TC", userColor: "#8A4CC9",
                   semester: "Spring 2025", amount: 150, amountPaid: 0,
                   dueDate: Date().addingTimeInterval(86400 * 7),
                   status: .unpaid, payments: [], notes: "Pledge rate"),
    ]
}

enum DuesStatus: String, CaseIterable {
    case paid    = "Paid"
    case partial = "Partial"
    case unpaid  = "Unpaid"
    case overdue = "Overdue"
    case waived  = "Waived"

    var color: String {
        switch self {
        case .paid:    return "#4CC99A"
        case .partial: return "#C9A84C"
        case .unpaid:  return "#888780"
        case .overdue: return "#C94C4C"
        case .waived:  return "#4C6BC9"
        }
    }

    var icon: String {
        switch self {
        case .paid:    return "checkmark.circle.fill"
        case .partial: return "circle.lefthalf.filled"
        case .unpaid:  return "circle"
        case .overdue: return "exclamationmark.circle.fill"
        case .waived:  return "minus.circle.fill"
        }
    }
}

struct PaymentRecord: Identifiable {
    let id: String
    let amount: Double
    let method: PaymentMethod
    let paidAt: Date
    let confirmedBy: String
    let note: String
}

enum PaymentMethod: String, CaseIterable {
    case stripe   = "Stripe"
    case cashApp  = "Cash App"
    case zelle    = "Zelle"
    case venmo    = "Venmo"
    case cash     = "Cash"
    case waived   = "Waived"

    var icon: String {
        switch self {
        case .stripe:  return "creditcard.fill"
        case .cashApp: return "dollarsign.app.fill"
        case .zelle:   return "arrow.left.arrow.right.circle.fill"
        case .venmo:   return "v.circle.fill"
        case .cash:    return "banknote.fill"
        case .waived:  return "minus.circle.fill"
        }
    }
}

struct DuesSummary {
    let semester: String
    let totalExpected: Double
    let totalCollected: Double
    let paidCount: Int
    let unpaidCount: Int
    let overdueCount: Int
    let memberCount: Int

    var collectionRate: Double { totalExpected > 0 ? totalCollected / totalExpected : 0 }

    static let mock = DuesSummary(
        semester: "Spring 2025",
        totalExpected: 1150,
        totalCollected: 625,
        paidCount: 2,
        unpaidCount: 2,
        overdueCount: 1,
        memberCount: 5
    )
}

// MARK: - Alumni

struct AlumniMember: Identifiable {
    let id: String
    var name: String
    var initials: String
    var avatarColor: String
    var graduationYear: Int
    var major: String
    var currentRole: String
    var company: String
    var city: String
    var email: String
    var linkedIn: String
    var bio: String
    var canMentor: Bool
    var interests: [String]
    var pledgeClass: String

    static var mockList: [AlumniMember] = [
        AlumniMember(id: "a1", name: "Dr. Raymond Cole", initials: "RC",
                     avatarColor: "#C9A84C", graduationYear: 2008,
                     major: "Pre-Med", currentRole: "Cardiologist",
                     company: "Sentara Healthcare", city: "Norfolk, VA",
                     email: "rcole@alumni.com", linkedIn: "linkedin.com/in/rcole",
                     bio: "Board-certified cardiologist. Loves mentoring pre-med brothers.",
                     canMentor: true, interests: ["Medicine", "Mentorship", "Golf"],
                     pledgeClass: "Fall 2004"),
        AlumniMember(id: "a2", name: "Marcus Johnson", initials: "MJ",
                     avatarColor: "#4C6BC9", graduationYear: 2015,
                     major: "Computer Science", currentRole: "Senior Engineer",
                     company: "Google", city: "New York, NY",
                     email: "mjohnson@alumni.com", linkedIn: "linkedin.com/in/mjohnson",
                     bio: "Tech lead at Google Maps. Happy to refer for engineering roles.",
                     canMentor: true, interests: ["Tech", "Startups", "Basketball"],
                     pledgeClass: "Spring 2012"),
        AlumniMember(id: "a3", name: "Brandon Hayes", initials: "BH",
                     avatarColor: "#4CC99A", graduationYear: 2019,
                     major: "Business", currentRole: "Investment Analyst",
                     company: "Goldman Sachs", city: "Washington, DC",
                     email: "bhayes@alumni.com", linkedIn: "linkedin.com/in/bhayes",
                     bio: "Finance and investment banking. Always looking to connect with brothers.",
                     canMentor: false, interests: ["Finance", "Real Estate", "Travel"],
                     pledgeClass: "Fall 2016"),
    ]
}

// MARK: - Gamification Badges

struct GHBadge: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let color: String
    let category: BadgeCategory
    let requirement: BadgeRequirement
    var earnedAt: Date?
    var isEarned: Bool { earnedAt != nil }

    static let allBadges: [GHBadge] = [
        // Attendance
        GHBadge(id: "b_perfect", name: "Perfect Attendance",
                description: "Attended every event this semester",
                icon: "checkmark.seal.fill", color: "#C9A84C",
                category: .attendance, requirement: .attendanceRate(1.0), earnedAt: nil),
        GHBadge(id: "b_streak5", name: "5-Event Streak",
                description: "Attended 5 events in a row",
                icon: "flame.fill", color: "#C94C4C",
                category: .attendance, requirement: .eventStreak(5), earnedAt: nil),
        GHBadge(id: "b_century", name: "Century Club",
                description: "Earned 100+ points in a semester",
                icon: "bolt.circle.fill", color: "#C9A84C",
                category: .points, requirement: .pointsThreshold(100), earnedAt: Date()),

        // Service
        GHBadge(id: "b_service10", name: "Service Star",
                description: "Logged 10+ service hours",
                icon: "heart.circle.fill", color: "#4CC99A",
                category: .service, requirement: .serviceHours(10), earnedAt: Date()),
        GHBadge(id: "b_service25", name: "Community Pillar",
                description: "Logged 25+ service hours",
                icon: "hands.and.sparkles.fill", color: "#4CC99A",
                category: .service, requirement: .serviceHours(25), earnedAt: nil),

        // Rush
        GHBadge(id: "b_recruiter", name: "Top Recruiter",
                description: "Referred 3+ PNMs who were accepted",
                icon: "person.badge.plus.fill", color: "#C94C8A",
                category: .recruitment, requirement: .recruits(3), earnedAt: nil),

        // Leadership
        GHBadge(id: "b_officer", name: "Officer",
                description: "Holds or has held an officer position",
                icon: "crown.fill", color: "#C9A84C",
                category: .leadership, requirement: .isOfficer, earnedAt: Date()),
        GHBadge(id: "b_founder", name: "Chapter Founder",
                description: "One of the founding members of this chapter",
                icon: "building.columns.fill", color: "#8A4CC9",
                category: .leadership, requirement: .manual, earnedAt: nil),

        // Engagement
        GHBadge(id: "b_social", name: "Social Butterfly",
                description: "Posted 10+ times in the chapter feed",
                icon: "bubble.left.and.bubble.right.fill", color: "#4C6BC9",
                category: .engagement, requirement: .postCount(10), earnedAt: nil),
        GHBadge(id: "b_earlybird", name: "Early Bird",
                description: "First to check in at 3 events",
                icon: "sunrise.fill", color: "#EF9F27",
                category: .attendance, requirement: .eventStreak(3), earnedAt: nil),
    ]
}

enum BadgeCategory: String, CaseIterable {
    case attendance  = "Attendance"
    case points      = "Points"
    case service     = "Service"
    case recruitment = "Recruitment"
    case leadership  = "Leadership"
    case engagement  = "Engagement"

    var icon: String {
        switch self {
        case .attendance:  return "checkmark.seal.fill"
        case .points:      return "bolt.fill"
        case .service:     return "heart.fill"
        case .recruitment: return "person.badge.plus.fill"
        case .leadership:  return "crown.fill"
        case .engagement:  return "bubble.left.fill"
        }
    }
}

enum BadgeRequirement {
    case attendanceRate(Double)
    case eventStreak(Int)
    case pointsThreshold(Int)
    case serviceHours(Int)
    case recruits(Int)
    case postCount(Int)
    case isOfficer
    case manual

    var description: String {
        switch self {
        case .attendanceRate(let r): return "\(Int(r * 100))% attendance"
        case .eventStreak(let n):    return "\(n)-event streak"
        case .pointsThreshold(let n):return "\(n)+ points"
        case .serviceHours(let n):   return "\(n)+ service hours"
        case .recruits(let n):       return "\(n)+ recruits"
        case .postCount(let n):      return "\(n)+ posts"
        case .isOfficer:             return "Officer role"
        case .manual:                return "Officer-awarded"
        }
    }
}
