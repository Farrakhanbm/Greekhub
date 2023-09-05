import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM:  AuthViewModel
    @StateObject private var feedVM    = FeedViewModel()
    @StateObject private var eventsVM  = EventsViewModel()
    @StateObject private var chatVM    = ChatViewModel()
    @StateObject private var rosterVM  = RosterViewModel()
    @StateObject private var pointsVM  = PointsViewModel()
    @StateObject private var mediaVM   = MediaViewModel()
    @StateObject private var notifVM   = NotificationsViewModel()
    @State private var selectedTab     = 0
    @State private var showNotifs      = false

    private var chapter:   String { authVM.currentUser.chapter }
    private var isOfficer: Bool   { authVM.currentUser.role.isOfficer }

    private var tabs: [(icon: String, label: String)] {
        isOfficer
        ? [("house.fill","Feed"),("calendar","Events"),("bubble.left.fill","Chat"),
           ("photo.stack.fill","Media"),("crown.fill","Officer")]
        : [("house.fill","Feed"),("calendar","Events"),("bubble.left.fill","Chat"),
           ("photo.stack.fill","Media"),("person.crop.circle","Profile")]
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {

                // 0 — Feed
                NavigationStack {
                    FeedView()
                        .environmentObject(feedVM)
                        .environmentObject(authVM)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                notifBell
                            }
                        }
                }
                .tag(0)

                // 1 — Events
                NavigationStack {
                    EventsView()
                        .environmentObject(eventsVM)
                        .environmentObject(authVM)
                }
                .tag(1)

                // 2 — Chat
                ChatListView()
                    .environmentObject(chatVM)
                    .environmentObject(authVM)
                    .tag(2)

                // 3 — Media Wall
                NavigationStack {
                    MediaWallView()
                        .environmentObject(authVM)
                }
                .tag(3)

                // 4 — Officer Hub or Profile
                if isOfficer {
                    NavigationStack {
                        OfficerHubView()
                            .environmentObject(authVM)
                            .environmentObject(pointsVM)
                    }
                    .tag(4)
                } else {
                    ProfileView()
                        .environmentObject(authVM)
                        .environmentObject(pointsVM)
                        .tag(4)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            GHTabBar(selectedTab: $selectedTab,
                     unreadCount: chatVM.totalUnread,
                     notifCount:  notifVM.unreadCount,
                     tabs:        tabs)
        }
        .background(Color.ghBackground).ignoresSafeArea()
        .onAppear {
            feedVM.startListening(chapter: chapter)
            eventsVM.startListening(chapter: chapter)
            chatVM.loadChannels(chapter: chapter)
            rosterVM.loadRoster(chapter: chapter)
            pointsVM.loadLeaderboard(chapter: chapter)
            mediaVM.startListening(chapter: chapter)
            notifVM.loadNotifications(userId: authVM.currentUser.id)
            notifVM.requestPermission(userId: authVM.currentUser.id)
        }
        .onDisappear {
            feedVM.stopListening()
            eventsVM.stopListening()
            chatVM.stopListening()
            mediaVM.stopListening()
        }
        .sheet(isPresented: $showNotifs) {
            NotificationsView().environmentObject(authVM)
        }
    }

    private var notifBell: some View {
        Button { showNotifs = true } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 18)).foregroundColor(.ghTextMuted)
                if notifVM.unreadCount > 0 {
                    Text("\(min(notifVM.unreadCount, 9))")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 15, height: 15)
                        .background(Color.ghGold)
                        .clipShape(Circle())
                        .offset(x: 6, y: -6)
                }
            }
        }
    }
}

// MARK: - Officer Hub

