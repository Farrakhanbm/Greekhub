import SwiftUI

// MARK: - Officer Points Tool

struct OfficerPointsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = OfficerPointsViewModel()
    @State private var showAwardSheet = false

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Points Manager")
                            .font(.ghTitle)
                            .foregroundColor(.ghText)
                        Text("Award & adjust member points")
                            .font(.ghCaption)
                            .foregroundColor(.ghTextMuted)
                    }
                    Spacer()
                    Button {
                        showAwardSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "bolt.badge.plus.fill")
                                .font(.system(size: 14))
                            Text("Award")
                                .font(.ghCaptionBold)
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.ghGold)
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 14)

                Divider().background(Color.ghBorder)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Recent awards feed
                        if !vm.recentAwards.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("RECENT ACTIVITY")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.ghTextMuted)
                                    .kerning(0.8)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)

                                ForEach(vm.recentAwards) { event in
                                    PointsEventRow(event: event)
                                    Divider().background(Color.ghBorder).padding(.leading, 56)
                                }
                            }
                        }

                        // Member point standings
                        VStack(alignment: .leading, spacing: 0) {
                            Text("ALL MEMBERS")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.ghTextMuted)
                                .kerning(0.8)
                                .padding(.horizontal, 16)
                                .padding(.top, 20)
                                .padding(.bottom, 10)

                            ForEach(vm.members) { member in
                                OfficerMemberPointsRow(member: member) {
                                    // Quick +1 award
                                    vm.award = PointsAwardRequest(
                                        memberId: member.user.id,
                                        memberName: member.user.name,
                                        amount: 1,
                                        reason: .manualAward,
                                        note: ""
                                    )
                                    showAwardSheet = true
                                }
                                Divider().background(Color.ghBorder).padding(.leading, 68)
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            let chapter = authVM.currentUser.chapter
            vm.loadMembers(chapter: chapter)
            vm.loadRecentAwards(chapter: chapter)
        }
        .sheet(isPresented: $showAwardSheet) {
            AwardPointsSheet(vm: vm, officerName: authVM.currentUser.name)
        }
    }
}

// MARK: - Points Event Row

