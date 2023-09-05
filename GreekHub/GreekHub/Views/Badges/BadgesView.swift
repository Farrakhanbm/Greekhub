import SwiftUI

// MARK: - Badge Shelf (member view)

struct BadgesView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = BadgesViewModel()
    @State private var selectedCategory: BadgeCategory? = nil

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Badges")
                            .font(.ghTitle).foregroundColor(.ghText)
                        Text("\(vm.earnedBadges.count) earned · \(vm.unearnedBadges.count) to unlock")
                            .font(.ghCaption).foregroundColor(.ghTextMuted)
                    }
                    Spacer()
                    // Progress ring
                    ZStack {
                        Circle()
                            .stroke(Color.ghSurface2, lineWidth: 4)
                            .frame(width: 36, height: 36)
                        Circle()
                            .trim(from: 0,
                                  to: vm.allBadges.isEmpty ? 0 :
                                      Double(vm.earnedBadges.count) / Double(vm.allBadges.count))
                            .stroke(Color.ghGold, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 36, height: 36)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.6, dampingFraction: 0.8),
                                       value: vm.earnedBadges.count)
                        Text("\(vm.earnedBadges.count)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.ghGold)
                    }
                }
                .padding(.horizontal, 20).padding(.top, 60).padding(.bottom, 12)

                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", isSelected: selectedCategory == nil) {
                            selectedCategory = nil; vm.selectedCategory = nil
                        }
                        ForEach(BadgeCategory.allCases, id: \.self) { cat in
                            FilterChip(label: cat.rawValue, isSelected: selectedCategory == cat) {
                                selectedCategory = selectedCategory == cat ? nil : cat
                                vm.selectedCategory = selectedCategory
                            }
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 8)
                }

                Divider().background(Color.ghBorder)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Earned section
                        if !vm.earnedBadges.isEmpty {
                            BadgeSection(title: "Earned",
                                         badges: vm.filteredBadges.filter { $0.isEarned },
                                         dimmed: false)
                        }

                        // Locked section
                        let locked = vm.filteredBadges.filter { !$0.isEarned }
                        if !locked.isEmpty {
                            BadgeSection(title: "Locked", badges: locked, dimmed: true)
                        }
                    }
                    .padding(16).padding(.bottom, 100)
                }
            }
        }
        .onAppear { vm.loadBadges(userId: authVM.currentUser.id) }
    }
}

// MARK: - Badge Section

struct BadgeSection: View {
    let title: String
    let badges: [GHBadge]
    let dimmed: Bool

    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.ghTextMuted).kerning(0.8)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(badges) { badge in
                    BadgeTile(badge: badge, dimmed: dimmed)
                }
            }
        }
    }
}

// MARK: - Badge Tile

struct BadgeTile: View {
    let badge: GHBadge
    let dimmed: Bool
    @State private var showDetail = false

    var body: some View {
        Button { showDetail = true } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(dimmed
                              ? Color.ghSurface2
                              : Color(hex: badge.color).opacity(0.2))
                        .frame(width: 60, height: 60)
                    Circle()
                        .stroke(dimmed
                                ? Color.ghBorder
                                : Color(hex: badge.color).opacity(0.5),
                                lineWidth: 1.5)
                        .frame(width: 60, height: 60)

                    Image(systemName: badge.icon)
                        .font(.system(size: 24))
                        .foregroundColor(dimmed
                                         ? Color.ghTextMuted.opacity(0.4)
                                         : Color(hex: badge.color))

                    if dimmed {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.ghTextMuted)
                            .offset(x: 18, y: 18)
                    } else if badge.isEarned {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.ghGold)
                            .background(Circle().fill(Color.ghBackground).frame(width: 12, height: 12))
                            .offset(x: 18, y: 18)
                    }
                }

                Text(badge.name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(dimmed ? .ghTextMuted : .ghText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.vertical, 12).padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .background(dimmed ? Color.ghSurface.opacity(0.5) : Color.ghSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(dimmed ? Color.ghBorder.opacity(0.5) : Color.ghBorder, lineWidth: 0.5)
            )
            .opacity(dimmed ? 0.6 : 1.0)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            BadgeDetailSheet(badge: badge)
        }
    }
}

// MARK: - Badge Detail Sheet

