import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM:  AuthViewModel
    @EnvironmentObject var pointsVM: PointsViewModel
    @StateObject private var badgesVM = BadgesViewModel()
    @State private var showLeaderboard   = false
    @State private var showBadges        = false
    @State private var showAlumni        = false
    @State private var showLogoutConfirm = false
    @State private var showEditBio       = false
    @State private var editedBio         = ""

    var user: User { authVM.currentUser }

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Text("Profile").font(.ghTitle).foregroundColor(.ghText)
                        Spacer()
                        Button { showEditBio = true } label: {
                            Image(systemName: "pencil.circle").font(.system(size: 20))
                                .foregroundColor(.ghTextMuted)
                        }
                    }
                    .padding(.top, 60).padding(.horizontal, 20)

                    // Avatar + name
                    VStack(spacing: 14) {
                        AvatarView(initials: user.avatarInitials,
                                   colorHex: user.avatarColor, size: 88)
                        VStack(spacing: 4) {
                            Text(user.name).font(.ghTitle).foregroundColor(.ghText)
                            Text("@\(user.username)").font(.ghCallout).foregroundColor(.ghTextMuted)
                        }
                        HStack(spacing: 6) {
                            Image(systemName: user.role.icon).font(.system(size: 12)).foregroundColor(.ghGold)
                            Text(user.role.rawValue).ghPill(color: .ghGold)
                        }
                        if !user.bio.isEmpty {
                            Text(user.bio).font(.ghCallout).foregroundColor(.ghTextMuted)
                                .multilineTextAlignment(.center).padding(.horizontal, 24)
                        }
                    }
                    .padding(.top, 8)

                    // Stats grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()),
                                        GridItem(.flexible())], spacing: 12) {
                        StatCard(value: "\(user.points)", label: "Points",
                                 icon: "bolt.fill",                      color: .ghGold)
                        StatCard(value: user.year,        label: "Year",
                                 icon: "graduationcap.fill",             color: .ghBlue)
                        StatCard(value: "\(badgesVM.earnedBadges.count)", label: "Badges",
                                 icon: "seal.fill",                      color: .ghPurple)
                    }
                    .padding(.horizontal, 16)

                    // Earned badges preview
                    if !badgesVM.earnedBadges.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: "seal.fill").font(.system(size: 12))
                                        .foregroundColor(.ghPurple)
                                    Text("My Badges").font(.ghHeadline).foregroundColor(.ghText)
                                }
                                Spacer()
                                Button { showBadges = true } label: {
                                    Text("See all").font(.ghCaption).foregroundColor(.ghGold)
                                }
                            }
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(badgesVM.earnedBadges.prefix(6)) { badge in
                                        VStack(spacing: 6) {
                                            ZStack {
                                                Circle().fill(Color(hex: badge.color).opacity(0.2))
                                                    .frame(width: 44, height: 44)
                                                Image(systemName: badge.icon)
                                                    .font(.system(size: 18))
                                                    .foregroundColor(Color(hex: badge.color))
                                            }
                                            Text(badge.name)
                                                .font(.system(size: 9, weight: .semibold))
                                                .foregroundColor(.ghTextMuted)
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                                .frame(width: 52)
                                        }
                                    }
                                }
                                .padding(.horizontal, 2)
                            }
                        }
                        .padding(14).ghCard().padding(.horizontal, 16)
                    }

                    // Quick links
                    VStack(spacing: 10) {
                        ProfileActionRow(icon: "chart.bar.fill", label: "Leaderboard",
                                         detail: "See chapter standings", color: .ghGold) {
                            showLeaderboard = true
                        }
                        ProfileActionRow(icon: "building.columns.fill", label: "Alumni Network",
                                         detail: "Connect with brothers", color: .ghBlue) {
                            showAlumni = true
                        }
                    }
                    .padding(.horizontal, 16)

                    // Info card
                    VStack(spacing: 0) {
                        ProfileInfoRow(icon: "house.fill",            label: "Chapter",     value: user.chapter)
                        Divider().background(Color.ghBorder)
                        ProfileInfoRow(icon: "graduationcap.fill",    label: "Major",       value: user.major)
                        Divider().background(Color.ghBorder)
                        ProfileInfoRow(icon: "person.badge.clock.fill", label: "Pledge Class", value: user.pledgeClass)
                    }
                    .ghCard().padding(.horizontal, 16)

                    // Sign out
                    Button { showLogoutConfirm = true } label: {
                        Text("Sign Out")
                            .font(.ghHeadline).foregroundColor(.ghRed)
                            .frame(maxWidth: .infinity).frame(height: 50)
                            .background(Color.ghRed.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.ghRed.opacity(0.2), lineWidth: 0.5))
                    }
                    .padding(.horizontal, 16).padding(.bottom, 100)
                }
            }
        }
        .onAppear { badgesVM.loadBadges(userId: user.id) }
        .sheet(isPresented: $showLeaderboard) {
            LeaderboardView().environmentObject(pointsVM)
        }
        .sheet(isPresented: $showBadges) {
            NavigationStack { BadgesView().environmentObject(authVM) }
        }
        .sheet(isPresented: $showAlumni) {
            NavigationStack { AlumniView().environmentObject(authVM) }
        }
        .confirmationDialog("Sign out of GreekHub?",
                            isPresented: $showLogoutConfirm, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) { authVM.logout() }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showEditBio) {
            EditBioSheet(bio: user.bio) { newBio in
                authVM.updateBio(newBio)
            }
        }
    }
}

// MARK: - Profile Action Row

struct ProfileActionRow: View {
    let icon: String; let label: String; let detail: String
    let color: Color; let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(color.opacity(0.15)).frame(width: 40, height: 40)
                    Image(systemName: icon).font(.system(size: 16)).foregroundColor(color)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(label).font(.ghCallout).foregroundColor(.ghText)
                    Text(detail).font(.ghCaption).foregroundColor(.ghTextMuted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12)).foregroundColor(.ghTextMuted)
            }
            .padding(14).ghCard()
        }
    }
}

// MARK: - Edit Bio Sheet

struct EditBioSheet: View {
    @State var bio: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) var dismiss
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                Capsule().fill(Color.ghBorder).frame(width: 40, height: 4).padding(.top, 12)
                HStack {
                    Button("Cancel") { dismiss() }.font(.ghCallout).foregroundColor(.ghTextMuted)
                    Spacer()
                    Text("Edit Bio").font(.ghHeadline).foregroundColor(.ghText)
                    Spacer()
                    Button("Save") { onSave(bio); dismiss() }
                        .font(.ghCallout).foregroundColor(.ghGold)
                }
                .padding(.horizontal, 20).padding(.vertical, 16)
                Divider().background(Color.ghBorder)
                TextEditor(text: $bio)
                    .focused($focused)
                    .font(.ghBody).foregroundColor(.ghText)
                    .scrollContentBackground(.hidden).background(.clear)
                    .padding(20)
                Spacer()
            }
        }
        .onAppear { focused = true }
    }
}

// MARK: - Shared components used across screens

struct StatCard: View {
    let value: String; let label: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 18)).foregroundColor(color)
            Text(value).font(.ghHeadline).foregroundColor(.ghText)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(label).font(.ghCaption).foregroundColor(.ghTextMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16).ghCard()
    }
}

struct ProfileInfoRow: View {
    let icon: String; let label: String; let value: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 14))
                .foregroundColor(.ghGold).frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.ghCaption).foregroundColor(.ghTextMuted)
                Text(value).font(.ghCallout).foregroundColor(.ghText).lineLimit(2)
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
}
