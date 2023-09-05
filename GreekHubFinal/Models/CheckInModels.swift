import Foundation

// MARK: - Check-In Record

struct CheckInRecord: Identifiable {
    let id: String
    let eventId: String
    let eventTitle: String
    let userId: String
    let userName: String
    let userInitials: String
    let userColor: String
    let checkedInAt: Date
    let method: CheckInMethod

    enum CheckInMethod: String {
        case qr     = "QR Scan"
        case manual = "Manual"
    }
}

// MARK: - QR Payload
// This is the data encoded into the QR code for each event.
// Format: "greekHub://checkin?eventId=XXX&chapter=YYY&token=ZZZ"
// The token is a SHA-256 hash of (eventId + chapter + secret) to prevent forgery.

struct QRPayload: Codable {
    let eventId: String
    let chapter: String
    let token: String       // HMAC-SHA256(eventId+chapter, serverSecret) — verified server-side
    let expiresAt: Double   // Unix timestamp — QR rotates every 5 minutes

    var urlString: String {
        "greekHub://checkin?eventId=\(eventId)&chapter=\(chapter)&token=\(token)&exp=\(Int(expiresAt))"
    }

    /// Client-side expiry check (server still validates)
    var isExpired: Bool { Date().timeIntervalSince1970 > expiresAt }
}

// MARK: - Dashboard Stats

struct DashboardStats {
    var totalMembers: Int
    var activeThisSemester: Int
    var eventsThisSemester: Int
    var avgAttendanceRate: Double    // 0.0 – 1.0
    var topAttendee: String
    var leastActive: String
    var upcomingEventCount: Int
    var checkInsToday: Int

    /// Attendance rate as a display percentage string
    var attendancePercent: String { "\(Int(avgAttendanceRate * 100))%" }

    static let mock = DashboardStats(
        totalMembers: 24,
        activeThisSemester: 21,
        eventsThisSemester: 12,
        avgAttendanceRate: 0.74,
        topAttendee: "Marcus Webb",
        leastActive: "Trey Coleman",
        upcomingEventCount: 4,
        checkInsToday: 0
    )
}

// MARK: - Event Attendance Summary

struct EventAttendanceSummary: Identifiable {
    let id: String           // eventId
    let title: String
    let date: Date
    let type: EventType
    let rsvpCount: Int
    let checkedInCount: Int
    let attendees: [AttendeeRecord]

    var attendanceRate: Double {
        rsvpCount > 0 ? Double(checkedInCount) / Double(rsvpCount) : 0
    }

    var attendancePercent: String { "\(Int(attendanceRate * 100))%" }
}

struct AttendeeRecord: Identifiable {
    let id: String           // userId
    let name: String
    let initials: String
    let color: String
    let checkedInAt: Date?   // nil = RSVPed but no-show
    var didCheckIn: Bool { checkedInAt != nil }
}

// MARK: - Mock Data

extension CheckInRecord {
    static var mockRecent: [CheckInRecord] = [
        CheckInRecord(id: "ci1", eventId: "e2", eventTitle: "Chapter Meeting",
                      userId: "u1", userName: "Marcus Webb",    userInitials: "MW", userColor: "#C9A84C",
                      checkedInAt: Date().addingTimeInterval(-3600), method: .qr),
        CheckInRecord(id: "ci2", eventId: "e2", eventTitle: "Chapter Meeting",
                      userId: "u2", userName: "Darius King",    userInitials: "DK", userColor: "#4C6BC9",
                      checkedInAt: Date().addingTimeInterval(-3500), method: .qr),
        CheckInRecord(id: "ci3", eventId: "e2", eventTitle: "Chapter Meeting",
                      userId: "u3", userName: "Javon Miles",    userInitials: "JM", userColor: "#4CC99A",
                      checkedInAt: Date().addingTimeInterval(-3400), method: .manual),
        CheckInRecord(id: "ci4", eventId: "e2", eventTitle: "Chapter Meeting",
                      userId: "u4", userName: "Elijah Ross",    userInitials: "ER", userColor: "#C94C4C",
                      checkedInAt: Date().addingTimeInterval(-3200), method: .qr),
        CheckInRecord(id: "ci5", eventId: "e2", eventTitle: "Chapter Meeting",
                      userId: "u6", userName: "Andre Thompson", userInitials: "AT", userColor: "#C94C8A",
                      checkedInAt: Date().addingTimeInterval(-3100), method: .qr),
    ]
}

extension EventAttendanceSummary {
    static var mockSummaries: [EventAttendanceSummary] = [
        EventAttendanceSummary(
            id: "e1", title: "Community Literacy Drive",
            date: Date().addingTimeInterval(-86400 * 7), type: .service,
            rsvpCount: 9, checkedInCount: 8,
            attendees: [
                AttendeeRecord(id: "u1", name: "Marcus Webb",    initials: "MW", color: "#C9A84C", checkedInAt: Date().addingTimeInterval(-86400 * 7 + 300)),
                AttendeeRecord(id: "u2", name: "Darius King",    initials: "DK", color: "#4C6BC9", checkedInAt: Date().addingTimeInterval(-86400 * 7 + 450)),
                AttendeeRecord(id: "u3", name: "Javon Miles",    initials: "JM", color: "#4CC99A", checkedInAt: nil),
                AttendeeRecord(id: "u4", name: "Elijah Ross",    initials: "ER", color: "#C94C4C", checkedInAt: Date().addingTimeInterval(-86400 * 7 + 600)),
            ]
        ),
        EventAttendanceSummary(
            id: "e2", title: "Chapter Meeting",
            date: Date().addingTimeInterval(-86400 * 3), type: .meeting,
            rsvpCount: 24, checkedInCount: 19,
            attendees: []
        ),
        EventAttendanceSummary(
            id: "e3", title: "Alumni Mixer",
            date: Date().addingTimeInterval(-86400 * 14), type: .social,
            rsvpCount: 31, checkedInCount: 26,
            attendees: []
        ),
    ]
}
