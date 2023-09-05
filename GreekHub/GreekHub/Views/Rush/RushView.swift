import SwiftUI

// MARK: - Rush Home

struct RushView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = RushViewModel()
    @State private var showAddPNM = false

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Rush & Recruitment")
                            .font(.ghTitle)
                            .foregroundColor(.ghText)
                        Text(vm.season.name)
                            .font(.ghCaption)
                            .foregroundColor(.ghGold)
                    }
                    Spacer()
                    Button { showAddPNM = true } label: {
                        Image(systemName: "person.badge.plus.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.ghGold)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 12)

                // Status summary strip
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        RushStatChip(label: "All", count: vm.pnms.count,
                                     isSelected: vm.selectedStatus == nil,
                                     color: .ghGold) { vm.selectedStatus = nil }

                        ForEach(PNMStatus.allCases, id: \.self) { status in
                            let count = vm.statusCounts[status] ?? 0
                            if count > 0 {
                                RushStatChip(
                                    label: status.rawValue,
                                    count: count,
                                    isSelected: vm.selectedStatus == status,
                                    color: Color(hex: status.color)
                                ) { vm.selectedStatus = vm.selectedStatus == status ? nil : status }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }

                // Search
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundColor(.ghTextMuted)
                    TextField("", text: $vm.searchText)
                        .placeholder(when: vm.searchText.isEmpty) {
                            Text("Search PNMs...").foregroundColor(.ghTextMuted)
                        }
                        .font(.ghBody).foregroundColor(.ghText)
                    if !vm.searchText.isEmpty {
                        Button { vm.searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14)).foregroundColor(.ghTextMuted)
                        }
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 9)
                .background(Color.ghSurface2)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(.horizontal, 16).padding(.bottom, 6)

                Divider().background(Color.ghBorder)

                // PNM list
                if vm.filtered.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "person.badge.plus.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.ghTextMuted)
                        Text("No PNMs found")
                            .font(.ghHeadline).foregroundColor(.ghTextMuted)
                        Text("Add candidates to begin tracking rush")
                            .font(.ghCaption).foregroundColor(.ghTextMuted)
                        Spacer()
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(vm.filtered) { pnm in
                                NavigationLink(destination: PNMDetailView(pnm: pnm, vm: vm)
                                    .environmentObject(authVM)) {
                                    PNMRow(pnm: pnm)
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
        .onAppear { vm.startListening(chapter: authVM.currentUser.chapter) }
        .onDisappear { vm.stopListening() }
        .sheet(isPresented: $showAddPNM) {
            AddPNMView(vm: vm, chapter: authVM.currentUser.chapter,
                       addedBy: authVM.currentUser.name)
        }
        .navigationTitle("")
        .navigationBarHidden(true)
    }
}

// MARK: - Rush Stat Chip

struct RushStatChip: View {
    let label: String
    let count: Int
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(label)
                    .font(.ghCaptionBold)
                    .foregroundColor(isSelected ? .black : color)
                Text("\(count)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isSelected ? .black.opacity(0.7) : color.opacity(0.8))
                    .padding(.horizontal, 5).padding(.vertical, 1)
                    .background(isSelected ? Color.black.opacity(0.15) : color.opacity(0.15))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(isSelected ? color : color.opacity(0.1))
            .clipShape(Capsule())
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - PNM Row

struct PNMRow: View {
    let pnm: PNM

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color(hex: pnm.avatarColor).opacity(0.2))
                    .frame(width: 48, height: 48)
                Circle().stroke(Color(hex: pnm.avatarColor).opacity(0.5), lineWidth: 1.5)
                    .frame(width: 48, height: 48)
                Text(pnm.initials)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: pnm.avatarColor))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(pnm.fullName)
                    .font(.ghHeadline).foregroundColor(.ghText)
                HStack(spacing: 6) {
                    Text(pnm.major)
                        .font(.ghCaption).foregroundColor(.ghTextMuted)
                    Text("·").font(.ghCaption).foregroundColor(.ghTextMuted)
                    Text(pnm.year)
                        .font(.ghCaption).foregroundColor(.ghTextMuted)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                // Status pill
                HStack(spacing: 4) {
                    Image(systemName: pnm.status.icon)
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: pnm.status.color))
                    Text(pnm.status.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: pnm.status.color))
                }
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Color(hex: pnm.status.color).opacity(0.12))
                .clipShape(Capsule())

                // Vote count or avg score
                if !pnm.votes.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9)).foregroundColor(.ghGold)
                        Text(String(format: "%.1f", pnm.averageScore))
                            .font(.system(size: 11, weight: .semibold)).foregroundColor(.ghGold)
                        Text("(\(pnm.votes.count))")
                            .font(.system(size: 10)).foregroundColor(.ghTextMuted)
                    }
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
}