struct BadgeDetailSheet: View {
    let badge: GHBadge
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                Capsule().fill(Color.ghBorder).frame(width: 40, height: 4).padding(.top, 12)

                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24)).foregroundColor(.ghTextMuted)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 20).padding(.top, 8)

                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(badge.isEarned
                                  ? Color(hex: badge.color).opacity(0.2)
                                  : Color.ghSurface2)
                            .frame(width: 100, height: 100)
                        Circle()
                            .stroke(badge.isEarned
                                    ? Color(hex: badge.color).opacity(0.5)
                                    : Color.ghBorder, lineWidth: 2)
                            .frame(width: 100, height: 100)
                        Image(systemName: badge.icon)
                            .font(.system(size: 40))
                            .foregroundColor(badge.isEarned
                                             ? Color(hex: badge.color)
                                             : .ghTextMuted.opacity(0.4))
                    }
                    .padding(.top, 20)

                    VStack(spacing: 8) {
                        Text(badge.name)
                            .font(.ghTitle).foregroundColor(.ghText)
                            .multilineTextAlignment(.center)
                        Text(badge.description)
                            .font(.ghCallout).foregroundColor(.ghTextMuted)
                            .multilineTextAlignment(.center)
                        Text(badge.category.rawValue.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(hex: badge.color))
                            .kerning(0.8)
                    }
                    .padding(.horizontal, 32)

                    // Status
                    if badge.isEarned, let earnedAt = badge.earnedAt {
                        VStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 24)).foregroundColor(.ghGold)
                            Text("Earned \(earnedAt.relativeString)")
                                .font(.ghCallout).foregroundColor(.ghGold)
                        }
                        .padding(16).background(Color.ghGold.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 20)).foregroundColor(.ghTextMuted)
                            Text("How to earn this badge")
                                .font(.ghHeadline).foregroundColor(.ghText)
                            Text(badge.requirement.description)
                                .font(.ghCallout).foregroundColor(.ghTextMuted)
                        }
                        .frame(maxWidth: .infinity).padding(16)
                        .background(Color.ghSurface2)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .padding(.horizontal, 20)
                    }
                }

                Spacer()
            }
        }
    }
}

// MARK: - Officer Badge Award Tool

struct OfficerBadgeAwardView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = BadgesViewModel()
    @StateObject private var rosterVM = RosterViewModel()
    @State private var selectedMember: RosterMember? = nil
    @State private var selectedBadge:  GHBadge?      = nil
    @State private var successMessage: String?        = nil

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Text("Award Badges")
                    .font(.ghTitle).foregroundColor(.ghText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20).padding(.top, 60).padding(.bottom, 14)

                Divider().background(Color.ghBorder)

                if let msg = successMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.ghGreen)
                        Text(msg).font(.ghCallout).foregroundColor(.ghGreen)
                        Spacer()
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Color.ghGreen.opacity(0.08))
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Step 1 — Pick member
                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabel("1. Select Member")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(rosterVM.members) { member in
                                        Button {
                                            selectedMember = member
                                        } label: {
                                            VStack(spacing: 6) {
                                                ZStack {
                                                    AvatarView(initials: member.user.avatarInitials,
                                                               colorHex: member.user.avatarColor, size: 44)
                                                    if selectedMember?.id == member.id {
                                                        Circle()
                                                            .stroke(Color.ghGold, lineWidth: 2.5)
                                                            .frame(width: 48, height: 48)
                                                    }
                                                }
                                                Text(member.user.name.components(separatedBy: " ").first ?? "")
                                                    .font(.ghCaption)
                                                    .foregroundColor(selectedMember?.id == member.id ? .ghGold : .ghTextMuted)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }

                        // Step 2 — Pick badge (manual-award ones only)
                        VStack(alignment: .leading, spacing: 10) {
                            SectionLabel("2. Select Badge")
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()),
                                                GridItem(.flexible())], spacing: 10) {
                                ForEach(GHBadge.allBadges) { badge in
                                    Button {
                                        selectedBadge = badge
                                    } label: {
                                        VStack(spacing: 6) {
                                            ZStack {
                                                Circle()
                                                    .fill(selectedBadge?.id == badge.id
                                                          ? Color(hex: badge.color).opacity(0.25)
                                                          : Color.ghSurface2)
                                                    .frame(width: 50, height: 50)
                                                Circle()
                                                    .stroke(selectedBadge?.id == badge.id
                                                            ? Color(hex: badge.color).opacity(0.7)
                                                            : Color.clear, lineWidth: 1.5)
                                                    .frame(width: 50, height: 50)
                                                Image(systemName: badge.icon)
                                                    .font(.system(size: 20))
                                                    .foregroundColor(Color(hex: badge.color))
                                            }
                                            Text(badge.name)
                                                .font(.system(size: 10, weight: .semibold))
                                                .foregroundColor(.ghText)
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                        }
                                        .padding(.vertical, 10)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // Step 3 — Confirm
                        if selectedMember != nil && selectedBadge != nil {
                            VStack(spacing: 6) {
                                HStack(spacing: 10) {
                                    AvatarView(initials: selectedMember!.user.avatarInitials,
                                               colorHex: selectedMember!.user.avatarColor, size: 36)
                                    Text("Award \"\(selectedBadge!.name)\" to \(selectedMember!.user.name)")
                                        .font(.ghCallout).foregroundColor(.ghText)
                                    Spacer()
                                }
                                .padding(12).ghCard()

                                GHPrimaryButton(label: "Award Badge") {
                                    vm.awardBadge(badgeId: selectedBadge!.id,
                                                  userId: selectedMember!.user.id,
                                                  officerName: authVM.currentUser.name)
                                    successMessage = "\"\(selectedBadge!.name)\" awarded to \(selectedMember!.user.name)"
                                    selectedBadge  = nil
                                    selectedMember = nil
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        successMessage = nil
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 16).padding(.bottom, 100)
                }
            }
        }
        .onAppear { rosterVM.loadRoster(chapter: authVM.currentUser.chapter) }
    }
}
