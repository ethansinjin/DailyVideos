//
//  MediaSelectionService.swift
//  DailyVideos
//
//  Created by Claude on 1/7/26.
//

import Foundation
internal import Photos

/// Service for selecting which media to use per day for video compilation
class MediaSelectionService {
    static let shared = MediaSelectionService()

    private let photoLibraryManager = PhotoLibraryManager.shared
    private let pinnedMediaManager = PinnedMediaManager.shared

    private init() {}

    // MARK: - Main Selection Method

    /// Select media for all days within a timeframe
    /// - Parameter timeframe: The selected timeframe
    /// - Returns: Array of DayMediaSelection objects, one per day with media
    func selectMedia(for timeframe: TimeframeSelection) async -> [DayMediaSelection] {
        let calendar = Calendar.current
        let startDate = timeframe.startDate
        let endDate = timeframe.endDate

        var selections: [DayMediaSelection] = []

        // Iterate through each day in the timeframe
        var currentDate = startDate
        while currentDate <= endDate {
            if let selection = await selectMedia(for: currentDate) {
                selections.append(selection)
            }

            // Move to next day
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        return selections
    }

    /// Select media for a specific day
    /// - Parameter date: The date to select media for
    /// - Returns: DayMediaSelection if media exists for this day, nil otherwise
    func selectMedia(for date: Date) async -> DayMediaSelection? {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)

        // Step 1: Check for pinned media
        if let pinnedMedia = pinnedMediaManager.getPinnedMedia(for: normalizedDate) {
            return await createSelectionFromPin(pinnedMedia, targetDate: normalizedDate)
        }

        // Step 2: No pin exists, fetch native media for this day
        let nativeMedia = photoLibraryManager.fetchMedia(for: normalizedDate, includePinnedMedia: false)

        guard !nativeMedia.isEmpty else {
            // No media for this day
            return nil
        }

        // Step 3: Apply smart selection rules
        if let selectedMedia = selectBestMedia(from: nativeMedia) {
            let priority = calculatePriority(for: selectedMedia, in: nativeMedia)
            return DayMediaSelection(
                date: normalizedDate,
                selectedMedia: selectedMedia,
                selectionReason: .automatic(priority: priority)
            )
        }

        return nil
    }

    // MARK: - Pin Handling

    /// Create a DayMediaSelection from a PinnedMedia object
    /// - Parameters:
    ///   - pinnedMedia: The pinned media record
    ///   - targetDate: The target date where media should appear
    /// - Returns: DayMediaSelection or nil if asset no longer exists
    private func createSelectionFromPin(_ pinnedMedia: PinnedMedia, targetDate: Date) async -> DayMediaSelection? {
        // Fetch the pinned asset
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [pinnedMedia.assetIdentifier], options: nil)
        guard let asset = result.firstObject else {
            // Asset no longer exists, should cleanup orphaned pin
            print("⚠️ MediaSelectionService: Pinned asset not found: \(pinnedMedia.assetIdentifier)")
            return nil
        }

        // Create MediaItem from the asset
        let mediaItem = MediaItem(
            asset: asset,
            displayContext: .pinnedFromOtherDay(pinnedMedia.sourceDate)
        )

        // Determine if this is a "cheating" pin
        let calendar = Calendar.current
        let normalizedSource = calendar.startOfDay(for: pinnedMedia.sourceDate)
        let normalizedTarget = calendar.startOfDay(for: targetDate)

        let isCheating = normalizedSource != normalizedTarget

        let selectionReason: DayMediaSelection.SelectionReason = isCheating
            ? .pinnedCheating(fromDate: normalizedSource)
            : .pinnedNormal

