import SwiftUI

struct FeedView: View {
    @EnvironmentObject var feedVM: FeedViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showCompose = false

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation bar
                HStack {
                    Text("Feed")
                        .font(.ghTitle)
                        .foregroundColor(.ghText)

                    Spacer()

                    Button {
                        showCompose = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.ghGold)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 12)

                Divider().background(Color.ghBorder)

                // Feed
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(feedVM.posts) { post in
                            PostCard(post: post) {
                                feedVM.toggleLike(postID: post.id)
                            }
                            Divider().background(Color.ghBorder)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showCompose) {
            ComposePostView(feedVM: feedVM, author: authVM.currentUser)
        }
    }
}

// MARK: - Post Card

struct PostCard: View {
    let post: Post
    let onLike: () -> Void
    @State private var showComments = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .top, spacing: 10) {
                AvatarView(initials: post.author.avatarInitials, colorHex: post.author.avatarColor, size: 42)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(post.author.name)
                            .font(.ghHeadline)
                            .foregroundColor(.ghText)

                        if post.author.role.isOfficer {
                            Image(systemName: post.author.role.icon)
                                .font(.system(size: 11))
                                .foregroundColor(.ghGold)
                        }
                    }

                    HStack(spacing: 4) {
                        Text(post.author.role.rawValue)
                            .font(.ghCaption)
                            .foregroundColor(.ghTextMuted)
                        Text("·")
                            .font(.ghCaption)
                            .foregroundColor(.ghTextMuted)
                        Text(post.postedAt.relativeString)
                            .font(.ghCaption)
                            .foregroundColor(.ghTextMuted)
                    }
                }

                Spacer()

                if let tag = post.tag {
                    Text(tag.rawValue)
                        .ghPill(color: Color(hex: tag.color))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            // Content
            Text(post.content)
                .font(.ghBody)
                .foregroundColor(.ghText)
                .lineSpacing(4)
                .padding(.horizontal, 16)
                .padding(.bottom, 14)

            // Actions
            HStack(spacing: 24) {
                Button(action: onLike) {
                    HStack(spacing: 5) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 17))
                            .foregroundColor(post.isLiked ? .ghRed : .ghTextMuted)
                            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: post.isLiked)
                        Text("\(post.likes)")
                            .font(.ghCallout)
                            .foregroundColor(.ghTextMuted)
                    }
                }

                Button {
                    showComments.toggle()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 17))
                            .foregroundColor(.ghTextMuted)
                        Text("\(post.comments.count)")
                            .font(.ghCallout)
                            .foregroundColor(.ghTextMuted)
                    }
                }

                Spacer()

                Button {} label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17))
                        .foregroundColor(.ghTextMuted)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)

            // Comments preview
            if showComments && !post.comments.isEmpty {
                VStack(spacing: 10) {
                    ForEach(post.comments) { comment in
                        CommentRow(comment: comment)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
    }
}

// MARK: - Comment Row

struct CommentRow: View {
    let comment: Comment

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            AvatarView(initials: comment.author.avatarInitials, colorHex: comment.author.avatarColor, size: 28)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(comment.author.name)
                        .font(.ghCaptionBold)
                        .foregroundColor(.ghText)
                    Text(comment.postedAt.relativeString)
                        .font(.ghCaption)
                        .foregroundColor(.ghTextMuted)
                }
                Text(comment.text)
                    .font(.ghCaption)
                    .foregroundColor(.ghText.opacity(0.85))
            }
            Spacer()
        }
        .padding(10)
        .background(Color.ghSurface2)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Compose Post

struct ComposePostView: View {
    @ObservedObject var feedVM: FeedViewModel
    let author: User
    @Environment(\.dismiss) var dismiss
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Sheet handle
                Capsule()
                    .fill(Color.ghBorder)
                    .frame(width: 40, height: 4)
                    .padding(.top, 12)

                HStack {
                    Button("Cancel") { dismiss() }
                        .font(.ghCallout)
                        .foregroundColor(.ghTextMuted)
                    Spacer()
                    Text("New Post")
                        .font(.ghHeadline)
                        .foregroundColor(.ghText)
                    Spacer()
                    Button {
                        feedVM.submitPost(author: author)
                        dismiss()
                    } label: {
                        Text("Post")
                            .font(.ghHeadline)
                            .foregroundColor(feedVM.newPostText.isEmpty ? .ghTextMuted : .ghGold)
                    }
                    .disabled(feedVM.newPostText.isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                Divider().background(Color.ghBorder)

                HStack(alignment: .top, spacing: 12) {
                    AvatarView(initials: author.avatarInitials, colorHex: author.avatarColor, size: 40)
                    TextEditor(text: $feedVM.newPostText)
                        .focused($focused)
                        .font(.ghBody)
                        .foregroundColor(.ghText)
                        .scrollContentBackground(.hidden)
                        .background(.clear)
                        .frame(minHeight: 120)
                        .placeholder(when: feedVM.newPostText.isEmpty) {
                            Text("What's happening in the chapter?")
                                .foregroundColor(.ghTextMuted)
                                .font(.ghBody)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()
            }
        }
        .onAppear { focused = true }
    }
}
