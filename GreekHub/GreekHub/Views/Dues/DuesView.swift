import SwiftUI

// MARK: - Dues Dashboard

struct DuesView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = DuesViewModel()
    @State private var showRecordPayment: DuesRecord? = nil
    @State private var showCreateDues = false
    @State private var showSemesterPicker = false

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dues & Payments")
                            .font(.ghTitle).foregroundColor(.ghText)
                        Button {
                            showSemesterPicker = true
                        } label: {
                            HStack(spacing: 4) {
                                Text(vm.selectedSemester)
                                    .font(.ghCaption).foregroundColor(.ghGold)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 9)).foregroundColor(.ghGold)
                            }
                        }
                    }
                    Spacer()
                    Button { showCreateDues = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22)).foregroundColor(.ghGold)
                    }
                }
                .padding(.horizontal, 20).padding(.top, 60).padding(.bottom, 14)

                // Summary strip
                DuesSummaryStrip(summary: vm.summary)
                    .padding(.horizontal, 16).padding(.bottom, 10)

                Divider().background(Color.ghBorder)

                // Success message
                if let msg = vm.successMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.ghGreen)
                        Text(msg).font(.ghCallout).foregroundColor(.ghGreen)
                        Spacer()
                        Button { vm.successMessage = nil } label: {
                            Image(systemName: "xmark").font(.system(size: 12)).foregroundColor(.ghTextMuted)
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Color.ghGreen.opacity(0.08))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Member dues list
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(vm.records) { record in
                            DuesRow(record: record) {
                                showRecordPayment = record
                            }
                            Divider().background(Color.ghBorder).padding(.leading, 68)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear { vm.load(chapter: authVM.currentUser.chapter) }
        .sheet(item: $showRecordPayment) { record in
            RecordPaymentSheet(record: record, vm: vm,
                               officerName: authVM.currentUser.name)
        }
        .sheet(isPresented: $showCreateDues) {
            CreateDuesSheet(vm: vm, chapter: authVM.currentUser.chapter)
        }
        .confirmationDialog("Select Semester", isPresented: $showSemesterPicker) {
            ForEach(vm.semesters, id: \.self) { sem in
                Button(sem) {
                    vm.selectedSemester = sem
                    vm.load(chapter: authVM.currentUser.chapter)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .animation(.easeInOut(duration: 0.2), value: vm.successMessage)
    }
}

// MARK: - Summary Strip

struct DuesSummaryStrip: View {
    let summary: DuesSummary

    var body: some View {
        VStack(spacing: 12) {
            // Collection progress bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Collection progress")
                        .font(.ghCaption).foregroundColor(.ghTextMuted)
                    Spacer()
                    Text("$\(Int(summary.totalCollected)) / $\(Int(summary.totalExpected))")
                        .font(.ghCaptionBold).foregroundColor(.ghText)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.ghSurface2).frame(height: 10)
                        RoundedRectangle(cornerRadius: 4).fill(Color.ghGreen)
                            .frame(width: geo.size.width * summary.collectionRate, height: 10)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: summary.collectionRate)
                    }
                }
                .frame(height: 10)
            }

            // Stat pills
            HStack(spacing: 8) {
                DuesStatPill(value: "\(summary.paidCount)",    label: "Paid",    color: .ghGreen)
                DuesStatPill(value: "\(summary.unpaidCount)",  label: "Unpaid",  color: .ghTextMuted)
                DuesStatPill(value: "\(summary.overdueCount)", label: "Overdue", color: .ghRed)
                Spacer()
                Text("\(Int(summary.collectionRate * 100))% collected")
                    .font(.ghCaptionBold)
                    .foregroundColor(summary.collectionRate >= 0.8 ? .ghGreen : .ghGold)
            }
        }
        .padding(14).ghCard()
    }
}