// MARK: - PNM Detail

struct PNMDetailView: View {
    let pnm: PNM
    @ObservedObject var vm: RushViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showVoteSheet   = false
    @State private var showStatusSheet = false
    @State private var showNoteSheet   = false
    @State private var newNote         = ""

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Hero
                    VStack(spacing: 14) {
                        ZStack {
                            Circle().fill(Color(hex: pnm.avatarColor).opacity(0.2))
                                .frame(width: 80, height: 80)
                            Circle().stroke(Color(hex: pnm.avatarColor).opacity(0.5), lineWidth: 2)
                                .frame(width: 80, height: 80)
                            Text(pnm.initials)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color(hex: pnm.avatarColor))
                        }

                        VStack(spacing: 4) {
                            Text(pnm.fullName)
                                .font(.ghTitle).foregroundColor(.ghText)
                            HStack(spacing: 6) {
                                Image(systemName: pnm.status.icon)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: pnm.status.color))
                                Text(pnm.status.rawValue)
                                    .font(.ghCallout)
                                    .foregroundColor(Color(hex: pnm.status.color))
                            }
                        }

                        if !pnm.bio.isEmpty {
                            Text(pnm.bio)
                                .font(.ghCallout).foregroundColor(.ghTextMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }

                        // GPA + interests
                        if !pnm.interests.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(pnm.interests, id: \.self) { interest in
                                        Text(interest)
                                            .ghPill(color: .ghBlue)
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                    }
                    .padding(.top, 8)

                    // Info card
                    VStack(spacing: 0) {
                        PNMInfoRow(icon: "graduationcap.fill", label: "Major",    value: pnm.major)
                        Divider().background(Color.ghBorder)
                        PNMInfoRow(icon: "calendar",          label: "Year",     value: pnm.year)
                        Divider().background(Color.ghBorder)
                        PNMInfoRow(icon: "chart.bar.fill",    label: "GPA",      value: String(format: "%.2f", pnm.gpa))
                        Divider().background(Color.ghBorder)
                        PNMInfoRow(icon: "mappin.circle.fill", label: "Hometown", value: pnm.hometown)
                        Divider().background(Color.ghBorder)
                        PNMInfoRow(icon: "envelope.fill",     label: "Email",    value: pnm.email)
                        Divider().background(Color.ghBorder)
                        PNMInfoRow(icon: "phone.fill",        label: "Phone",    value: pnm.phone)
                    }
                    .ghCard()

                    // Vote summary
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Officer Votes")
                                .font(.ghHeadline).foregroundColor(.ghText)
                            Spacer()
                            if !pnm.votes.isEmpty {
                                Text(String(format: "Avg %.1f / 10", pnm.averageScore))
                                    .font(.ghCaptionBold).foregroundColor(.ghGold)
                            }
                        }

                        if pnm.votes.isEmpty {
                            Text("No votes yet. Be the first to vote.")
                                .font(.ghCaption).foregroundColor(.ghTextMuted)
                        } else {
                            // Breakdown bar
                            let breakdown = pnm.voteBreakdown
                            let total     = pnm.votes.count
                            HStack(spacing: 4) {
                                VoteBar(count: breakdown.yes,     total: total, color: .ghGreen,  label: "Yes")
                                VoteBar(count: breakdown.abstain, total: total, color: .ghGold,   label: "Abstain")
                                VoteBar(count: breakdown.no,      total: total, color: .ghRed,    label: "No")
                            }
                            .frame(height: 28)

                            // Individual votes
                            ForEach(pnm.votes) { vote in
                                VoteRow(vote: vote)
                            }
                        }

                        Button {
                            showVoteSheet = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill").font(.system(size: 14))
                                Text("Cast Your Vote")
                                    .font(.ghHeadline)
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity).frame(height: 46)
                            .background(Color.ghGold)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .padding(14).ghCard()

                    // Officer notes
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Notes")
                                .font(.ghHeadline).foregroundColor(.ghText)
                            Spacer()
                            Button {
                                showNoteSheet = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18)).foregroundColor(.ghGold)
                            }
                        }

                        if pnm.notes.isEmpty {
                            Text("No notes yet.")
                                .font(.ghCaption).foregroundColor(.ghTextMuted)
                        } else {
                            ForEach(pnm.notes) { note in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(note.authorName)
                                            .font(.ghCaptionBold).foregroundColor(.ghText)
                                        Spacer()
                                        Text(note.createdAt.relativeString)
                                            .font(.ghCaption).foregroundColor(.ghTextMuted)
                                    }
                                    Text(note.text)
                                        .font(.ghCallout).foregroundColor(.ghTextMuted)
                                }
                                .padding(10)
                                .background(Color.ghSurface2)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                    }
                    .padding(14).ghCard()

                    // Status actions
                    VStack(spacing: 10) {
                        if pnm.status == .interviewing || pnm.status == .pending {
                            Button {
                                vm.offerBid(pnmId: pnm.id)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "envelope.fill").font(.system(size: 14))
                                    Text("Offer Bid").font(.ghHeadline)
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity).frame(height: 50)
                                .background(Color.ghGreen)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }

                        if pnm.status == .bidOffered {
                            HStack(spacing: 10) {
                                Button {
                                    vm.updateStatus(pnmId: pnm.id, status: .accepted)
                                } label: {
                                    Text("Accept").font(.ghHeadline).foregroundColor(.black)
                                        .frame(maxWidth: .infinity).frame(height: 50)
                                        .background(Color.ghGreen)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                Button {
                                    vm.updateStatus(pnmId: pnm.id, status: .declined)
                                } label: {
                                    Text("Decline").font(.ghHeadline).foregroundColor(.ghRed)
                                        .frame(maxWidth: .infinity).frame(height: 50)
                                        .background(Color.ghRed.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(Color.ghRed.opacity(0.3), lineWidth: 0.5))
                                }
                            }
                        }

                        Button { showStatusSheet = true } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 13))
                                Text("Change Status")
                                    .font(.ghCallout)
                            }
                            .foregroundColor(.ghTextMuted)
                            .frame(maxWidth: .infinity).frame(height: 44)
                            .background(Color.ghSurface2)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle(pnm.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showVoteSheet) {
            VoteSheet(pnm: pnm, vm: vm, officerId: authVM.currentUser.id,
                      officerName: authVM.currentUser.name)
        }
        .sheet(isPresented: $showNoteSheet) {
            AddNoteSheet(pnmId: pnm.id, vm: vm, authorName: authVM.currentUser.name)
        }
        .confirmationDialog("Change Status", isPresented: $showStatusSheet, titleVisibility: .visible) {
            ForEach(PNMStatus.allCases, id: \.self) { status in
                Button(status.rawValue) { vm.updateStatus(pnmId: pnm.id, status: status) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Vote Bar

struct VoteBar: View {
    let count: Int
    let total: Int
    let color: Color
    let label: String

    var fraction: Double { total > 0 ? Double(count) / Double(total) : 0 }

    var body: some View {
        VStack(spacing: 3) {
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 4).fill(color.opacity(0.12))
                    RoundedRectangle(cornerRadius: 4).fill(color)
                        .frame(height: geo.size.height * fraction)
                }
            }
            Text("\(count)").font(.system(size: 11, weight: .bold)).foregroundColor(color)
            Text(label).font(.system(size: 9)).foregroundColor(.ghTextMuted)
        }
    }
}

