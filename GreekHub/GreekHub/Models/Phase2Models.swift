import Foundation

// MARK: - Points Event (audit log entry)

struct PointsEvent: Identifiable {
    let id: String
    let userId: String
    let amount: Int
    let reason: PointsReason
    let eventTitle: String?
    let awardedBy: String        // officer name or "system"
    let awardedAt: Date

    var isPositive: Bool { amount >= 0 }
}

enum PointsReason: String, CaseIterable {
    case eventAttendance  = "Event attendance"
    case serviceHours     = "Service hours"
    case chapterMeeting   = "Chapter meeting"
    case manualAward      = "Officer award"
    case manualDeduction  = "Officer deduction"
    case fine             = "Fine"
    case philanthropy     = "Philanthropy"
    case recruitment      = "Recruitment"

    var icon: String {
        switch self {
        case .eventAttendance:  return "checkmark.seal.fill"
        case .serviceHours:     return "heart.fill"
        case .chapterMeeting:   return "person.3.fill"
        case .manualAward:      return "bolt.fill"
        case .manualDeduction:  return "minus.circle.fill"
        case .fine:             return "exclamationmark.triangle.fill"
        case .philanthropy:     return "dollarsign.circle.fill"
        case .recruitment:      return "person.badge.plus.fill"
        }
    }

    var color: String {
        switch self {
        case .manualDeduction, .fine: return "#C94C4C"
        case .serviceHours:           return "#4CC99A"
        case .chapterMeeting:         return "#C9A84C"
        case .philanthropy:           return "#4C6BC9"
        case .recruitment:            return "#8A4CC9"
        default:                      return "#C9A84C"
        }
    }
}

// MARK: - Check-In

struct CheckInRecord: Identifiable {
    let id: String
    let eventId: String
    let eventTitle: String
    let userId: String
    let userName: String
    let checkedInAt: Date
    let pointsAwarded: Int
    let method: CheckInMethod
}

enum CheckInMethod: String {
    case qrScan  = "QR Scan"
    case manual  = "Manual"
}

// MARK: - Officer Dashboard Analytics

struct ChapterAnalytics {
    let chapter: String
    let semesterLabel: String
    let totalMembers: Int
    let activeMembers: Int
    let averageAttendanceRate: Double      // 0.0 – 1.0
    let totalServiceHours: Int
    let eventsThisSemester: Int
    let topPerformers: [MemberStat]
    let atRiskMembers: [MemberStat]        // below threshold
    let eventTurnout: [EventTurnoutPoint]
    let pointsDistribution: [PointsBucket]

    static let mock = ChapterAnalytics(
        chapter: "Alpha Phi Alpha — Theta Chapter",
        semesterLabel: "Spring 2025",
        totalMembers: 24,
        activeMembers: 21,
        averageAttendanceRate: 0.76,
        totalServiceHours: 312,
        eventsThisSemester: 14,
        topPerformers: MemberStat.mockTop,
        atRiskMembers: MemberStat.mockAtRisk,
        eventTurnout: EventTurnoutPoint.mockSeries,
        pointsDistribution: PointsBucket.mockBuckets
    )
}

struct MemberStat: Identifiable {
    let id: String
    let name: String
    let initials: String
    let color: String
    let points: Int
    let attendanceRate: Double

    static let mockTop: [MemberStat] = [
        MemberStat(id: "u1", name: "Marcus Webb",   initials: "MW", color: "#C9A84C", points: 142, attendanceRate: 0.95),
        MemberStat(id: "u6", name: "Andre Thompson",initials: "AT", color: "#C94C8A", points: 115, attendanceRate: 0.88),
        MemberStat(id: "u2", name: "Darius King",   initials: "DK", color: "#4C6BC9", points: 98,  attendanceRate: 0.82),
    ]

    static let mockAtRisk: [MemberStat] = [
        MemberStat(id: "u5", name: "Trey Coleman",  initials: "TC", color: "#8A4CC9", points: 44, attendanceRate: 0.42),
        MemberStat(id: "u8", name: "Devon Price",   initials: "DP", color: "#4CC99A", points: 31, attendanceRate: 0.35),
    ]
}

struct EventTurnoutPoint: Identifiable {
    let id: String
    let label: String       // short event name
    let attended: Int
    let total: Int
    var rate: Double { total > 0 ? Double(attended) / Double(total) : 0 }

    static let mockSeries: [EventTurnoutPoint] = [
        EventTurnoutPoint(id: "1", label: "Jan Mtg",  attended: 18, total: 24),
        EventTurnoutPoint(id: "2", label: "Literacy", attended: 12, total: 24),
        EventTurnoutPoint(id: "3", label: "Feb Mtg",  attended: 20, total: 24),
        EventTurnoutPoint(id: "4", label: "Alumni",   attended: 22, total: 24),
        EventTurnoutPoint(id: "5", label: "Mar Mtg",  attended: 17, total: 24),
        EventTurnoutPoint(id: "6", label: "Service",  attended: 14, total: 24),
        EventTurnoutPoint(id: "7", label: "Apr Mtg",  attended: 21, total: 24),
    ]
}

struct PointsBucket: Identifiable {
    let id: String
    let label: String
    let count: Int
    let color: String

    static let mockBuckets: [PointsBucket] = [
        PointsBucket(id: "b1", label: "100+",  count: 5,  color: "#C9A84C"),
        PointsBucket(id: "b2", label: "75–99", count: 6,  color: "#4CC99A"),
        PointsBucket(id: "b3", label: "50–74", count: 7,  color: "#4C6BC9"),
        PointsBucket(id: "b4", label: "25–49", count: 4,  color: "#8A4CC9"),
        PointsBucket(id: "b5", label: "0–24",  count: 2,  color: "#C94C4C"),
    ]
}

// MARK: - Points Award Request (officer tool)

struct PointsAwardRequest {
    var memberId: String = ""
    var memberName: String = ""
    var amount: Int = 0
    var reason: PointsReason = .manualAward
    var note: String = ""
}