struct OfficerHubView: View {
    @EnvironmentObject var authVM:  AuthViewModel
    @EnvironmentObject var pointsVM: PointsViewModel
    @State private var showProfile = false

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Image(systemName: "crown.fill").font(.system(size: 14)).foregroundColor(.ghGold)
                                Text("Officer Hub").font(.ghTitle).foregroundColor(.ghText)
                            }
                            Text(authVM.currentUser.role.rawValue).font(.ghCaption).foregroundColor(.ghGold)
                        }
                        Spacer()
                        Button { showProfile = true } label: {
                            AvatarView(initials: authVM.currentUser.avatarInitials,
                                       colorHex: authVM.currentUser.avatarColor, size: 36)
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 60).padding(.bottom, 20)

                    // Tools
                    VStack(spacing: 12) {
                        Text("TOOLS").font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.ghTextMuted).kerning(0.8)
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            NavigationLink(destination: OfficerDashboardView().environmentObject(authVM)) {
                                OfficerToolCard(icon: "chart.bar.fill", label: "Dashboard",
                                                detail: "Attendance & analytics", color: .ghBlue)
                            }.buttonStyle(.plain)

                            NavigationLink(destination: OfficerPointsView().environmentObject(authVM)) {
                                OfficerToolCard(icon: "bolt.fill", label: "Points",
                                                detail: "Award & adjust", color: .ghGold)
                            }.buttonStyle(.plain)

                            NavigationLink(destination: NavigationStack { RushView().environmentObject(authVM) }) {
                                OfficerToolCard(icon: "person.badge.plus.fill", label: "Rush",
                                                detail: "PNMs, votes & bids", color: .ghPink)
                            }.buttonStyle(.plain)

                            NavigationLink(destination: CreateEventView()
                                .environmentObject(authVM)
                                .environmentObject(EventsViewModel())) {
                                OfficerToolCard(icon: "calendar.badge.plus", label: "New Event",
                                                detail: "Create & schedule", color: .ghPurple)
                            }.buttonStyle(.plain)

                            NavigationLink(destination: DuesView().environmentObject(authVM)) {
                                OfficerToolCard(icon: "dollarsign.circle.fill", label: "Dues",
                                                detail: "Track & record payments", color: .ghGreen)
                            }.buttonStyle(.plain)

                            NavigationLink(destination: NavigationStack {
                                AlumniView().environmentObject(authVM)
                            }) {
                                OfficerToolCard(icon: "building.columns.fill", label: "Alumni",
                                                detail: "Network & mentors", color: .ghBlue)
                            }.buttonStyle(.plain)

                            NavigationLink(destination: OfficerBadgeAwardView().environmentObject(authVM)) {
                                OfficerToolCard(icon: "seal.fill", label: "Badges",
                                                detail: "Award to members", color: .ghPurple)
                            }.buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 20)

                    // Leaderboard preview
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("LEADERBOARD").font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.ghTextMuted).kerning(0.8)
                            Spacer()
                            NavigationLink("See all") {
                                LeaderboardView().environmentObject(pointsVM)
                            }
                            .font(.ghCaption).foregroundColor(.ghGold)
                        }
                        .padding(.horizontal, 20).padding(.bottom, 10)

                        ForEach(pointsVM.leaderboard.prefix(5)) { entry in
                            LeaderboardRow(entry: entry)
                            Divider().background(Color.ghBorder).padding(.leading, 68)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showProfile) {
            NavigationStack {
                ProfileView().environmentObject(authVM).environmentObject(pointsVM)
            }
        }
    }
}

// MARK: - Officer Tool Card

struct OfficerToolCard: View {
    let icon: String; let label: String; let detail: String; let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 44, height: 44)
                Image(systemName: icon).font(.system(size: 18)).foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.ghHeadline).foregroundColor(.ghText)
                Text(detail).font(.ghCaption).foregroundColor(.ghTextMuted).lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14).ghCard()
    }
}

// MARK: - Placeholder screens

struct OfficerRosterManageView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var rosterVM = RosterViewModel()
    var body: some View {
        RosterView().environmentObject(rosterVM)
            .onAppear { rosterVM.loadRoster(chapter: authVM.currentUser.chapter) }
    }
}

