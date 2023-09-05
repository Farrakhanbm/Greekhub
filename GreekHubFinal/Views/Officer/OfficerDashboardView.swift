import SwiftUI

// MARK: - Officer Dashboard

struct OfficerDashboardView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = OfficerDashboardViewModel()
    @State private var selectedTab: DashTab = .overview

    enum DashTab: String, CaseIterable {
        case overview  = "Overview"
        case attendance = "Attendance"
        case points    = "Points"
    }

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Officer Dashboard")
                            .font(.ghTitle)
                            .foregroundColor(.ghText)
                        Text(vm.analytics.semesterLabel)
                            .font(.ghCaption)
                            .foregroundColor(.ghTextMuted)
                    }
                    Spacer()
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.ghGold)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 14)

                // Tab selector
                HStack(spacing: 0) {
                    ForEach(DashTab.allCases, id: \.self) { tab in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
                        } label: {
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundColor(selectedTab == tab ? .ghGold : .ghTextMuted)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    selectedTab == tab
                                        ? Color.ghGold.opacity(0.1)
                                        : Color.clear
                                )
                                .overlay(
                                    Rectangle()
                                        .fill(selectedTab == tab ? Color.ghGold : Color.clear)
                                        .frame(height: 2),
                                    alignment: .bottom
                                )
                        }
                    }
                }
                .background(Color.ghSurface)
                .overlay(Rectangle().fill(Color.ghBorder).frame(height: 0.5), alignment: .bottom)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        switch selectedTab {
                        case .overview:   OverviewTab(analytics: vm.analytics)
                        case .attendance: AttendanceTab(analytics: vm.analytics)
                        case .points:     PointsTab(analytics: vm.analytics)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 100)
                }
            }

            if vm.isLoading {
                Color.ghBackground.opacity(0.6).ignoresSafeArea()
                ProgressView().tint(.ghGold)
            }
        }
        .onAppear { vm.load(chapter: authVM.currentUser.chapter) }
    }
}

// MARK: - Overview Tab

struct OverviewTab: View {
    let analytics: ChapterAnalytics

    var body: some View {
        VStack(spacing: 16) {
            // Stat cards grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                DashStatCard(value: "\(analytics.activeMembers)/\(analytics.totalMembers)",
                             label: "Active members",   icon: "person.3.fill",     color: .ghBlue)
                DashStatCard(value: "\(Int(analytics.averageAttendanceRate * 100))%",
                             label: "Avg attendance",   icon: "chart.bar.fill",    color: .ghGreen)
                DashStatCard(value: "\(analytics.eventsThisSemester)",
                             label: "Events this sem",  icon: "calendar",          color: .ghGold)
                DashStatCard(value: "\(analytics.totalServiceHours)h",
                             label: "Service hours",    icon: "heart.fill",        color: .ghPink)
            }

            // Top performers
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Top performers", icon: "trophy.fill", color: .ghGold)
                ForEach(analytics.topPerformers) { stat in
                    MemberStatRow(stat: stat, showBadge: true)
                }
            }
            .padding(14)
            .ghCard()

            // At-risk members
            if !analytics.atRiskMembers.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Needs attention", icon: "exclamationmark.triangle.fill", color: .ghRed)
                    Text("Members below 30 points or under 40% attendance")
                        .font(.ghCaption)
                        .foregroundColor(.ghTextMuted)
                    ForEach(analytics.atRiskMembers) { stat in
                        MemberStatRow(stat: stat, showBadge: false, accentColor: .ghRed)
                    }
                }
                .padding(14)
                .ghCard()
            }
        }
    }
}

// MARK: - Attendance Tab

struct AttendanceTab: View {
    let analytics: ChapterAnalytics