struct DuesStatPill: View {
    let value: String; let label: String; let color: Color
    var body: some View {
        HStack(spacing: 4) {
            Text(value).font(.system(size: 13, weight: .bold)).foregroundColor(color)
            Text(label).font(.ghCaption).foregroundColor(.ghTextMuted)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(color.opacity(0.08))
        .clipShape(Capsule())
    }
}

// MARK: - Dues Row

struct DuesRow: View {
    let record: DuesRecord
    let onRecordPayment: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(initials: record.userInitials, colorHex: record.userColor, size: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(record.userName)
                    .font(.ghHeadline).foregroundColor(.ghText)

                // Mini progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2).fill(Color.ghSurface2).frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: record.status.color))
                            .frame(width: geo.size.width * record.percentPaid, height: 4)
                    }
                }
                .frame(height: 4)

                HStack(spacing: 4) {
                    Text("$\(Int(record.amountPaid)) / $\(Int(record.amount))")
                        .font(.ghCaption).foregroundColor(.ghTextMuted)
                    if record.status == .overdue {
                        Text("· OVERDUE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.ghRed)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: record.status.icon)
                        .font(.system(size: 10)).foregroundColor(Color(hex: record.status.color))
                    Text(record.status.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color(hex: record.status.color))
                }
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Color(hex: record.status.color).opacity(0.12))
                .clipShape(Capsule())

                if record.status != .paid && record.status != .waived {
                    Button(action: onRecordPayment) {
                        Text("Record")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.ghGold)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Color.ghGold.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }
}

// MARK: - Record Payment Sheet

struct RecordPaymentSheet: View {
    let record: DuesRecord
    @ObservedObject var vm: DuesViewModel
    let officerName: String
    @Environment(\.dismiss) var dismiss

    @State private var amount:    String = ""
    @State private var method:    PaymentMethod = .cash
    @State private var note:      String = ""
    @State private var showWaive  = false

    var remaining: Double { record.balance }

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                Capsule().fill(Color.ghBorder).frame(width: 40, height: 4).padding(.top, 12)
                HStack {
                    Button("Cancel") { dismiss() }.font(.ghCallout).foregroundColor(.ghTextMuted)
                    Spacer()
                    Text("Record Payment").font(.ghHeadline).foregroundColor(.ghText)
                    Spacer()
                    Text("Cancel").font(.ghCallout).foregroundColor(.clear)
                }
                .padding(.horizontal, 20).padding(.vertical, 16)
                Divider().background(Color.ghBorder)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Member card
                        HStack(spacing: 12) {
                            AvatarView(initials: record.userInitials,
                                       colorHex: record.userColor, size: 48)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(record.userName)
                                    .font(.ghHeadline).foregroundColor(.ghText)
                                Text("Balance: $\(String(format: "%.2f", remaining)) remaining")
                                    .font(.ghCaption).foregroundColor(record.status == .overdue ? .ghRed : .ghTextMuted)
                            }
                        }
                        .padding(14).ghCard()

