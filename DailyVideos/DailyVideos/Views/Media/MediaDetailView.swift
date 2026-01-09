import SwiftUI
import AVKit
internal import Photos
import PhotosUI

struct MediaDetailView: View {
    let mediaItems: [MediaItem]
    let initialIndex: Int
    let onDismiss: () -> Void

    @State private var currentIndex: Int
    @State private var dragOffset: CGFloat = 0

    init(mediaItems: [MediaItem], initialIndex: Int, onDismiss: @escaping () -> Void) {
        self.mediaItems = mediaItems
        self.initialIndex = initialIndex
        self.onDismiss = onDismiss
        _currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(mediaItems.enumerated()), id: \.element.id) { index, item in
                    MediaContentView(mediaItem: item)
                        .tag(index)
                }
            }
#if os(iOS) || os(visionOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
#endif
            .ignoresSafeArea()

            // Top bar with controls
            VStack {
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }

                    Spacer()

                    // Page indicator
                    if mediaItems.count > 1 {
                        Text("\(currentIndex + 1) / \(mediaItems.count)")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(12)
                    }
                }
                .padding()

                Spacer()
            }
        }
    }
}

// MARK: - Media Content View
struct MediaContentView: View {
    let mediaItem: MediaItem

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black

                switch mediaItem.mediaType {
                case .video:
                    VideoPlayerView(mediaItem: mediaItem)
                case .livePhoto:
                    LivePhotoView(mediaItem: mediaItem)
                }
            }
        }
    }
}

// MARK: - Video Player View
struct VideoPlayerView: View {
    let mediaItem: MediaItem
    @State private var player: AVPlayer?

    var body: some View {
        Group {
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
        .onAppear {
            loadVideo()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    private func loadVideo() {
        guard let asset = mediaItem.asset else { return }

        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat

        PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { playerItem, _ in
            DispatchQueue.main.async {
                if let playerItem = playerItem {
                    self.player = AVPlayer(playerItem: playerItem)
                }
            }
        }
    }
}

// MARK: - Live Photo View
struct LivePhotoView: View {
    let mediaItem: MediaItem
    @State private var livePhoto: PHLivePhoto?
    @State private var isLoading = true
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if let livePhoto = livePhoto {
                    LivePhotoViewRepresentable(livePhoto: livePhoto)
                        .ignoresSafeArea()
                } else if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                } else {
                    Text("Failed to load Live Photo")
                        .foregroundColor(.white)
                }
            }
            .onAppear {
                loadLivePhoto(targetSize: proxy.size)
            }
        }
    }

    private func loadLivePhoto(targetSize: CGSize) {
        guard let asset = mediaItem.asset else {
            isLoading = false
            return
        }

        let options = PHLivePhotoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat

        PHImageManager.default().requestLivePhoto(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        ) { livePhoto, _ in
            DispatchQueue.main.async {
                self.livePhoto = livePhoto
                self.isLoading = false
            }
        }
    }
}

// MARK: - Live Photo Representable (UIKit/AppKit)
#if os(iOS) || os(visionOS)
struct LivePhotoViewRepresentable: UIViewRepresentable {
    let livePhoto: PHLivePhoto

    func makeUIView(context: Context) -> PHLivePhotoView {
        let view = PHLivePhotoView()
        view.contentMode = .scaleAspectFit
        view.livePhoto = livePhoto
        view.startPlayback(with: .full)
        return view
    }

    func updateUIView(_ uiView: PHLivePhotoView, context: Context) {
        uiView.livePhoto = livePhoto
    }
}
#elseif os(macOS)
struct LivePhotoViewRepresentable: NSViewRepresentable {
    let livePhoto: PHLivePhoto

    func makeNSView(context: Context) -> PHLivePhotoView {
        let view = PHLivePhotoView()
        // AppKit PHLivePhotoView does not use UIView content modes.
        view.livePhoto = livePhoto
        view.startPlayback(with: .full)
        return view
    }

    func updateNSView(_ nsView: PHLivePhotoView, context: Context) {
        nsView.livePhoto = livePhoto
    }
}
#endif

#Preview("Single Video") {
    MediaDetailView(
        mediaItems: [.sampleVideo],
        initialIndex: 0,
        onDismiss: {}
    )
}

#Preview("Multiple Items") {
    MediaDetailView(
        mediaItems: MediaItem.sampleMediaItems,
        initialIndex: 0,
        onDismiss: {}
    )
}
