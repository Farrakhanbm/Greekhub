import SwiftUI
import PhotosUI

// MARK: - Media Wall View

struct MediaWallView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = MediaViewModel()
    @State private var showUpload = false
    @State private var selectedPost: MediaPost? = nil

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Media Wall")
                        .font(.ghTitle).foregroundColor(.ghText)
                    Spacer()
                    Button { showUpload = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.ghGold)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 12)

                Divider().background(Color.ghBorder)

                if vm.isUploading {
                    UploadProgressBar(progress: vm.uploadProgress)
                }

                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(vm.posts) { post in
                            Button { selectedPost = post } label: {
                                MediaThumbnail(post: post)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear { vm.startListening(chapter: authVM.currentUser.chapter) }
        .onDisappear { vm.stopListening() }
        .sheet(isPresented: $showUpload) {
            UploadPhotoView(vm: vm, uploader: authVM.currentUser)
        }
        .sheet(item: $selectedPost) { post in
            MediaDetailView(post: post, vm: vm, currentUserId: authVM.currentUser.id)
        }
    }
}

// MARK: - Upload Progress Bar

struct UploadProgressBar: View {
    let progress: Double

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Uploading...")
                    .font(.ghCaption).foregroundColor(.ghTextMuted)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.ghCaptionBold).foregroundColor(.ghGold)
            }
            .padding(.horizontal, 16)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.ghSurface2).frame(height: 3)
                    Rectangle().fill(Color.ghGold)
                        .frame(width: geo.size.width * progress, height: 3)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background(Color.ghSurface)
    }
}

// MARK: - Media Thumbnail

struct MediaThumbnail: View {
    let post: MediaPost

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: URL(string: post.imageURL)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color.ghSurface2)
                        .overlay(
                            Image(systemName: "photo.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.ghTextMuted)
                        )
                }
                .frame(width: geo.size.width, height: geo.size.width)
                .clipped()

                // Likes overlay
                HStack(spacing: 3) {
                    Image(systemName: "heart.fill").font(.system(size: 9)).foregroundColor(.white)
                    Text("\(post.likes)").font(.system(size: 10, weight: .semibold)).foregroundColor(.white)
                }
                .padding(.horizontal, 6).padding(.vertical, 3)
                .background(Color.black.opacity(0.5))
                .clipShape(Capsule())
                .padding(4)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Media Detail View

struct MediaDetailView: View {
    let post: MediaPost
    @ObservedObject var vm: MediaViewModel
    let currentUserId: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.top, 20)

                Spacer()

                // Full image
                AsyncImage(url: URL(string: post.imageURL)) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    ProgressView().tint(.white)
                }

                Spacer()

                // Info bar
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        AvatarView(initials: post.uploaderInitials,
                                   colorHex: post.uploaderColor, size: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(post.uploaderName)
                                .font(.ghHeadline).foregroundColor(.white)
                            HStack(spacing: 4) {
                                if let eventTitle = post.eventTitle, !eventTitle.isEmpty {
                                    Image(systemName: "calendar").font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.6))
                                    Text(eventTitle).font(.ghCaption)
                                        .foregroundColor(.white.opacity(0.6))
                                    Text("·").foregroundColor(.white.opacity(0.4))
                                }
                                Text(post.uploadedAt.relativeString)
                                    .font(.ghCaption).foregroundColor(.white.opacity(0.6))
                            }
                        }
                        Spacer()
                        // Like button
                        Button {
                            vm.toggleLike(postId: post.id, userId: currentUserId)
                        } label: {
                            VStack(spacing: 3) {
                                Image(systemName: post.isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: 22))
                                    .foregroundColor(post.isLiked ? .ghRed : .white)
                                    .animation(.spring(response: 0.2, dampingFraction: 0.5), value: post.isLiked)
                                Text("\(post.likes)")
                                    .font(.ghCaption).foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }

                    if !post.caption.isEmpty {
                        Text(post.caption)
                            .font(.ghCallout).foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(20)
                .background(
                    LinearGradient(colors: [.clear, .black.opacity(0.8)],
                                   startPoint: .top, endPoint: .bottom)
                )
            }
        }
    }
}

// MARK: - Upload Photo View

struct UploadPhotoView: View {
    @ObservedObject var vm: MediaViewModel
    let uploader: User
    @Environment(\.dismiss) var dismiss

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage?         = nil
    @State private var caption                         = ""
    @State private var selectedEvent: ChapterEvent?    = nil

    var body: some View {
        ZStack {
            Color.ghBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule().fill(Color.ghBorder).frame(width: 40, height: 4).padding(.top, 12)

                HStack {
                    Button("Cancel") { dismiss() }.font(.ghCallout).foregroundColor(.ghTextMuted)
                    Spacer()
                    Text("New Photo").font(.ghHeadline).foregroundColor(.ghText)
                    Spacer()
                    Button("Share") {
                        if let image = selectedImage {
                            vm.uploadPhoto(image: image, caption: caption,
                                           event: selectedEvent, uploader: uploader)
                            dismiss()
                        }
                    }
                    .font(.ghCallout)
                    .foregroundColor(selectedImage == nil ? .ghTextMuted : .ghGold)
                    .disabled(selectedImage == nil)
                }
                .padding(.horizontal, 20).padding(.vertical, 16)

                Divider().background(Color.ghBorder)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {

                        // Photo picker area
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            ZStack {
                                if let img = selectedImage {
                                    Image(uiImage: img)
                                        .resizable().scaledToFill()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 280)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                } else {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(Color.ghSurface2)
                                        .frame(maxWidth: .infinity).frame(height: 200)
                                        .overlay(
                                            VStack(spacing: 10) {
                                                Image(systemName: "photo.badge.plus.fill")
                                                    .font(.system(size: 36)).foregroundColor(.ghGold)
                                                Text("Tap to choose a photo")
                                                    .font(.ghCallout).foregroundColor(.ghTextMuted)
                                            }
                                        )
                                }
                            }
                        }
                        .onChange(of: selectedItem) { item in
                            Task {
                                if let data = try? await item?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    await MainActor.run { selectedImage = image }
                                }
                            }
                        }

                        // Caption
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CAPTION").font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.ghTextMuted).kerning(0.8)
                            TextField("", text: $caption, axis: .vertical)
                                .placeholder(when: caption.isEmpty) {
                                    Text("Write a caption...").foregroundColor(.ghTextMuted)
                                }
                                .font(.ghBody).foregroundColor(.ghText).lineLimit(1...4)
                                .padding(14)
                                .background(Color.ghSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.ghBorder, lineWidth: 0.5))
                        }

                        // Tag to event (optional)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TAG AN EVENT (OPTIONAL)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.ghTextMuted).kerning(0.8)

                            Text("Event tagging coming soon — hook this up to your EventsViewModel.")
                                .font(.ghCaption).foregroundColor(.ghTextMuted)
                        }

                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 20).padding(.top, 20)
                }
            }
        }
    }
}