        return DayMediaSelection(
            date: targetDate,
            selectedMedia: mediaItem,
            selectionReason: selectionReason
        )
    }

    // MARK: - Selection Rules

    /// Select the best media from a collection using preference rules
    /// Priority: Videos > Live Photos > Chronological (oldest first)
    /// - Parameter mediaItems: Array of media items
    /// - Returns: The selected MediaItem, or nil if array is empty
    private func selectBestMedia(from mediaItems: [MediaItem]) -> MediaItem? {
        guard !mediaItems.isEmpty else { return nil }

        // Sort items by creation date (oldest first for chronological priority)
        let sortedItems = mediaItems.sorted { $0.date < $1.date }

        // Priority 1: Find first video (chronologically)
        if let video = sortedItems.first(where: { $0.mediaType == .video }) {
            return video
        }

        // Priority 2: Find first live photo (chronologically)
        if let livePhoto = sortedItems.first(where: { $0.mediaType == .livePhoto }) {
            return livePhoto
        }

        // Priority 3: Return first item chronologically
        return sortedItems.first
    }

    /// Calculate priority score for a media item (for display purposes)
    /// Higher priority = better match to selection rules
    /// - Parameters:
    ///   - mediaItem: The selected media item
    ///   - allItems: All available media items for this day
    /// - Returns: Priority score (1 = highest)
    private func calculatePriority(for mediaItem: MediaItem, in allItems: [MediaItem]) -> Int {
        let sortedItems = allItems.sorted { $0.date < $1.date }

        // If it's the first video, it's priority 1
        if mediaItem.mediaType == .video,
           let firstVideo = sortedItems.first(where: { $0.mediaType == .video }),
           mediaItem.assetIdentifier == firstVideo.assetIdentifier {
            return 1
        }

        // If it's the first live photo (and no videos exist), it's priority 1
        if mediaItem.mediaType == .livePhoto,
           !sortedItems.contains(where: { $0.mediaType == .video }),
           let firstLivePhoto = sortedItems.first(where: { $0.mediaType == .livePhoto }),
           mediaItem.assetIdentifier == firstLivePhoto.assetIdentifier {
            return 1
        }

        // Otherwise, calculate position in sorted list
        if let index = sortedItems.firstIndex(where: { $0.assetIdentifier == mediaItem.assetIdentifier }) {
            return index + 1
        }

        return allItems.count
    }

    // MARK: - Validation

    /// Validate that a timeframe has at least some media
    /// - Parameter timeframe: The timeframe to validate
    /// - Returns: Number of days with media in the timeframe
    func validateTimeframe(_ timeframe: TimeframeSelection) async -> Int {
        let selections = await selectMedia(for: timeframe)
        return selections.count
    }

    /// Get summary statistics for a timeframe
    /// - Parameter timeframe: The timeframe to analyze
    /// - Returns: Summary statistics
    func getTimeframeSummary(_ timeframe: TimeframeSelection) async -> TimeframeSummary {
        let selections = await selectMedia(for: timeframe)

        let totalDays = selections.count
        let pinnedCount = selections.filter { $0.isPinned }.count
        let cheatingCount = selections.filter { $0.isCheating }.count
        let videoCount = selections.filter { $0.selectedMedia.mediaType == .video }.count
        let livePhotoCount = selections.filter { $0.selectedMedia.mediaType == .livePhoto }.count

        let totalDuration = selections.reduce(0.0) { total, selection in
            total + (selection.selectedMedia.duration ?? 3.0) // Default 3s for Live Photos
        }

        return TimeframeSummary(
            totalDays: totalDays,
            pinnedCount: pinnedCount,
            cheatingPinCount: cheatingCount,
            videoCount: videoCount,
            livePhotoCount: livePhotoCount,
            estimatedDuration: totalDuration
        )
    }
}

// MARK: - Supporting Types

/// Summary statistics for a timeframe selection
struct TimeframeSummary {
    let totalDays: Int
    let pinnedCount: Int
    let cheatingPinCount: Int
    let videoCount: Int
    let livePhotoCount: Int
    let estimatedDuration: TimeInterval

    /// Human-readable duration string
    var durationString: String {
        let minutes = Int(estimatedDuration) / 60
        let seconds = Int(estimatedDuration) % 60

        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }

    /// Summary description
    var description: String {
        return "\(totalDays) days • \(durationString) • \(pinnedCount) pinned"
    }
}