struct CreateEventView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var eventsVM: EventsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var title = ""; @State private var description = ""
    @State private var location = ""; @State private var date = Date().addingTimeInterval(86400)
    @State private var endDate = Date().addingTimeInterval(86400 + 3600)
    @State private var type = EventType.meeting; @State private var pointValue = 1
    @State private var requiresCheckIn = true

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button("Cancel") { dismiss() }.font(.ghCallout).foregroundColor(.ghTextMuted)
                    Spacer()
                    Text("New Event").font(.ghHeadline).foregroundColor(.ghText)
                    Spacer()
                    Button("Create") {
                        let e = ChapterEvent(id: UUID().uuidString, title: title,
                            description: description, location: location,
                            date: date, endDate: endDate, type: type,
                            pointValue: pointValue, rsvpCount: 0, capacity: nil,
                            isRSVPed: false, requiresCheckIn: requiresCheckIn,
                            organizerName: authVM.currentUser.name)
                        eventsVM.createEvent(e, chapter: authVM.currentUser.chapter)
                        dismiss()
                    }
                    .font(.ghCallout).foregroundColor(title.isEmpty ? .ghTextMuted : .ghGold)
                    .disabled(title.isEmpty)
                }
                .padding(.horizontal, 20).padding(.vertical, 16)
                Divider().background(Color.ghBorder)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        SectionLabel("Details")
                        GHTextField(label: "Title",    placeholder: "Chapter Meeting",   text: $title)
                        GHTextField(label: "Location", placeholder: "Student Union 204", text: $location)
                        GHTextField(label: "Description", placeholder: "What to expect...", text: $description)

                        SectionLabel("Schedule").padding(.top, 8)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Start").font(.ghCaption).foregroundColor(.ghTextMuted)
                            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact).colorScheme(.dark)
                                .padding(12).background(Color.ghSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        SectionLabel("Settings").padding(.top, 8)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(EventType.allCases, id: \.self) { t in
                                    FilterChip(label: t.rawValue, isSelected: type == t,
                                               color: Color(hex: t.color)) { type = t }
                                }
                            }
                        }

                        HStack(spacing: 16) {
                            ForEach([0,1,2,3,5], id: \.self) { pts in
                                Button { pointValue = pts } label: {
                                    Text("\(pts)").font(.ghHeadline)
                                        .foregroundColor(pointValue == pts ? .black : .ghGold)
                                        .frame(width: 44, height: 44)
                                        .background(pointValue == pts ? Color.ghGold : Color.ghGold.opacity(0.1))
                                        .clipShape(Circle())
                                }
                            }
                        }

                        Toggle(isOn: $requiresCheckIn) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("QR Check-In").font(.ghCallout).foregroundColor(.ghText)
                                Text("Members scan to earn points").font(.ghCaption).foregroundColor(.ghTextMuted)
                            }
                        }
                        .tint(.ghGold).padding(14).ghCard()
                        Spacer().frame(height: 60)
                    }
                    .padding(.horizontal, 20).padding(.top, 20)
                }
            }
        }
    }
}

// MARK: - Tab Bar

struct GHTabBar: View {
    @Binding var selectedTab: Int
    var unreadCount: Int
    var notifCount:  Int  = 0
    var tabs: [(icon: String, label: String)]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedTab = i }
                } label: {
                    VStack(spacing: 4) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: tabs[i].icon)
                                .font(.system(size: 22, weight: selectedTab == i ? .semibold : .regular))
                                .foregroundColor(selectedTab == i ? .ghGold : .ghTextMuted)
                                .scaleEffect(selectedTab == i ? 1.08 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedTab)

                            if i == 2 && unreadCount > 0 {
                                badge(unreadCount)
                            }
                        }
                        Text(tabs[i].label)
                            .font(.system(size: 10, weight: selectedTab == i ? .semibold : .regular))
                            .foregroundColor(selectedTab == i ? .ghGold : .ghTextMuted)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                }
            }
        }
        .padding(.horizontal, 8).padding(.bottom, 24)
        .background(Color.ghSurface
            .overlay(Rectangle().fill(Color.ghBorder).frame(height: 0.5), alignment: .top))
    }

    private func badge(_ count: Int) -> some View {
        Text("\(min(count, 9))")
            .font(.system(size: 9, weight: .bold)).foregroundColor(.black)
            .frame(width: 15, height: 15)
            .background(Color.ghRed).clipShape(Circle())
            .offset(x: 8, y: -6)
    }
}