// MARK: - Vote Row

struct VoteRow: View {
    let vote: OfficerVote
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: vote.recommendation.icon)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: vote.recommendation.color))
            VStack(alignment: .leading, spacing: 1) {
                Text(vote.officerName).font(.ghCaptionBold).foregroundColor(.ghText)
                if !vote.note.isEmpty {
                    Text(vote.note).font(.ghCaption).foregroundColor(.ghTextMuted).lineLimit(2)
                }
            }
            Spacer()
            Text("\(vote.score)/10")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.ghGold)
        }
        .padding(10)
        .background(Color.ghSurface2)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - PNM Info Row

struct PNMInfoRow: View {
    let icon: String; let label: String; let value: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(.ghGold).frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.ghCaption).foregroundColor(.ghTextMuted)
                Text(value).font(.ghCallout).foregroundColor(.ghText)
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 11)
    }
}

// MARK: - Vote Sheet

struct VoteSheet: View {
    let pnm: PNM
    @ObservedObject var vm: RushViewModel
    let officerId: String
    let officerName: String
    @Environment(\.dismiss) var dismiss

    @State private var score: Int = 7
    @State private var recommendation: VoteRecommendation = .yes
    @State private var note = ""

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                Capsule().fill(Color.ghBorder).frame(width: 40, height: 4).padding(.top, 12)
                HStack {
                    Button("Cancel") { dismiss() }.font(.ghCallout).foregroundColor(.ghTextMuted)
                    Spacer()
                    Text("Vote on \(pnm.firstName)").font(.ghHeadline).foregroundColor(.ghText)
                    Spacer()
                    Text("Cancel").font(.ghCallout).foregroundColor(.clear)
                }
                .padding(.horizontal, 20).padding(.vertical, 16)
                Divider().background(Color.ghBorder)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Score slider
                        VStack(spacing: 12) {
                            HStack {
                                Text("Score").font(.ghHeadline).foregroundColor(.ghText)
                                Spacer()
                                Text("\(score) / 10")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.ghGold)
                            }
                            Slider(value: Binding(
                                get: { Double(score) },
                                set: { score = Int($0) }
                            ), in: 1...10, step: 1)
                            .tint(.ghGold)
                            HStack {
                                Text("1").font(.ghCaption).foregroundColor(.ghTextMuted)
                                Spacer()
                                Text("10").font(.ghCaption).foregroundColor(.ghTextMuted)
                            }
                        }

                        // Recommendation
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recommendation").font(.ghHeadline).foregroundColor(.ghText)
                            HStack(spacing: 10) {
                                ForEach(VoteRecommendation.allCases, id: \.self) { rec in
                                    Button { recommendation = rec } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: rec.icon).font(.system(size: 14))
                                            Text(rec.rawValue).font(.ghHeadline)
                                        }
                                        .foregroundColor(recommendation == rec ? .black : Color(hex: rec.color))
                                        .frame(maxWidth: .infinity).frame(height: 46)
                                        .background(recommendation == rec ? Color(hex: rec.color) : Color(hex: rec.color).opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }
                                }
                            }
                        }

                        // Note
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note (optional)").font(.ghHeadline).foregroundColor(.ghText)
                            TextField("", text: $note, axis: .vertical)
                                .placeholder(when: note.isEmpty) {
                                    Text("Add reasoning...").foregroundColor(.ghTextMuted)
                                }
                                .font(.ghBody).foregroundColor(.ghText).lineLimit(1...4)
                                .padding(14)
                                .background(Color.ghSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.ghBorder, lineWidth: 0.5))
                        }

                        GHPrimaryButton(label: "Submit Vote") {
                            let vote = OfficerVote(
                                id: UUID().uuidString,
                                officerId: officerId,
                                officerName: officerName,
                                score: score,
                                recommendation: recommendation,
                                note: note,
                                votedAt: Date()
                            )
                            vm.submitVote(pnmId: pnm.id, vote: vote)
                            dismiss()
                        }
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20).padding(.top, 20)
                }
            }
        }
    }
}

