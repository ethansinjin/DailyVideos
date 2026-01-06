import SwiftUI

struct MediaThumbnailView: View {
    let mediaItem: MediaItem
    @State private var thumbnail: UIImage?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else if isLoading {
                Color.gray.opacity(0.2)
                ProgressView()
            } else {
                Color.gray.opacity(0.2)
                Image(systemName: "photo")
                    .foregroundColor(.gray)
            }

            // Overlay for media type
            VStack {
                Spacer()
                HStack {
                    // Media type badge
                    mediaBadge
                    Spacer()
                    // Duration for videos
                    if let duration = mediaItem.duration {
                        Text(formatDuration(duration))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)
                    }
                }
                .padding(6)
            }
        }
        .cornerRadius(8)
        .onAppear {
            loadThumbnail()
        }
    }

    @ViewBuilder
    private var mediaBadge: some View {
        switch mediaItem.mediaType {
        case .video:
            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundColor(.white)
                .shadow(radius: 2)
        case .livePhoto:
            Text("LIVE")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.7))
                .cornerRadius(4)
        }
    }

    private func loadThumbnail() {
        let size = CGSize(width: 300, height: 300)
        PhotoLibraryManager.shared.getThumbnail(for: mediaItem, size: size) { image in
            self.thumbnail = image
            self.isLoading = false
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview("Video") {
    MediaThumbnailView(mediaItem: .sampleVideo)
        .frame(width: 120, height: 120)
        .padding()
}

#Preview("Live Photo") {
    MediaThumbnailView(mediaItem: .sampleLivePhoto)
        .frame(width: 120, height: 120)
        .padding()
}