    var body: some View {
        VStack(spacing: 16) {
            // Turnout bar chart
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Event turnout", icon: "person.fill.checkmark", color: .ghBlue)

                ForEach(analytics.eventTurnout) { point in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(point.label)
                                .font(.ghCaption)
                                .foregroundColor(.ghText)
                            Spacer()
                            Text("\(point.attended)/\(point.total)")
                                .font(.ghCaptionBold)
                                .foregroundColor(point.rate >= 0.75 ? .ghGreen : point.rate >= 0.5 ? .ghGold : .ghRed)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.ghSurface2)
                                    .frame(height: 8)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(point.rate >= 0.75 ? Color.ghGreen : point.rate >= 0.5 ? Color.ghGold : Color.ghRed)
                                    .frame(width: geo.size.width * point.rate, height: 8)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: point.rate)
                            }
                        }
                        .frame(height: 8)
                    }
                }
            }
            .padding(14)
            .ghCard()

            // Attendance rate summary
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Semester summary", icon: "chart.pie.fill", color: .ghPurple)
                HStack(spacing: 0) {
                    SummaryCell(value: "\(Int(analytics.averageAttendanceRate * 100))%",
                                label: "Avg rate", color: .ghGreen)
                    Divider().background(Color.ghBorder).frame(height: 40)
                    SummaryCell(value: "\(analytics.eventsThisSemester)",
                                label: "Events", color: .ghGold)
                    Divider().background(Color.ghBorder).frame(height: 40)
                    SummaryCell(value: "\(analytics.activeMembers)",
                                label: "Active", color: .ghBlue)
                }
            }
            .padding(14)
            .ghCard()
        }
    }
}

// MARK: - Points Tab

struct PointsTab: View {
    let analytics: ChapterAnalytics

    var body: some View {
        VStack(spacing: 16) {
            // Distribution bars
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(title: "Points distribution", icon: "bolt.fill", color: .ghGold)

                let total = analytics.pointsDistribution.reduce(0) { $0 + $1.count }
                ForEach(analytics.pointsDistribution) { bucket in
                    let frac = total > 0 ? Double(bucket.count) / Double(total) : 0
                    HStack(spacing: 10) {
                        Text(bucket.label)
                            .font(.ghCaption)
                            .foregroundColor(.ghTextMuted)
                            .frame(width: 44, alignment: .trailing)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.ghSurface2)
                                    .frame(height: 20)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: bucket.color))
                                    .frame(width: max(geo.size.width * frac, 4), height: 20)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: frac)
                            }
                        }
                        .frame(height: 20)
                        Text("\(bucket.count)")
                            .font(.ghCaptionBold)
                            .foregroundColor(.ghTextMuted)
                            .frame(width: 20)
                    }
                }
            }
            .padding(14)
            .ghCard()

            // Top earners
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Top earners", icon: "trophy.fill", color: .ghGold)
                ForEach(Array(analytics.topPerformers.enumerated()), id: \.element.id) { i, stat in
                    HStack(spacing: 12) {
                        Text("#\(i + 1)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(i == 0 ? .ghGold : .ghTextMuted)
                            .frame(width: 24)
                        AvatarView(initials: stat.initials, colorHex: stat.color, size: 36)
                        Text(stat.name)
                            .font(.ghCallout)
                            .foregroundColor(.ghText)
                        Spacer()
                        HStack(spacing: 3) {
                            Image(systemName: "bolt.fill").font(.system(size: 10)).foregroundColor(.ghGold)
                            Text("\(stat.points)").font(.ghHeadline).foregroundColor(.ghGold)
                        }
                    }
                }
            }
            .padding(14)
            .ghCard()
        }
    }
}

// MARK: - Shared Dashboard Components

struct DashStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.ghText)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.ghCaption)
                .foregroundColor(.ghTextMuted)
        }
        .padding(14)
        .ghCard()
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            Text(title)
                .font(.ghHeadline)
                .foregroundColor(.ghText)
        }
    }
}

struct MemberStatRow: View {
    let stat: MemberStat
    var showBadge: Bool = true
    var accentColor: Color = .ghGold

    var body: some View {
        HStack(spacing: 10) {
            AvatarView(initials: stat.initials, colorHex: stat.color, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(stat.name).font(.ghCallout).foregroundColor(.ghText)
                Text("\(Int(stat.attendanceRate * 100))% attendance")
                    .font(.ghCaption).foregroundColor(.ghTextMuted)
            }
            Spacer()
            if showBadge {
                HStack(spacing: 3) {
                    Image(systemName: "bolt.fill").font(.system(size: 10)).foregroundColor(accentColor)
                    Text("\(stat.points)").font(.ghCaptionBold).foregroundColor(accentColor)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(accentColor.opacity(0.12))
                .clipShape(Capsule())
            } else {
                Text("\(stat.points) pts")
                    .font(.ghCaption)
                    .foregroundColor(accentColor)
            }
        }
    }
}

struct SummaryCell: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.ghHeadline).foregroundColor(color)
            Text(label).font(.ghCaption).foregroundColor(.ghTextMuted)
        }
        .frame(maxWidth: .infinity)
    }
}
