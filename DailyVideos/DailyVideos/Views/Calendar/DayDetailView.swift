import SwiftUI
#if os(iOS)
import UIKit
#endif

struct DayDetailView: View {
    let day: CalendarDay
    let mediaItems: [MediaItem]
    @ObservedObject var viewModel: CalendarViewModel
    let onDismiss: () -> Void

    @State private var selectedMedia: SelectedMedia?
    @State private var preferredAsset: String?
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var showUnpinConfirmation = false
    @State private var mediaToUnpin: MediaItem?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // Platform-specific toolbar placements
    #if os(iOS)
    private let leadingPlacement: ToolbarItemPlacement = .navigationBarLeading
    private let trailingPlacement: ToolbarItemPlacement = .navigationBarTrailing
    #else
    private let leadingPlacement: ToolbarItemPlacement = .automatic
    private let trailingPlacement: ToolbarItemPlacement = .automatic
    #endif

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

    /// Context menu actions for a media item
    @ViewBuilder
    private func contextMenuActions(for item: MediaItem) -> some View {
        // Cross-date pin removal
        if case .pinnedFromOtherDay(let sourceDate) = item.displayContext {
            Button(role: .destructive) {
                mediaToUnpin = item
                showUnpinConfirmation = true
            } label: {
                Label("Remove Pin from This Day", systemImage: "pin.slash")
            }

            Divider()

            Text("Pinned from \(formatSourceDateLong(sourceDate))")
                .font(.caption)
                .foregroundColor(.secondary)
        }

        // Preferred media selection (only for native media)
        if case .native = item.displayContext {
            if item.assetIdentifier == preferredAssetIdentifier {
                Button {
                    // Already preferred, allow unpinning
                    PreferencesManager.shared.removePreferredMedia(for: day.date)
                    preferredAsset = nil
                    showToast(message: "Removed as preferred")
                } label: {
                    Label("Remove as Preferred", systemImage: "pin.slash.fill")
                }
            } else {
                Button {
                    handleSetPreferred(item)
                } label: {
                    Label("Set as Preferred", systemImage: "pin.fill")
                }
            }
        }
    }

    /// Handle setting an item as preferred
    private func handleSetPreferred(_ item: MediaItem) {
        #if os(iOS)
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif

        // Save preference
        PreferencesManager.shared.setPreferredMedia(for: day.date, assetIdentifier: item.assetIdentifier)

        // Update local state
        preferredAsset = item.assetIdentifier

        // Show toast
        showToast(message: "Set as preferred for \(formatDateMedium(day.date))")
    }

    /// Show toast message
    private func showToast(message: String) {
        toastMessage = message
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

                            Text("Record some memories for this day, or pin media from a nearby date using the button above.")
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
                                    let isPinned = item.assetIdentifier == preferredAssetIdentifier
                                    let isCrossDatePin: Bool = {
                                        if case .pinnedFromOtherDay = item.displayContext {
                                            return true
                                        }
                                        return false
                                    }()
                                    let pinSourceDate: Date? = {
                                        if case .pinnedFromOtherDay(let sourceDate) = item.displayContext {
                                            return sourceDate
                                        }
                                        return nil
                                    }()

                                    MediaThumbnailView(
                                        mediaItem: item,
                                        showPinBadge: isPinned,
                                        showCrossDatePinBadge: isCrossDatePin,
                                        pinSourceDate: pinSourceDate
                                    )
                                    .frame(width: geometry.size.width, height: geometry.size.width)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedMedia = SelectedMedia(index: index)
                                    }
                                    .contextMenu {
                                        contextMenuActions(for: item)
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
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: leadingPlacement) {
                    Button {
                        viewModel.startPinningMedia(for: day.date)
                    } label: {
                        Label("Pin Media", systemImage: "calendar.badge.plus")
                    }
                }

                ToolbarItem(placement: trailingPlacement) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showPinMediaSheet) {
                PinMediaSelectionView(
                    targetDate: day.date,
                    nearbyMediaByDate: viewModel.nearbyMediaByDate,
                    selectedSourceDate: $viewModel.selectedPinSourceDate,
                    isLoading: viewModel.isLoadingNearbyMedia,
                    onPin: { assetId, sourceDate in
                        viewModel.pinMedia(
                            assetIdentifier: assetId,
                            sourceDate: sourceDate,
                            to: day.date
                        )
                    },
                    onCancel: {
                        viewModel.cancelPinning()
                    }
                )
            }
            .alert("Remove Pin", isPresented: $showUnpinConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    if case .pinnedFromOtherDay = mediaToUnpin?.displayContext {
                        viewModel.removePinnedMedia(for: day.date)
                        showToast(message: "Pin removed")
                    }
                }
            } message: {
                Text("This will remove the media pinned from another day. The media will still exist on its original date.")
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
        #if os(iOS)
        .fullScreenCover(item: $selectedMedia) { selected in
            MediaDetailView(
                mediaItems: mediaItems,
                initialIndex: selected.index,
                onDismiss: {
                    selectedMedia = nil
                }
            )
        }
        #else
        .sheet(item: $selectedMedia) { selected in
            MediaDetailView(
                mediaItems: mediaItems,
                initialIndex: selected.index,
                onDismiss: {
                    selectedMedia = nil
                }
            )
        }
        #endif
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: day.date)
    }

    private func formatDateMedium(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formatSourceDateLong(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

#Preview("With Media") {
    DayDetailView(
        day: .sampleDayWithMedia,
        mediaItems: MediaItem.sampleMediaItems,
        viewModel: CalendarViewModel(),
        onDismiss: {}
    )
}

#Preview("Empty") {
    DayDetailView(
        day: .sampleDayWithoutMedia,
        mediaItems: [],
        viewModel: CalendarViewModel(),
        onDismiss: {}
    )
}

