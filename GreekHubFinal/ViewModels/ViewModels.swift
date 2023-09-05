import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

// MARK: - Auth ViewModel

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn     = false
    @Published var isCheckingAuth = true
    @Published var isLoading      = false
    @Published var currentUser: User = .mock
    @Published var errorMessage: String?

    private let authService = AuthService.shared
    private let db          = FirestoreService.shared
    private var authHandle: AuthStateDidChangeListenerHandle?

    init() { listenToAuthState() }

    deinit {
        if let handle = authHandle { Auth.auth().removeStateDidChangeListener(handle) }
    }

    private func listenToAuthState() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            Task { @MainActor in
                if let user {
                    await self.loadCurrentUser(uid: user.uid)
                    self.isLoggedIn = true
                } else {
                    self.isLoggedIn = false
                }
                self.isCheckingAuth = false
            }
        }
    }

    @MainActor
    private func loadCurrentUser(uid: String) async {
        do { currentUser = try await db.fetchUser(uid: uid) }
        catch { print("AuthVM: could not load user — \(error.localizedDescription)") }
    }

    func login(email: String, password: String) {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter your email and password."; return
        }
        isLoading = true; errorMessage = nil
        Task {
            do { try await authService.signIn(email: email, password: password) }
            catch { await MainActor.run { self.errorMessage = AuthError.from(error).errorDescription } }
            await MainActor.run { self.isLoading = false }
        }
    }

    func register(name: String, email: String, password: String,
                  chapter: String, pledgeClass: String, major: String, year: String) {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all required fields."; return
        }
        isLoading = true; errorMessage = nil
        Task {
            do {
                let uid      = try await authService.signUp(email: email, password: password)
                let initials = name.split(separator: " ").compactMap { $0.first.map(String.init) }.prefix(2).joined().uppercased()
                let colors   = ["#C9A84C","#4C6BC9","#4CC99A","#C94C8A","#8A4CC9","#C94C4C"]
                let newUser  = User(id: uid, name: name,
                    username: email.components(separatedBy: "@").first ?? uid,
                    avatarInitials: initials, avatarColor: colors.randomElement()!,
                    chapter: chapter, role: .member, points: 0,
                    pledgeClass: pledgeClass, major: major, year: year,
                    bio: "", isActive: true)
                try await db.createUser(newUser)
                await MainActor.run { self.currentUser = newUser }
            } catch {
                await MainActor.run { self.errorMessage = AuthError.from(error).errorDescription }
            }
            await MainActor.run { self.isLoading = false }
        }
    }

    func logout() { try? authService.signOut() }

    func sendPasswordReset(email: String) {
        Task {
            do {
                try await authService.sendPasswordReset(email: email)
                await MainActor.run { self.errorMessage = "Reset email sent — check your inbox." }
            } catch {
                await MainActor.run { self.errorMessage = error.localizedDescription }
            }
        }
    }

    func updateBio(_ bio: String) {
        guard let uid = authService.currentUID else { return }
        Task {
            try? await db.updateUser(uid: uid, fields: ["bio": bio])
            await MainActor.run { self.currentUser.bio = bio }
        }
    }
}

// MARK: - Feed ViewModel

class FeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var newPostText = ""
    @Published var isPosting   = false

    private let db = FirestoreService.shared
    private var listener: ListenerRegistration?

    func startListening(chapter: String) {
        listener?.remove()
        listener = db.feedListener(chapter: chapter) { [weak self] posts in
            DispatchQueue.main.async { self?.posts = posts }
        }
    }

    func stopListening() { listener?.remove() }

    func toggleLike(postID: String) {
        guard let uid = AuthService.shared.currentUID else { return }
        if let idx = posts.firstIndex(where: { $0.id == postID }) {
            posts[idx].isLiked.toggle()
            posts[idx].likes += posts[idx].isLiked ? 1 : -1
        }
        Task { try? await db.toggleLike(postId: postID, userId: uid) }
    }

    func submitPost(author: User) {
        let text = newPostText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        isPosting = true; newPostText = ""
        let post = Post(id: UUID().uuidString, author: author, content: text,
                        imageURL: nil, likes: 0, comments: [], isLiked: false,
                        postedAt: Date(), isOfficerPost: author.role.isOfficer, tag: nil)
        Task {
            try? await db.createPost(post)
            await MainActor.run { self.isPosting = false }
        }
    }
}