// MARK: - Add Note Sheet

struct AddNoteSheet: View {
    let pnmId: String
    @ObservedObject var vm: RushViewModel
    let authorName: String
    @Environment(\.dismiss) var dismiss
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                Capsule().fill(Color.ghBorder).frame(width: 40, height: 4).padding(.top, 12)
                HStack {
                    Button("Cancel") { dismiss() }.font(.ghCallout).foregroundColor(.ghTextMuted)
                    Spacer()
                    Text("Add Note").font(.ghHeadline).foregroundColor(.ghText)
                    Spacer()
                    Button("Save") {
                        let note = PNMNote(id: UUID().uuidString, authorName: authorName,
                                          text: text, createdAt: Date())
                        vm.addNote(pnmId: pnmId, note: note)
                        dismiss()
                    }
                    .font(.ghCallout).foregroundColor(text.isEmpty ? .ghTextMuted : .ghGold)
                    .disabled(text.isEmpty)
                }
                .padding(.horizontal, 20).padding(.vertical, 16)
                Divider().background(Color.ghBorder)
                TextEditor(text: $text)
                    .focused($focused)
                    .font(.ghBody).foregroundColor(.ghText)
                    .scrollContentBackground(.hidden).background(.clear)
                    .padding(20)
                    .placeholder(when: text.isEmpty) {
                        Text("Write your observations about this candidate...")
                            .foregroundColor(.ghTextMuted).font(.ghBody).padding(24).allowsHitTesting(false)
                    }
                Spacer()
            }
        }
        .onAppear { focused = true }
    }
}

