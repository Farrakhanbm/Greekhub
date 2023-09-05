import Foundation
import FirebaseFirestore

// MARK: - Dues ViewModel

class DuesViewModel: ObservableObject {
    @Published var records: [DuesRecord]    = DuesRecord.mockList
    @Published var summary: DuesSummary    = .mock
    @Published var selectedSemester        = "Spring 2025"
    @Published var isLoading               = false
    @Published var successMessage: String? = nil
    @Published var errorMessage: String?   = nil

    private let db = FirestoreService.shared

    var semesters: [String] { ["Spring 2025", "Fall 2024", "Spring 2024"] }

    var totalCollected: Double { records.filter { $0.status == .paid }.reduce(0) { $0 + $1.amountPaid } }
    var totalOutstanding: Double { records.reduce(0) { $0 + $1.balance } }
    var overdueRecords: [DuesRecord] { records.filter { $0.status == .overdue } }

    func load(chapter: String) {
        isLoading = true
        Task {
            let fetched = (try? await db.fetchDuesRecords(chapter: chapter, semester: selectedSemester)) ?? DuesRecord.mockList
            let sum     = buildSummary(from: fetched)
            await MainActor.run {
                self.records  = fetched
                self.summary  = sum
                self.isLoading = false
            }
        }
    }

    private func buildSummary(from records: [DuesRecord]) -> DuesSummary {
        DuesSummary(
            semester:       selectedSemester,
            totalExpected:  records.reduce(0) { $0 + $1.amount },
            totalCollected: records.reduce(0) { $0 + $1.amountPaid },
            paidCount:      records.filter { $0.status == .paid }.count,
            unpaidCount:    records.filter { $0.status == .unpaid }.count,
            overdueCount:   records.filter { $0.status == .overdue }.count,
            memberCount:    records.count
        )
    }

    // Officer manually records a payment
    func recordPayment(duesId: String, amount: Double, method: PaymentMethod,
                       confirmedBy: String, note: String) {
        guard let idx = records.firstIndex(where: { $0.id == duesId }) else { return }
        let payment = PaymentRecord(
            id:          UUID().uuidString,
            amount:      amount,
            method:      method,
            paidAt:      Date(),
            confirmedBy: confirmedBy,
            note:        note
        )
        records[idx].payments.append(payment)
        records[idx].amountPaid += amount
        records[idx].status = records[idx].isPaidInFull ? .paid : .partial

        Task {
            try? await db.recordDuesPayment(duesId: duesId, payment: payment,
                                            newAmountPaid: records[idx].amountPaid,
                                            newStatus: records[idx].status)
            await MainActor.run { self.successMessage = "Payment of $\(String(format: "%.2f", amount)) recorded." }
        }
    }

    // Create dues records for whole chapter
    func createSemesterDues(chapter: String, amount: Double, dueDate: Date,
                            semester: String, members: [RosterMember]) {
        let newRecords = members.map { member in
            DuesRecord(
                id:           UUID().uuidString,
                userId:       member.user.id,
                userName:     member.user.name,
                userInitials: member.user.avatarInitials,
                userColor:    member.user.avatarColor,
                semester:     semester,
                amount:       member.user.role == .pledge ? amount * 0.6 : amount,
                amountPaid:   0,
                dueDate:      dueDate,
                status:       .unpaid,
                payments:     [],
                notes:        ""
            )
        }
        records = newRecords
        Task {
            for record in newRecords {
                try? await db.createDuesRecord(record, chapter: chapter)
            }
        }
    }

    func waivedDues(duesId: String, note: String) {
        guard let idx = records.firstIndex(where: { $0.id == duesId }) else { return }
        records[idx].status = .waived
        records[idx].notes  = note
        Task { try? await db.updateDuesStatus(duesId: duesId, status: .waived, notes: note) }
    }
}

// MARK: - Alumni ViewModel

class AlumniViewModel: ObservableObject {
    @Published var alumni: [AlumniMember]  = AlumniMember.mockList
    @Published var searchText              = ""
    @Published var mentorOnly              = false
    @Published var isLoading               = false

    private let db = FirestoreService.shared

    var filtered: [AlumniMember] {
        alumni.filter { a in
            let matchSearch = searchText.isEmpty ||
                a.name.localizedCaseInsensitiveContains(searchText) ||
                a.company.localizedCaseInsensitiveContains(searchText) ||
                a.currentRole.localizedCaseInsensitiveContains(searchText)
            let matchMentor = !mentorOnly || a.canMentor
            return matchSearch && matchMentor
        }
    }

    func load(chapter: String) {
        isLoading = true
        Task {
            let fetched = (try? await db.fetchAlumni(chapter: chapter)) ?? AlumniMember.mockList
            await MainActor.run {
                self.alumni    = fetched
                self.isLoading = false
            }
        }
    }
}

// MARK: - Badges ViewModel

class BadgesViewModel: ObservableObject {
    @Published var allBadges: [GHBadge]    = GHBadge.allBadges
    @Published var memberBadges: [String: [GHBadge]] = [:]  // userId → earned badges
    @Published var selectedCategory: BadgeCategory? = nil

    private let db = FirestoreService.shared

    var filteredBadges: [GHBadge] {
        guard let cat = selectedCategory else { return allBadges }
        return allBadges.filter { $0.category == cat }
    }

    var earnedBadges: [GHBadge]   { allBadges.filter { $0.isEarned } }
    var unearnedBadges: [GHBadge] { allBadges.filter { !$0.isEarned } }

    func loadBadges(userId: String) {
        Task {
            let earned = (try? await db.fetchEarnedBadges(userId: userId)) ?? []
            var updated = GHBadge.allBadges
            for i in updated.indices {
                if let match = earned.first(where: { $0.id == updated[i].id }) {
                    updated[i].earnedAt = match.earnedAt
                }
            }
            await MainActor.run { self.allBadges = updated }
        }
    }

    func awardBadge(badgeId: String, userId: String, officerName: String) {
        if let idx = allBadges.firstIndex(where: { $0.id == badgeId }) {
            allBadges[idx].earnedAt = Date()
        }
        Task { try? await db.awardBadge(badgeId: badgeId, userId: userId, awardedBy: officerName) }
    }

    // Evaluate which badges a user has auto-earned based on their stats
    func evaluateBadges(user: User, attendanceRate: Double, serviceHours: Int,
                        postCount: Int, checkInsCount: Int) {
        var toAward: [String] = []

        for badge in allBadges where !badge.isEarned {
            switch badge.requirement {
            case .attendanceRate(let req) where attendanceRate >= req:
                toAward.append(badge.id)
            case .pointsThreshold(let req) where user.points >= req:
                toAward.append(badge.id)
            case .serviceHours(let req) where serviceHours >= req:
                toAward.append(badge.id)
            case .postCount(let req) where postCount >= req:
                toAward.append(badge.id)
            case .isOfficer where user.role.isOfficer:
                toAward.append(badge.id)
            default:
                break
            }
        }

        for badgeId in toAward {
            awardBadge(badgeId: badgeId, userId: user.id, officerName: "system")
        }
    }
}
