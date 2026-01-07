import SwiftUI

struct DayDetailView: View {
    let day: CalendarDay
    let mediaItems: [MediaItem]
    let onDismiss: () -> Void

    @State private var selectedMedia: SelectedMedia?
    @State private var preferredAsset: String?
    @State private var showToast = false
    @State private var toastMessage = ""
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var columns: [GridItem] {
        let count = horizontalSizeClass == .regular ? 5 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: count)
    }

    private struct SelectedMedia: Identifiable {
        let id = UUID()
        let index: Int
    }

    /// Get the preferred media asset identifier for this day
    private var preferredAssetIdentifier: String? {
        // Use local state if set, otherwise compute from preferences
        if let preferred = preferredAsset {
            return preferred
        }

        // First check user preference
        if let preferred = PreferencesManager.shared.getPreferredMedia(for: day.date) {
            // Verify it exists in current media items
            if mediaItems.contains(where: { $0.assetIdentifier == preferred }) {
                return preferred
            }
        }
        // Fall back to smart default
        return PhotoLibraryManager.shared.selectDefaultRepresentativeMedia(from: mediaItems)
    }

    /// Handle long press on a media item to set it as preferred
    private func handleLongPress(on item: MediaItem) {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Save preference
        PreferencesManager.shared.setPreferredMedia(for: day.date, assetIdentifier: item.assetIdentifier)

        // Update local state
        preferredAsset = item.assetIdentifier

        // Show toast
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        toastMessage = "Pinned as preferred for \(formatter.string(from: day.date))"
        showToast = true

        // Hide toast after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast = false
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with date and count
                VStack(spacing: 8) {
                    Text(formattedDate)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("\(mediaItems.count) \(mediaItems.count == 1 ? "item" : "items")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()

                if mediaItems.isEmpty {
                    // Empty state
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "video.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        VStack(spacing: 8) {
                            Text("No Videos or Live Photos")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text("Record some memories for this day!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    Spacer()
                } else {
                    // Media grid
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(Array(mediaItems.enumerated()), id: \.element.id) { index, item in
                                GeometryReader { geometry in
                                    MediaThumbnailView(
                                        mediaItem: item,
                                        showPinBadge: item.assetIdentifier == preferredAssetIdentifier
                                    )
                                    .frame(width: geometry.size.width, height: geometry.size.width)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedMedia = SelectedMedia(index: index)
                                    }
                                    .onLongPressGesture {
                                        handleLongPress(on: item)
                                    }
                                }
                                .aspectRatio(1, contentMode: .fit)
                                .clipped()
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
            .overlay(
                // Toast notification
                VStack {
                    if showToast {
                        Text(toastMessage)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(10)
                            .shadow(radius: 10)
                            .padding(.top, 60)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showToast)
                    }
                    Spacer()
                }
            )
        }
        .fullScreenCover(item: $selectedMedia) { selected in
            MediaDetailView(
                mediaItems: mediaItems,
                initialIndex: selected.index,
                onDismiss: {
                    selectedMedia = nil
                }
            )
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: day.date)
    }
}

#Preview("With Media") {
    DayDetailView(
        day: .sampleDayWithMedia,
        mediaItems: MediaItem.sampleMediaItems,
        onDismiss: {}
    )
}

#Preview("Empty") {
    DayDetailView(
        day: .sampleDayWithoutMedia,
        mediaItems: [],
        onDismiss: {}
    )
}