// MARK: - Add PNM View

struct AddPNMView: View {
    @ObservedObject var vm: RushViewModel
    let chapter: String
    let addedBy: String
    @Environment(\.dismiss) var dismiss

    @State private var firstName = ""
    @State private var lastName  = ""
    @State private var email     = ""
    @State private var phone     = ""
    @State private var major     = ""
    @State private var year      = "Freshman"
    @State private var gpa       = ""
    @State private var hometown  = ""
    @State private var bio       = ""

    private let years    = ["Freshman", "Sophomore", "Junior", "Senior"]
    private let colors   = ["#4C6BC9", "#4CC99A", "#C94C8A", "#8A4CC9", "#C9A84C", "#C94C4C"]

    var canSave: Bool { !firstName.isEmpty && !lastName.isEmpty }

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                Capsule().fill(Color.ghBorder).frame(width: 40, height: 4).padding(.top, 12)
                HStack {
                    Button("Cancel") { dismiss() }.font(.ghCallout).foregroundColor(.ghTextMuted)
                    Spacer()
                    Text("Add PNM").font(.ghHeadline).foregroundColor(.ghText)
                    Spacer()
                    Button("Add") {
                        let pnm = PNM(
                            id: UUID().uuidString,
                            firstName: firstName, lastName: lastName,
                            email: email, phone: phone, major: major,
                            year: year, gpa: Double(gpa) ?? 0,
                            hometown: hometown, bio: bio, interests: [],
                            avatarColor: colors.randomElement()!,
                            status: .pending, addedBy: addedBy,
                            addedAt: Date(), votes: [], photoURLs: [], notes: []
                        )
                        vm.addPNM(pnm, chapter: chapter)
                        dismiss()
                    }
                    .font(.ghCallout).foregroundColor(canSave ? .ghGold : .ghTextMuted)
                    .disabled(!canSave)
                }
                .padding(.horizontal, 20).padding(.vertical, 16)
                Divider().background(Color.ghBorder)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        SectionLabel("Identity")
                        HStack(spacing: 10) {
                            GHTextField(label: "First Name", placeholder: "Jordan",   text: $firstName)
                            GHTextField(label: "Last Name",  placeholder: "Davis",    text: $lastName)
                        }
                        GHTextField(label: "Email",    placeholder: "jdavis@edu",     text: $email)
                            .keyboardType(.emailAddress).autocapitalization(.none)
                        GHTextField(label: "Phone",    placeholder: "(757) 555-0000", text: $phone)
                            .keyboardType(.phonePad)

                        SectionLabel("Academic").padding(.top, 6)
                        GHTextField(label: "Major",    placeholder: "Political Science", text: $major)
                        GHTextField(label: "Hometown", placeholder: "Richmond, VA",      text: $hometown)
                        HStack(spacing: 10) {
                            GHTextField(label: "GPA",    placeholder: "3.7", text: $gpa)
                                .keyboardType(.decimalPad)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Year").font(.ghCaption).foregroundColor(.ghTextMuted)
                                Menu(year) {
                                    ForEach(years, id: \.self) { y in
                                        Button(y) { year = y }
                                    }
                                }
                                .font(.ghBody).foregroundColor(.ghText)
                                .padding()
                                .background(Color.ghSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.ghBorder, lineWidth: 0.5))
                            }
                        }

                        SectionLabel("Bio").padding(.top, 6)
                        GHTextField(label: "Bio / Notes", placeholder: "Student body VP, debate team...", text: $bio)
                    }
                    .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 40)
                }
            }
        }
    }
}
