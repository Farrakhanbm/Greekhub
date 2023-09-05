import Foundation
import FirebaseFirestore
import CoreImage
import UIKit

// MARK: - Points ViewModel (full Phase 2)

class PointsViewModel: ObservableObject {
    @Published var leaderboard: [PointsEntry]  = []
    @Published var myHistory: [PointsEvent]    = []
    @Published var isLoading = false

    private let db = FirestoreService.shared

    func loadLeaderboard(chapter: String) {
        isLoading = true
        Task {
            do {
                let users   = try await db.fetchRoster(chapter: chapter)
                let sorted  = users.sorted { $0.points > $1.points }
                let entries = sorted.enumerated().map { i, u in
                    PointsEntry(
                        id: "pts_\(u.id)",
                        member: RosterMember(id: u.id, user: u, phone: "", email: "", isActive: u.isActive),
                        rank: i + 1,
                        pointsThisSemester: u.points,
                        attendanceRate: 0,
                        serviceHours: 0
                    )
                }
                await MainActor.run {
                    self.leaderboard = entries
                    self.isLoading   = false
                }
            } catch {
                await MainActor.run { self.isLoading = false }
            }
        }
    }

    func loadHistory(userId: String) {
        Task {
            let events = (try? await db.fetchPointsHistory(userId: userId)) ?? []
            await MainActor.run { self.myHistory = events }
        }
    }
}

// MARK: - Officer Points ViewModel

class OfficerPointsViewModel: ObservableObject {
    @Published var members: [RosterMember]     = []
    @Published var recentAwards: [PointsEvent] = []
    @Published var award = PointsAwardRequest()
    @Published var isSubmitting = false
    @Published var successMessage: String?
    @Published var errorMessage: String?

    private let db = FirestoreService.shared

    func loadMembers(chapter: String) {
        Task {
            let users = (try? await db.fetchRoster(chapter: chapter)) ?? []
            let roster = users.map { RosterMember(id: $0.id, user: $0, phone: "", email: "", isActive: $0.isActive) }
            await MainActor.run { self.members = roster }
        }
    }

    func loadRecentAwards(chapter: String) {
        Task {
            let events = (try? await db.fetchRecentAwards(chapter: chapter)) ?? []
            await MainActor.run { self.recentAwards = events }
        }
    }

    func submitAward(officerName: String) {
        guard !award.memberId.isEmpty, award.amount != 0 else {
            errorMessage = "Select a member and enter an amount."; return
        }
        isSubmitting   = true
        errorMessage   = nil
        successMessage = nil
        Task {
            do {
                try await db.awardPoints(
                    userId:    award.memberId,
                    amount:    award.amount,
                    reason:    award.reason.rawValue,
                    note:      award.note,
                    awardedBy: officerName
                )
                await MainActor.run {
                    self.successMessage = "\(award.amount > 0 ? "+" : "")\(award.amount) pts awarded to \(award.memberName)"
                    self.award          = PointsAwardRequest()
                    self.isSubmitting   = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isSubmitting  = false
                }
            }
        }
    }
}

// MARK: - QR Check-In ViewModel

class CheckInViewModel: ObservableObject {
    // Officer side — generate QR
    @Published var qrImage: UIImage?
    @Published var activeEvent: ChapterEvent?

    // Member side — scan result
    @Published var scanResult: CheckInScanResult = .idle
    @Published var isScannerActive = false

    private let db = FirestoreService.shared

    enum CheckInScanResult {
        case idle
        case scanning
        case success(eventTitle: String, points: Int)
        case alreadyCheckedIn(eventTitle: String)
        case error(String)
    }

    // Officer: generate a QR code for an event
    func generateQR(for event: ChapterEvent) {
        activeEvent = event
        let payload = CheckInPayload(eventId: event.id, eventTitle: event.title,
                                     pointValue: event.pointValue,
                                     chapter: event.organizerName)
        guard
            let data   = try? JSONEncoder().encode(payload),
            let string = String(data: data, encoding: .utf8)
        else { return }

        let filter  = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let ciImage = filter.outputImage else { return }
        let scaled   = ciImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        let context  = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return }
        qrImage = UIImage(cgImage: cgImage)
    }

    // Member: process scanned QR payload
    func processScannedCode(_ code: String, user: User) {
        guard
            let data    = code.data(using: .utf8),
            let payload = try? JSONDecoder().decode(CheckInPayload.self, from: data)
        else {
            scanResult = .error("Invalid QR code — make sure you're scanning an event check-in code.")
            return
        }

        scanResult = .scanning
        Task {
            do {
                let alreadyIn = try await db.isCheckedIn(eventId: payload.eventId, userId: user.id)
                if alreadyIn {
                    await MainActor.run {
                        self.scanResult = .alreadyCheckedIn(eventTitle: payload.eventTitle)
                    }
                    return
                }
                try await db.recordCheckIn(
                    eventId:    payload.eventId,
                    eventTitle: payload.eventTitle,
                    user:       user,
                    points:     payload.pointValue
                )
                await MainActor.run {
                    self.scanResult = .success(eventTitle: payload.eventTitle, points: payload.pointValue)
                }
            } catch {
                await MainActor.run {
                    self.scanResult = .error(error.localizedDescription)
                }
            }
        }
    }

    func resetScan() { scanResult = .idle }
}

// QR payload — what's encoded in each event's QR code
struct CheckInPayload: Codable {
    let eventId:    String
    let eventTitle: String
    let pointValue: Int
    let chapter:    String
}

// MARK: - Officer Dashboard ViewModel

class OfficerDashboardViewModel: ObservableObject {
    @Published var analytics: ChapterAnalytics = .mock
    @Published var isLoading = false

    private let db = FirestoreService.shared

    func load(chapter: String) {
        isLoading = true
        Task {
            do {
                let analytics = try await db.fetchAnalytics(chapter: chapter)
                await MainActor.run {
                    self.analytics = analytics
                    self.isLoading = false
                }
            } catch {
                // Fall back to mock data while Firestore is being populated
                await MainActor.run { self.isLoading = false }
            }
        }
    }
}