// MARK: - Events ViewModel

class EventsViewModel: ObservableObject {
    @Published var events: [ChapterEvent] = []
    @Published var selectedFilter: EventType? = nil

    private let db = FirestoreService.shared
    private var listener: ListenerRegistration?

    var filtered: [ChapterEvent] {
        guard let f = selectedFilter else { return events }
        return events.filter { $0.type == f }
    }

    func startListening(chapter: String) {
        listener?.remove()
        listener = db.eventsListener(chapter: chapter) { [weak self] events in
            DispatchQueue.main.async { self?.events = events }
        }
    }

    func stopListening() { listener?.remove() }

    func toggleRSVP(eventID: String, user: User) {
        guard let idx = events.firstIndex(where: { $0.id == eventID }) else { return }
        events[idx].isRSVPed.toggle()
        events[idx].rsvpCount += events[idx].isRSVPed ? 1 : -1
        Task { try? await db.toggleRSVP(eventId: eventID, userId: user.id, userName: user.name) }
    }

    func createEvent(_ event: ChapterEvent, chapter: String) {
        Task { try? await db.createEvent(event, chapter: chapter) }
    }
}

// MARK: - Chat ViewModel

class ChatViewModel: ObservableObject {
    @Published var channels: [ChatChannel] = []
    @Published var messages: [ChatMessage] = []
    @Published var newMessage = ""
    @Published var selectedChannel: ChatChannel?

    private let db = FirestoreService.shared
    private var msgListener: ListenerRegistration?

    func loadChannels(chapter: String) {
        Task {
            let chs = (try? await db.fetchChannels(chapter: chapter)) ?? []
            await MainActor.run { self.channels = chs }
        }
    }

    func selectChannel(_ channel: ChatChannel) {
        selectedChannel = channel
        msgListener?.remove()
        msgListener = db.messagesListener(channelId: channel.id) { [weak self] msgs in
            DispatchQueue.main.async { self?.messages = msgs }
        }
    }

    func sendMessage(author: User) {
        let text = newMessage.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, let channel = selectedChannel else { return }
        newMessage = ""
        let msg = ChatMessage(id: UUID().uuidString, author: author, text: text,
                              sentAt: Date(), isFromCurrentUser: true)
        messages.append(msg)
        Task { try? await db.sendMessage(channelId: channel.id, message: msg) }
    }

    func stopListening() { msgListener?.remove() }

    var totalUnread: Int { channels.reduce(0) { $0 + $1.unreadCount } }
}

// MARK: - Roster ViewModel

class RosterViewModel: ObservableObject {
    @Published var members: [RosterMember] = []
    @Published var searchText  = ""
    @Published var roleFilter: MemberRole? = nil

    private let db = FirestoreService.shared

    var filtered: [RosterMember] {
        members.filter { m in
            let matchSearch = searchText.isEmpty || m.user.name.localizedCaseInsensitiveContains(searchText)
            let matchRole   = roleFilter == nil || m.user.role == roleFilter
            return matchSearch && matchRole
        }
    }

    func loadRoster(chapter: String) {
        Task {
            let users  = (try? await db.fetchRoster(chapter: chapter)) ?? []
            let roster = users.map { RosterMember(id: $0.id, user: $0, phone: "", email: "", isActive: $0.isActive) }
            await MainActor.run { self.members = roster }
        }
    }
}

// MARK: - Points ViewModel

class PointsViewModel: ObservableObject {
    @Published var leaderboard: [PointsEntry] = []

    private let db = FirestoreService.shared

    func loadLeaderboard(chapter: String) {
        Task {
            do {
                let users   = try await db.fetchRoster(chapter: chapter)
                let sorted  = users.sorted { $0.points > $1.points }
                let entries = sorted.enumerated().map { i, u in
                    PointsEntry(id: "pts_\(u.id)",
                        member: RosterMember(id: u.id, user: u, phone: "", email: "", isActive: u.isActive),
                        rank: i + 1, pointsThisSemester: u.points, attendanceRate: 0, serviceHours: 0)
                }
                await MainActor.run { self.leaderboard = entries }
            } catch { print("PointsVM: \(error.localizedDescription)") }
        }
    }
}
