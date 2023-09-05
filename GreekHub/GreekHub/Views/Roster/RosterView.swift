import SwiftUI

struct RosterView: View {
    @EnvironmentObject var rosterVM: RosterViewModel
    @State private var showRoleFilter = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ghBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Text("Roster")
                            .font(.ghTitle)
                            .foregroundColor(.ghText)
                        Spacer()
                        Button {
                            showRoleFilter.toggle()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(rosterVM.roleFilter != nil ? .ghGold : .ghTextMuted)
                                if let role = rosterVM.roleFilter {
                                    Text(role.rawValue)
                                        .font(.ghCaption)
                                        .foregroundColor(.ghGold)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .padding(.bottom, 12)

                    // Search
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15))
                            .foregroundColor(.ghTextMuted)
                        TextField("", text: $rosterVM.searchText)
                            .placeholder(when: rosterVM.searchText.isEmpty) {
                                Text("Search members...").foregroundColor(.ghTextMuted)
                            }
                            .font(.ghBody)
                            .foregroundColor(.ghText)
                        if !rosterVM.searchText.isEmpty {
                            Button { rosterVM.searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(.ghTextMuted)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.ghSurface2)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                    // Role filter chips (if shown)
                    if showRoleFilter {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterChip(label: "All", isSelected: rosterVM.roleFilter == nil) {
                                    rosterVM.roleFilter = nil
                                }
                                ForEach(MemberRole.allCases, id: \.self) { role in
                                    FilterChip(label: role.rawValue, isSelected: rosterVM.roleFilter == role) {
                                        rosterVM.roleFilter = rosterVM.roleFilter == role ? nil : role
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                        }
                    }

                    Divider().background(Color.ghBorder)

                    // Member count
                    HStack {
                        Text("\(rosterVM.filtered.count) member\(rosterVM.filtered.count == 1 ? "" : "s")")
                            .font(.ghCaption)
                            .foregroundColor(.ghTextMuted)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)

                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(rosterVM.filtered) { member in
                                NavigationLink(destination: MemberDetailView(member: member)) {
                                    MemberRow(member: member)
                                }
                                .buttonStyle(.plain)
                                Divider().background(Color.ghBorder).padding(.leading, 68)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
        }
    }
}

// MARK: - Member Row

struct MemberRow: View {
    let member: RosterMember

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(initials: member.user.avatarInitials, colorHex: member.user.avatarColor, size: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(member.user.name)
                    .font(.ghHeadline)
                    .foregroundColor(.ghText)
                HStack(spacing: 6) {
                    Image(systemName: member.user.role.icon)
                        .font(.system(size: 10))
                        .foregroundColor(member.user.role.isOfficer ? .ghGold : .ghTextMuted)
                    Text(member.user.role.rawValue)
                        .font(.ghCaption)
                        .foregroundColor(member.user.role.isOfficer ? .ghGold : .ghTextMuted)
                    Text("·")
                        .font(.ghCaption)
                        .foregroundColor(.ghTextMuted)
                    Text(member.user.pledgeClass)
                        .font(.ghCaption)
                        .foregroundColor(.ghTextMuted)
                }
            }

            Spacer()

            HStack(spacing: 3) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.ghGold)
                Text("\(member.user.points)")
                    .font(.ghCaptionBold)
                    .foregroundColor(.ghGold)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.ghGold.opacity(0.1))
            .clipShape(Capsule())

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.ghTextMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Member Detail

struct MemberDetailView: View {
    let member: RosterMember

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // Hero header
                    VStack(spacing: 14) {
                        AvatarView(initials: member.user.avatarInitials, colorHex: member.user.avatarColor, size: 80)

                        VStack(spacing: 4) {
                            Text(member.user.name)
                                .font(.ghTitle)
                                .foregroundColor(.ghText)

                            HStack(spacing: 6) {
                                Image(systemName: member.user.role.icon)
                                    .font(.system(size: 12))
                                    .foregroundColor(member.user.role.isOfficer ? .ghGold : .ghTextMuted)
                                Text(member.user.role.rawValue)
                                    .font(.ghCallout)
                                    .foregroundColor(member.user.role.isOfficer ? .ghGold : .ghTextMuted)
                            }
                        }

                        if !member.user.bio.isEmpty {
                            Text(member.user.bio)
                                .font(.ghCallout)
                                .foregroundColor(.ghTextMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }

                        // Stats row
                        HStack(spacing: 0) {
                            StatPill(value: "\(member.user.points)", label: "Points")
                            Divider().background(Color.ghBorder).frame(height: 28)
                            StatPill(value: member.user.year, label: "Year")
                            Divider().background(Color.ghBorder).frame(height: 28)
                            StatPill(value: member.user.pledgeClass, label: "Line")
                        }
                        .padding(16)
                        .ghCard()
                    }
                    .padding(.top, 10)

                    // Details card
                    VStack(spacing: 0) {
                        MemberInfoRow(icon: "graduationcap.fill", label: "Major", value: member.user.major)
                        Divider().background(Color.ghBorder)
                        MemberInfoRow(icon: "house.fill", label: "Chapter", value: member.user.chapter)
                        Divider().background(Color.ghBorder)
                        MemberInfoRow(icon: "envelope.fill", label: "Email", value: member.email)
                        Divider().background(Color.ghBorder)
                        MemberInfoRow(icon: "phone.fill", label: "Phone", value: member.phone)
                    }
                    .ghCard()
                    .padding(.horizontal, 0)

                    // Action buttons
                    HStack(spacing: 12) {
                        ActionButton(icon: "envelope.fill", label: "Message", color: .ghBlue)
                        ActionButton(icon: "phone.fill", label: "Call", color: .ghGreen)
                    }
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(member.user.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.ghHeadline)
                .foregroundColor(.ghText)
            Text(label)
                .font(.ghCaption)
                .foregroundColor(.ghTextMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MemberInfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.ghGold)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.ghCaption)
                    .foregroundColor(.ghTextMuted)
                Text(value)
                    .font(.ghCallout)
                    .foregroundColor(.ghText)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        Button {} label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(.ghHeadline)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(color.opacity(0.3), lineWidth: 0.5))
        }
    }
}