                        // Quick fill buttons
                        VStack(alignment: .leading, spacing: 8) {
                            Text("AMOUNT").font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.ghTextMuted).kerning(0.8)
                            HStack(spacing: 8) {
                                ForEach([remaining, remaining / 2, 50.0, 25.0], id: \.self) { amt in
                                    Button {
                                        amount = String(format: "%.0f", amt)
                                    } label: {
                                        Text("$\(Int(amt))")
                                            .font(.ghCaptionBold)
                                            .foregroundColor(amount == String(format: "%.0f", amt) ? .black : .ghGold)
                                            .padding(.horizontal, 12).padding(.vertical, 7)
                                            .background(amount == String(format: "%.0f", amt) ? Color.ghGold : Color.ghGold.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            TextField("", text: $amount)
                                .placeholder(when: amount.isEmpty) {
                                    Text("Custom amount").foregroundColor(.ghTextMuted)
                                }
                                .keyboardType(.decimalPad)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.ghText)
                                .multilineTextAlignment(.center)
                                .padding(16)
                                .background(Color.ghSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.ghBorder, lineWidth: 0.5))
                        }

                        // Payment method
                        VStack(alignment: .leading, spacing: 8) {
                            Text("METHOD").font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.ghTextMuted).kerning(0.8)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()),
                                                GridItem(.flexible())], spacing: 8) {
                                ForEach(PaymentMethod.allCases.filter { $0 != .waived }, id: \.self) { m in
                                    Button { method = m } label: {
                                        VStack(spacing: 4) {
                                            Image(systemName: m.icon)
                                                .font(.system(size: 16))
                                                .foregroundColor(method == m ? .black : .ghGold)
                                            Text(m.rawValue)
                                                .font(.ghCaption)
                                                .foregroundColor(method == m ? .black : .ghText)
                                        }
                                        .frame(maxWidth: .infinity).padding(.vertical, 12)
                                        .background(method == m ? Color.ghGold : Color.ghSurface2)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                }
                            }
                        }

                        GHTextField(label: "Note (optional)", placeholder: "Add a note...", text: $note)

                        VStack(spacing: 10) {
                            GHPrimaryButton(label: "Confirm Payment") {
                                if let amt = Double(amount), amt > 0 {
                                    vm.recordPayment(duesId: record.id, amount: amt,
                                                     method: method, confirmedBy: officerName, note: note)
                                    dismiss()
                                }
                            }

                            Button { showWaive = true } label: {
                                Text("Waive Dues")
                                    .font(.ghCallout).foregroundColor(.ghTextMuted)
                                    .frame(maxWidth: .infinity).frame(height: 46)
                                    .background(Color.ghSurface2)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20).padding(.top, 20)
                }
            }
        }
        .confirmationDialog("Waive dues for \(record.userName)?",
                            isPresented: $showWaive, titleVisibility: .visible) {
            Button("Waive Dues", role: .destructive) {
                vm.waivedDues(duesId: record.id, note: "Waived by \(officerName)")
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Create Semester Dues Sheet

struct CreateDuesSheet: View {
    @ObservedObject var vm: DuesViewModel
    let chapter: String
    @Environment(\.dismiss) var dismiss
    @StateObject private var rosterVM = RosterViewModel()

    @State private var amount:   String = "250"
    @State private var semester: String = "Spring 2025"
    @State private var dueDate  = Date().addingTimeInterval(86400 * 30)

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                Capsule().fill(Color.ghBorder).frame(width: 40, height: 4).padding(.top, 12)
                HStack {
                    Button("Cancel") { dismiss() }.font(.ghCallout).foregroundColor(.ghTextMuted)
                    Spacer()
                    Text("Create Dues").font(.ghHeadline).foregroundColor(.ghText)
                    Spacer()
                    Button("Create") {
                        if let amt = Double(amount) {
                            vm.createSemesterDues(chapter: chapter, amount: amt,
                                                  dueDate: dueDate, semester: semester,
                                                  members: rosterVM.members)
                            dismiss()
                        }
                    }
                    .font(.ghCallout)
                    .foregroundColor(amount.isEmpty ? .ghTextMuted : .ghGold)
                    .disabled(amount.isEmpty)
                }
                .padding(.horizontal, 20).padding(.vertical, 16)
                Divider().background(Color.ghBorder)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        SectionLabel("Semester")
                        GHTextField(label: "Semester", placeholder: "Spring 2025", text: $semester)
                        GHTextField(label: "Standard Amount ($)",
                                    placeholder: "250", text: $amount)
                            .keyboardType(.numberPad)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Due Date").font(.ghCaption).foregroundColor(.ghTextMuted)
                            DatePicker("", selection: $dueDate, displayedComponents: .date)
                                .datePickerStyle(.compact).colorScheme(.dark)
                                .padding(12).background(Color.ghSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "info.circle").font(.system(size: 12)).foregroundColor(.ghGold)
                            Text("Pledges automatically receive 60% of the standard rate.")
                                .font(.ghCaption).foregroundColor(.ghTextMuted)
                        }
                        .padding(12).background(Color.ghGold.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                        Text("This will create dues records for all \(rosterVM.members.count) active members.")
                            .font(.ghCaption).foregroundColor(.ghTextMuted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 40)
                }
            }
        }
        .onAppear { rosterVM.loadRoster(chapter: chapter) }
    }
}
