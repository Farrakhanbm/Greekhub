import Foundation
import FirebaseFirestore
import FirebaseStorage
import UIKit

// MARK: - Rush ViewModel

class RushViewModel: ObservableObject {
    @Published var pnms: [PNM]                  = PNM.mockList
    @Published var season: RushSeason            = .mock
    @Published var selectedStatus: PNMStatus?    = nil
    @Published var searchText                    = ""
    @Published var isLoading                     = false

    private let db = FirestoreService.shared
    private var listener: ListenerRegistration?

    var filtered: [PNM] {
        pnms.filter { pnm in
            let matchSearch = searchText.isEmpty ||
                pnm.fullName.localizedCaseInsensitiveContains(searchText) ||
                pnm.major.localizedCaseInsensitiveContains(searchText)
            let matchStatus = selectedStatus == nil || pnm.status == selectedStatus
            return matchSearch && matchStatus
        }
    }

    var statusCounts: [PNMStatus: Int] {
        Dictionary(grouping: pnms, by: { $0.status }).mapValues { $0.count }
    }

    func startListening(chapter: String) {
        listener?.remove()
        listener = db.rushListener(chapter: chapter) { [weak self] pnms in
            DispatchQueue.main.async { self?.pnms = pnms }
        }
    }

    func stopListening() { listener?.remove() }

    func addPNM(_ pnm: PNM, chapter: String) {
        Task { try? await db.createPNM(pnm, chapter: chapter) }
    }

    func updateStatus(pnmId: String, status: PNMStatus) {
        if let idx = pnms.firstIndex(where: { $0.id == pnmId }) {
            pnms[idx].status = status
        }
        Task { try? await db.updatePNMStatus(pnmId: pnmId, status: status) }
    }

    func submitVote(pnmId: String, vote: OfficerVote) {
        if let idx = pnms.firstIndex(where: { $0.id == pnmId }) {
            pnms[idx].votes.removeAll { $0.officerId == vote.officerId }
            pnms[idx].votes.append(vote)
        }
        Task { try? await db.submitVote(pnmId: pnmId, vote: vote) }
    }

    func addNote(pnmId: String, note: PNMNote) {
        if let idx = pnms.firstIndex(where: { $0.id == pnmId }) {
            pnms[idx].notes.append(note)
        }
        Task { try? await db.addPNMNote(pnmId: pnmId, note: note) }
    }

    func offerBid(pnmId: String) {
        updateStatus(pnmId: pnmId, status: .bidOffered)
    }
}

// MARK: - Notifications ViewModel

class NotificationsViewModel: ObservableObject {
    @Published var notifications: [GHNotification] = GHNotification.mockList
    @Published var fcmToken: String?
    @Published var permissionGranted = false

    private let db = FirestoreService.shared

    var unreadCount: Int { notifications.filter { !$0.isRead }.count }

    func requestPermission(userId: String) {
        Task {
            let granted = try? await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run { self.permissionGranted = granted ?? false }
            if granted == true { await registerForRemoteNotifications() }
        }
    }

    @MainActor
    private func registerForRemoteNotifications() async {
        UIApplication.shared.registerForRemoteNotifications()
    }

    func saveFCMToken(_ token: String, userId: String) {
        fcmToken = token
        Task { try? await db.saveFCMToken(token, userId: userId) }
    }

    func markAllRead() {
        for i in notifications.indices { notifications[i].isRead = true }
    }

    func markRead(id: String) {
        if let idx = notifications.firstIndex(where: { $0.id == id }) {
            notifications[idx].isRead = true
        }
    }

    func loadNotifications(userId: String) {
        Task {
            let notifs = (try? await db.fetchNotifications(userId: userId)) ?? GHNotification.mockList
            await MainActor.run { self.notifications = notifs }
        }
    }
}

// MARK: - Media ViewModel

class MediaViewModel: ObservableObject {
    @Published var posts: [MediaPost]           = MediaPost.mockWall
    @Published var isUploading                  = false
    @Published var uploadProgress: Double       = 0
    @Published var selectedEvent: ChapterEvent? = nil

    private let db      = FirestoreService.shared
    private let storage = Storage.storage()
    private var listener: ListenerRegistration?

    func startListening(chapter: String) {
        listener?.remove()
        listener = db.mediaListener(chapter: chapter) { [weak self] posts in
            DispatchQueue.main.async { self?.posts = posts }
        }
    }

    func stopListening() { listener?.remove() }

    func uploadPhoto(image: UIImage, caption: String, event: ChapterEvent?,
                     uploader: User) {
        guard let data = image.jpegData(compressionQuality: 0.75) else { return }
        isUploading = true
        uploadProgress = 0

        let path = "media/\(uploader.chapter)/\(UUID().uuidString).jpg"
            .replacingOccurrences(of: " ", with: "_")
        let ref  = storage.reference().child(path)
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"

        let task = ref.putData(data, metadata: meta)
        task.observe(.progress) { [weak self] snap in
            let pct = Double(snap.progress?.completedUnitCount ?? 0)
                    / Double(snap.progress?.totalUnitCount ?? 1)
            DispatchQueue.main.async { self?.uploadProgress = pct }
        }
        task.observe(.success) { [weak self] _ in
            ref.downloadURL { url, _ in
                guard let url else { return }
                let post = MediaPost(
                    id:               UUID().uuidString,
                    uploaderName:     uploader.name,
                    uploaderInitials: uploader.avatarInitials,
                    uploaderColor:    uploader.avatarColor,
                    uploaderId:       uploader.id,
                    eventId:          event?.id,
                    eventTitle:       event?.title,
                    imageURL:         url.absoluteString,
                    caption:          caption,
                    likes:            0,
                    isLiked:          false,
                    uploadedAt:       Date(),
                    chapter:          uploader.chapter
                )
                Task { try? await self?.db.createMediaPost(post) }
                DispatchQueue.main.async {
                    self?.isUploading   = false
                    self?.uploadProgress = 0
                }
            }
        }
        task.observe(.failure) { [weak self] _ in
            DispatchQueue.main.async {
                self?.isUploading    = false
                self?.uploadProgress = 0
            }
        }
    }

    func toggleLike(postId: String, userId: String) {
        if let idx = posts.firstIndex(where: { $0.id == postId }) {
            Task { try? await db.toggleMediaLike(postId: postId, userId: userId) }
        }
    }
}
