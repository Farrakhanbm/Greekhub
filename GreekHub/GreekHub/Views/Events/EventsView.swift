import SwiftUI

struct EventsView: View {
    @EnvironmentObject var eventsVM: EventsViewModel

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Events")
                        .font(.ghTitle)
                        .foregroundColor(.ghText)
                    Spacer()
                    Button {} label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.ghGold)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 12)

                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", isSelected: eventsVM.selectedFilter == nil) {
                            eventsVM.selectedFilter = nil
                        }
                        ForEach(EventType.allCases, id: \.self) { type in
                            FilterChip(label: type.rawValue, isSelected: eventsVM.selectedFilter == type, color: Color(hex: type.color)) {
                                eventsVM.selectedFilter = eventsVM.selectedFilter == type ? nil : type
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }

                Divider().background(Color.ghBorder)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(eventsVM.filtered) { event in
                            NavigationLink(destination: EventDetailView(event: event, eventsVM: eventsVM)) {
                                EventCard(event: event) {
                                    eventsVM.toggleRSVP(eventID: event.id)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 90)
                }
            }
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var color: Color = .ghGold
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.ghCaptionBold)
                .foregroundColor(isSelected ? .black : color)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? color : color.opacity(0.1))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(color.opacity(isSelected ? 0 : 0.3), lineWidth: 0.5))
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Event Card

struct EventCard: View {
    let event: ChapterEvent
    let onRSVP: () -> Void

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d · h:mm a"
        return formatter.string(from: event.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Type bar
            HStack(spacing: 6) {
                Image(systemName: event.type.icon)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: event.type.color))
                Text(event.type.rawValue.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .default))
                    .foregroundColor(Color(hex: event.type.color))
                    .kerning(0.5)
                Spacer()
                if event.pointValue > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.ghGold)
                        Text("+\(event.pointValue) pts")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.ghGold)
                    }
                }
            }

            Text(event.title)
                .font(.ghTitle2)
                .foregroundColor(.ghText)
                .lineLimit(2)

            VStack(alignment: .leading, spacing: 6) {
                Label(dateLabel, systemImage: "calendar")
                    .font(.ghCaption)
                    .foregroundColor(.ghTextMuted)
                Label(event.location, systemImage: "mappin.circle")
                    .font(.ghCaption)
                    .foregroundColor(.ghTextMuted)
                    .lineLimit(1)
            }

            HStack {
                // Attendee count
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.ghTextMuted)
                    Text("\(event.rsvpCount) going")
                        .font(.ghCaption)
                        .foregroundColor(.ghTextMuted)
                    if let cap = event.capacity {
                        Text("/ \(cap)")
                            .font(.ghCaption)
                            .foregroundColor(.ghTextMuted.opacity(0.6))
                    }
                }

                Spacer()

                Button(action: onRSVP) {
                    Text(event.isRSVPed ? "Going ✓" : "RSVP")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(event.isRSVPed ? .black : .ghGold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(event.isRSVPed ? Color.ghGold : Color.ghGold.opacity(0.12))
                        .clipShape(Capsule())
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: event.isRSVPed)
            }
        }
        .padding(16)
        .ghCard()
    }
}

// MARK: - Event Detail

struct EventDetailView: View {
    let event: ChapterEvent
    @ObservedObject var eventsVM: EventsViewModel
    @Environment(\.dismiss) var dismiss

    private var dateLabel: String {
        let f = DateFormatter(); f.dateFormat = "EEEE, MMMM d, yyyy"
        return f.string(from: event.date)
    }
    private var timeLabel: String {
        let f = DateFormatter(); f.dateFormat = "h:mm a"
        return "\(f.string(from: event.date)) – \(f.string(from: event.endDate))"
    }

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Type pill
                    HStack(spacing: 6) {
                        Image(systemName: event.type.icon)
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: event.type.color))
                        Text(event.type.rawValue)
                            .ghPill(color: Color(hex: event.type.color))
                        if event.pointValue > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "bolt.fill").font(.system(size: 11)).foregroundColor(.ghGold)
                                Text("+\(event.pointValue) pts").font(.ghCaptionBold).foregroundColor(.ghGold)
                            }
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Color.ghGold.opacity(0.12)).clipShape(Capsule())
                        }
                    }

                    Text(event.title)
                        .font(.ghLargeTitle)
                        .foregroundColor(.ghText)

                    VStack(spacing: 14) {
                        DetailRow(icon: "calendar", label: dateLabel)
                        DetailRow(icon: "clock", label: timeLabel)
                        DetailRow(icon: "mappin.circle.fill", label: event.location)
                        DetailRow(icon: "person.circle.fill", label: "Organized by \(event.organizerName)")
                        DetailRow(icon: "person.3.fill", label: "\(event.rsvpCount) attending\(event.capacity != nil ? " / \(event.capacity!) capacity" : "")")
                        if event.requiresCheckIn {
                            DetailRow(icon: "qrcode.viewfinder", label: "QR check-in required")
                        }
                    }
                    .padding(16)
                    .ghCard()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("About this event")
                            .font(.ghHeadline)
                            .foregroundColor(.ghText)
                        Text(event.description)
                            .font(.ghBody)
                            .foregroundColor(.ghTextMuted)
                            .lineSpacing(4)
                    }

                    // RSVP Button
                    Button {
                        eventsVM.toggleRSVP(eventID: event.id)
                    } label: {
                        Text(event.isRSVPed ? "Cancel RSVP" : "RSVP for this event")
                            .font(.ghHeadline)
                            .foregroundColor(event.isRSVPed ? .ghRed : .black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(event.isRSVPed ? Color.ghRed.opacity(0.12) : Color.ghGold)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(event.isRSVPed ? Color.ghRed.opacity(0.4) : .clear, lineWidth: 0.5)
                            )
                    }
                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: event.isRSVPed)
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(false)
    }
}

struct DetailRow: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(.ghGold)
                .frame(width: 20)
            Text(label)
                .font(.ghCallout)
                .foregroundColor(.ghText)
            Spacer()
        }
    }
}