struct PointsEventRow: View {
    let event: PointsEvent

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: event.reason.color).opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: event.reason.icon)
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: event.reason.color))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(event.reason.rawValue)
                    .font(.ghCallout)
                    .foregroundColor(.ghText)
                if let title = event.eventTitle, !title.isEmpty {
                    Text(title)
                        .font(.ghCaption)
                        .foregroundColor(.ghTextMuted)
                        .lineLimit(1)
                } else {
                    Text("By \(event.awardedBy)")
                        .font(.ghCaption)
                        .foregroundColor(.ghTextMuted)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(event.isPositive ? "+\(event.amount)" : "\(event.amount)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(event.isPositive ? .ghGreen : .ghRed)
                Text(event.awardedAt.relativeString)
                    .font(.ghCaption)
                    .foregroundColor(.ghTextMuted)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Officer Member Row

struct OfficerMemberPointsRow: View {
    let member: RosterMember
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(initials: member.user.avatarInitials,
                       colorHex: member.user.avatarColor, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(member.user.name)
                    .font(.ghHeadline)
                    .foregroundColor(.ghText)
                Text(member.user.role.rawValue)
                    .font(.ghCaption)
                    .foregroundColor(member.user.role.isOfficer ? .ghGold : .ghTextMuted)
            }

            Spacer()

            HStack(spacing: 3) {
                Image(systemName: "bolt.fill").font(.system(size: 10)).foregroundColor(.ghGold)
                Text("\(member.user.points)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.ghGold)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.ghGold.opacity(0.1))
            .clipShape(Capsule())

            Button(action: onTap) {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.ghTextMuted)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Award Points Sheet

struct AwardPointsSheet: View {
    @ObservedObject var vm: OfficerPointsViewModel
    let officerName: String
    @Environment(\.dismiss) var dismiss
    @State private var isDeduction = false

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule().fill(Color.ghBorder).frame(width: 40, height: 4).padding(.top, 12)

                HStack {
                    Button("Cancel") { dismiss() }
                        .font(.ghCallout).foregroundColor(.ghTextMuted)
                    Spacer()
                    Text(vm.award.memberId.isEmpty ? "Award Points" : "Award to \(vm.award.memberName)")
                        .font(.ghHeadline).foregroundColor(.ghText)
                        .lineLimit(1)
                    Spacer()
                    Text("Cancel").font(.ghCallout).foregroundColor(.clear)
                }
                .padding(.horizontal, 20).padding(.vertical, 16)

                Divider().background(Color.ghBorder)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // Member picker (if not pre-selected)
                        if vm.award.memberId.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("SELECT MEMBER")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.ghTextMuted).kerning(0.8)
                                VStack(spacing: 0) {
                                    ForEach(vm.members) { member in
                                        Button {
                                            vm.award.memberId   = member.user.id
                                            vm.award.memberName = member.user.name
                                        } label: {
                                            HStack(spacing: 10) {
                                                AvatarView(initials: member.user.avatarInitials,
                                                           colorHex: member.user.avatarColor, size: 36)
                                                Text(member.user.name)
                                                    .font(.ghCallout).foregroundColor(.ghText)
                                                Spacer()
                                                if vm.award.memberId == member.user.id {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.ghGold)
                                                }
                                            }
                                            .padding(.horizontal, 14).padding(.vertical, 10)
                                        }
                                        if member.id != vm.members.last?.id {
                                            Divider().background(Color.ghBorder).padding(.leading, 58)
                                        }
                                    }
                                }
                                .ghCard()
                            }
                        }

                        // Award / Deduct toggle
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TYPE").font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.ghTextMuted).kerning(0.8)
                            HStack(spacing: 0) {
                                typeButton(label: "Award", isActive: !isDeduction, color: .ghGreen) {
                                    isDeduction  = false
                                    vm.award.amount = abs(vm.award.amount)
                                }
                                typeButton(label: "Deduct", isActive: isDeduction, color: .ghRed) {
                                    isDeduction  = true
                                    vm.award.amount = -abs(vm.award.amount)
                                }
                            }
                            .ghCard()
                        }

                        // Amount stepper
                        VStack(alignment: .leading, spacing: 8) {
                            Text("AMOUNT").font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.ghTextMuted).kerning(0.8)
                            HStack {
                                Button {
                                    let v = abs(vm.award.amount)
                                    vm.award.amount = isDeduction ? -(max(1, v - 1)) : max(1, v - 1)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.ghTextMuted)
                                }

                                Spacer()

                                VStack(spacing: 2) {
                                    Text("\(isDeduction ? "-" : "+")\(abs(vm.award.amount))")
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(isDeduction ? .ghRed : .ghGreen)
                                    Text("points")
                                        .font(.ghCaption)
                                        .foregroundColor(.ghTextMuted)
                                }

                                Spacer()

                                Button {
                                    let v = abs(vm.award.amount)
                                    vm.award.amount = isDeduction ? -(v + 1) : v + 1
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.ghGold)
                                }
                            }
                            .padding(16)
                            .ghCard()
                        }

                        // Reason picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("REASON").font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.ghTextMuted).kerning(0.8)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(PointsReason.allCases, id: \.self) { reason in
                                    Button {
                                        vm.award.reason = reason
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: reason.icon)
                                                .font(.system(size: 12))
                                                .foregroundColor(Color(hex: reason.color))
                                            Text(reason.rawValue)
                                                .font(.ghCaption)
                                                .foregroundColor(.ghText)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.8)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 10).padding(.vertical, 10)
                                        .background(vm.award.reason == reason
                                                    ? Color(hex: reason.color).opacity(0.12)
                                                    : Color.ghSurface2)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(vm.award.reason == reason
                                                        ? Color(hex: reason.color).opacity(0.4)
                                                        : Color.clear, lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }

                        // Optional note
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NOTE (OPTIONAL)").font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.ghTextMuted).kerning(0.8)
                            TextField("", text: $vm.award.note, axis: .vertical)
                                .placeholder(when: vm.award.note.isEmpty) {
                                    Text("Add a note...").foregroundColor(.ghTextMuted)
                                }
                                .font(.ghBody).foregroundColor(.ghText)
                                .lineLimit(1...3)
                                .padding(14)
                                .background(Color.ghSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.ghBorder, lineWidth: 0.5))
                        }

                        // Success / error
                        if let msg = vm.successMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.ghGreen)
                                Text(msg).font(.ghCallout).foregroundColor(.ghGreen)
                            }
                            .padding(12).ghCard()
                        }
                        if let err = vm.errorMessage {
                            Text(err).font(.ghCaption).foregroundColor(.ghRed)
                        }

                        // Submit
                        Button {
                            vm.submitAward(officerName: officerName)
                        } label: {
                            ZStack {
                                if vm.isSubmitting { ProgressView().tint(.black) }
                                else {
                                    Text("Confirm \(isDeduction ? "Deduction" : "Award")")
                                        .font(.ghHeadline)
                                        .foregroundColor(vm.award.memberId.isEmpty ? .ghTextMuted : .black)
                                }
                            }
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(vm.award.memberId.isEmpty ? Color.ghSurface2 : Color.ghGold)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .disabled(vm.award.memberId.isEmpty || vm.isSubmitting)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20).padding(.top, 20)
                }
            }
        }
        .onChange(of: vm.successMessage) { msg in
            if msg != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
            }
        }
    }

    private func typeButton(label: String, isActive: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: isActive ? .semibold : .regular))
                .foregroundColor(isActive ? color : .ghTextMuted)
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(isActive ? color.opacity(0.1) : Color.clear)
        }
    }
}

// MARK: - placeholder helper redeclaration guard
// placeholder() is declared in LoginView.swift — no redeclaration needed
