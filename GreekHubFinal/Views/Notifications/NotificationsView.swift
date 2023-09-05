import SwiftUI
import UserNotifications

// MARK: - Notifications View

struct NotificationsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = NotificationsViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.ghTextMuted)
                    }
                    Spacer()
                    Text("Notifications")
                        .font(.ghHeadline).foregroundColor(.ghText)
                    Spacer()
                    Button("Mark all read") { vm.markAllRead() }
                        .font(.ghCaption).foregroundColor(.ghGold)
                        .opacity(vm.unreadCount > 0 ? 1 : 0)
                }
                .padding(.horizontal, 20).padding(.vertical, 16)

                Divider().background(Color.ghBorder)

                // Permission banner
                if !vm.permissionGranted {
                    NotifPermissionBanner {
                        vm.requestPermission(userId: authVM.currentUser.id)
                    }
                }

                if vm.notifications.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 40)).foregroundColor(.ghTextMuted)
                        Text("No notifications").font(.ghHeadline).foregroundColor(.ghTextMuted)
                        Spacer()
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(vm.notifications) { notif in
                                NotificationRow(notif: notif) {
                                    vm.markRead(id: notif.id)
                                }
                                Divider().background(Color.ghBorder).padding(.leading, 56)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .onAppear {
            vm.loadNotifications(userId: authVM.currentUser.id)
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    vm.permissionGranted = settings.authorizationStatus == .authorized
                }
            }
        }
    }
}

// MARK: - Notification Row

struct NotificationRow: View {
    let notif: GHNotification
    let onRead: () -> Void

    var body: some View {
        Button(action: onRead) {
            HStack(alignment: .top, spacing: 12) {
                // Unread dot
                Circle()
                    .fill(notif.isRead ? Color.clear : Color.ghGold)
                    .frame(width: 7, height: 7)
                    .padding(.top, 6)

                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: notif.type.color).opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: notif.type.icon)
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: notif.type.color))
                }

                // Content
                VStack(alignment: .leading, spacing: 3) {
                    Text(notif.title)
                        .font(notif.isRead ? .ghCallout : .ghHeadline)
                        .foregroundColor(notif.isRead ? .ghTextMuted : .ghText)
                        .lineLimit(2)
                    Text(notif.body)
                        .font(.ghCaption)
                        .foregroundColor(.ghTextMuted)
                        .lineLimit(2)
                    Text(notif.sentAt.relativeString)
                        .font(.ghCaption)
                        .foregroundColor(.ghTextMuted.opacity(0.7))
                }

                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(notif.isRead ? Color.clear : Color.ghGold.opacity(0.04))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Permission Banner

struct NotifPermissionBanner: View {
    let onEnable: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 18))
                .foregroundColor(.ghGold)
            VStack(alignment: .leading, spacing: 2) {
                Text("Enable notifications")
                    .font(.ghCallout).foregroundColor(.ghText)
                Text("Get event reminders, point awards, and chapter updates")
                    .font(.ghCaption).foregroundColor(.ghTextMuted)
            }
            Spacer()
            Button("Enable", action: onEnable)
                .font(.ghCaptionBold).foregroundColor(.black)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color.ghGold)
                .clipShape(Capsule())
        }
        .padding(14)
        .background(Color.ghGold.opacity(0.06))
        .overlay(Rectangle().fill(Color.ghBorder).frame(height: 0.5), alignment: .bottom)
    }
}

// MARK: - Notification Bell Button (for nav bars)

struct NotificationBellButton: View {
    @EnvironmentObject var notifVM: NotificationsViewModel
    @State private var showNotifs = false

    var body: some View {
        Button { showNotifs = true } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.ghTextMuted)

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
        .sheet(isPresented: $showNotifs) {
            // NotificationsView needs authVM — caller must inject it
            EmptyView()
        }
    }
}
