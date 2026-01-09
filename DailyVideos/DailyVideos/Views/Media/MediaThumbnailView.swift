import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct MediaThumbnailView: View {
    let mediaItem: MediaItem
    var showPinBadge: Bool = false
    var showCrossDatePinBadge: Bool = false
    var pinSourceDate: Date? = nil
    @State private var thumbnail: PlatformImage?
    @State private var isLoading = true

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let thumbnail = thumbnail {
                    #if os(macOS)
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                    #else
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                    #endif
                } else if isLoading {
                    Color.gray.opacity(0.2)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    ProgressView()
                } else {
                    Color.gray.opacity(0.2)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                }

                // Badges in top-right corner
                VStack(alignment: .trailing, spacing: 4) {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            // Cross-date pin badge (top priority)
                            if showCrossDatePinBadge {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.system(size: 10))
                                    if let sourceDate = pinSourceDate {
                                        Text(formatSourceDate(sourceDate))
                                            .font(.system(size: 10, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.9))
                                .cornerRadius(8)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            }

                            // Preferred pin badge (secondary)
                            if showPinBadge {
                                Image(systemName: "pin.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(Color.blue.opacity(0.9))
                                    .clipShape(Circle())
                                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(6)

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
        }
        .cornerRadius(8)
        .clipped()
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

    private func formatSourceDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
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
