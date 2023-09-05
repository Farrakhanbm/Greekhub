import SwiftUI

// MARK: - Channel List

struct ChatListView: View {
    @EnvironmentObject var chatVM: ChatViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @State private var selectedChannel: ChatChannel?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ghBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Text("Chat")
                            .font(.ghTitle)
                            .foregroundColor(.ghText)
                        Spacer()
                        Button {} label: {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.ghGold)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .padding(.bottom, 12)

                    Divider().background(Color.ghBorder)

                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(chatVM.channels) { channel in
                                NavigationLink(destination: ChatRoomView(channel: channel)
                                    .environmentObject(chatVM)
                                    .environmentObject(authVM)
                                ) {
                                    ChannelRow(channel: channel)
                                }
                                .buttonStyle(.plain)
                                .simultaneousGesture(TapGesture().onEnded {
                                    chatVM.selectChannel(channel)
                                })
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

// MARK: - Channel Row

struct ChannelRow: View {
    let channel: ChatChannel

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.ghSurface2)
                    .frame(width: 48, height: 48)
                Image(systemName: channel.icon)
                    .font(.system(size: 18))
                    .foregroundColor(.ghGold)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("#\(channel.name)")
                        .font(.ghHeadline)
                        .foregroundColor(.ghText)
                    if channel.isOfficerOnly {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.ghTextMuted)
                    }
                    Spacer()
                    Text(channel.lastMessageTime.relativeString)
                        .font(.ghCaption)
                        .foregroundColor(.ghTextMuted)
                }

                Text(channel.lastMessage)
                    .font(.ghCallout)
                    .foregroundColor(.ghTextMuted)
                    .lineLimit(1)
            }

            if channel.unreadCount > 0 {
                Text("\(channel.unreadCount)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
                    .frame(minWidth: 20, minHeight: 20)
                    .background(Color.ghGold)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Chat Room

struct ChatRoomView: View {
    let channel: ChatChannel
    @EnvironmentObject var chatVM: ChatViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @FocusState private var inputFocused: Bool
    @State private var scrollProxy: ScrollViewProxy?

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 4) {
                            ForEach(chatVM.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .padding(.bottom, 8)
                    }
                    .onAppear {
                        if let last = chatVM.messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                    .onChange(of: chatVM.messages.count) { _ in
                        if let last = chatVM.messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                // Input bar
                HStack(spacing: 10) {
                    TextField("Message #\(channel.name)", text: $chatVM.newMessage, axis: .vertical)
                        .focused($inputFocused)
                        .font(.ghBody)
                        .foregroundColor(.ghText)
                        .lineLimit(1...4)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.ghSurface2)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    Button {
                        chatVM.sendMessage(author: authVM.currentUser)
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(chatVM.newMessage.isEmpty ? .ghTextMuted : .ghGold)
                    }
                    .disabled(chatVM.newMessage.isEmpty)
                    .animation(.easeInOut(duration: 0.15), value: chatVM.newMessage.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.ghSurface.overlay(Rectangle().fill(Color.ghBorder).frame(height: 0.5), alignment: .top))
            }
        }
        .navigationTitle("#\(channel.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isFromCurrentUser {
                Spacer(minLength: 60)
            } else {
                AvatarView(initials: message.author.avatarInitials, colorHex: message.author.avatarColor, size: 30)
            }

            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 3) {
                if !message.isFromCurrentUser {
                    Text(message.author.name)
                        .font(.ghCaption)
                        .foregroundColor(.ghTextMuted)
                        .padding(.leading, 4)
                }

                Text(message.text)
                    .font(.ghBody)
                    .foregroundColor(message.isFromCurrentUser ? .black : .ghText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(message.isFromCurrentUser ? Color.ghGold : Color.ghSurface2)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Text(message.sentAt.relativeString)
                    .font(.system(size: 10))
                    .foregroundColor(.ghTextMuted)
                    .padding(.horizontal, 4)
            }

            if !message.isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
        .padding(.vertical, 2)
    }
}
