import Foundation
internal import Photos
import UIKit
import Combine

/// Singleton service for accessing and managing the photo library
class PhotoLibraryManager: ObservableObject {
    static let shared = PhotoLibraryManager()

    @Published var permissionStatus: PHAuthorizationStatus = .notDetermined

    private let imageManager = PHCachingImageManager()
    private var thumbnailCache: [String: UIImage] = [:]

    private init() {
        updatePermissionStatus()
    }

    // MARK: - Permission Handling

    /// Request photo library access permission
    func requestPermission(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                self?.updatePermissionStatus()
                completion(status == .authorized || status == .limited)
            }
        }
    }

    /// Update the current permission status
    private func updatePermissionStatus() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        // Always update @Published properties on main thread
        DispatchQueue.main.async { [weak self] in
            self?.permissionStatus = status
        }
    }

    // MARK: - Fetch Media

    /// Fetch all videos and Live Photos for a specific date
    /// - Parameter date: The date to fetch media for
    /// - Returns: Array of MediaItem objects
    func fetchMedia(for date: Date) -> [MediaItem] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        let options = PHFetchOptions()
        options.predicate = NSPredicate(
            format: "(creationDate >= %@) AND (creationDate < %@)",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        // Fetch videos
        let videoAssets = PHAsset.fetchAssets(with: .video, options: options)

        // Fetch Live Photos (images with live photo subtype)
        let imageOptions = PHFetchOptions()
        imageOptions.predicate = NSPredicate(
            format: "(creationDate >= %@) AND (creationDate < %@) AND (mediaSubtypes & %d) != 0",
            startOfDay as NSDate,
            endOfDay as NSDate,
            PHAssetMediaSubtype.photoLive.rawValue
        )
        imageOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let livePhotoAssets = PHAsset.fetchAssets(with: .image, options: imageOptions)

        var mediaItems: [MediaItem] = []

        // Convert videos to MediaItems
        videoAssets.enumerateObjects { asset, _, _ in
            mediaItems.append(MediaItem(asset: asset))
        }

        // Convert Live Photos to MediaItems
        livePhotoAssets.enumerateObjects { asset, _, _ in
            mediaItems.append(MediaItem(asset: asset))
        }

        // Sort by creation date (newest first)
        return mediaItems.sorted { ($0.date) > ($1.date) }
    }

    /// Data structure for day media info
    struct DayMediaInfo {
        let count: Int
        let representativeAssetIdentifier: String?
    }

    /// Fetch media for an entire month and organize by day
    /// - Parameters:
    ///   - year: The year
    ///   - month: The month (1-12)
    /// - Returns: Dictionary mapping dates to media info (count and representative asset)
    func fetchMediaInfo(for year: Int, month: Int) -> [Date: DayMediaInfo] {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth),
              let endOfMonthPlusOne = calendar.date(byAdding: .day, value: 1, to: endOfMonth) else {
            return [:]
        }

        let options = PHFetchOptions()
        options.predicate = NSPredicate(
            format: "(creationDate >= %@) AND (creationDate <= %@)",
            startOfMonth as NSDate,
            endOfMonthPlusOne as NSDate
        )
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        // Fetch videos
        let videoAssets = PHAsset.fetchAssets(with: .video, options: options)

        // Fetch Live Photos
        let imageOptions = PHFetchOptions()
        imageOptions.predicate = NSPredicate(
            format: "(creationDate >= %@) AND (creationDate <= %@) AND (mediaSubtypes & %d) != 0",
            startOfMonth as NSDate,
            endOfMonthPlusOne as NSDate,
            PHAssetMediaSubtype.photoLive.rawValue
        )
        imageOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let livePhotoAssets = PHAsset.fetchAssets(with: .image, options: imageOptions)

        // Group assets by day
        var assetsByDay: [Date: [PHAsset]] = [:]

        // Collect videos by day
        videoAssets.enumerateObjects { asset, _, _ in
            if let creationDate = asset.creationDate {
                let dayStart = calendar.startOfDay(for: creationDate)
                assetsByDay[dayStart, default: []].append(asset)
            }
        }

        // Collect Live Photos by day
        livePhotoAssets.enumerateObjects { asset, _, _ in
            if let creationDate = asset.creationDate {
                let dayStart = calendar.startOfDay(for: creationDate)
                assetsByDay[dayStart, default: []].append(asset)
            }
        }

        // Build media info using preferences or smart default selection
        var mediaInfo: [Date: DayMediaInfo] = [:]

        for (day, assets) in assetsByDay {
            var representativeAsset: String?

            // First, check if user has a preference for this day
            if let preferredAsset = PreferencesManager.shared.getPreferredMedia(for: day) {
                // Verify the preferred asset still exists in this day's assets
                let assetExists = assets.contains { $0.localIdentifier == preferredAsset }
                if assetExists {
                    representativeAsset = preferredAsset
                } else {
                    // Preferred asset was deleted, remove the stale preference
                    PreferencesManager.shared.removePreferredMedia(for: day)
                    // Fall back to smart default
                    representativeAsset = selectDefaultRepresentativeAsset(from: assets)
                }
            } else {
                // No preference exists, use smart default
                representativeAsset = selectDefaultRepresentativeAsset(from: assets)
            }

            mediaInfo[day] = DayMediaInfo(
                count: assets.count,
                representativeAssetIdentifier: representativeAsset
            )
        }

        return mediaInfo
    }

    /// Fetch media for an entire month and organize by day (count only)
    /// - Parameters:
    ///   - year: The year
    ///   - month: The month (1-12)
    /// - Returns: Dictionary mapping dates to media counts
    func fetchMediaCounts(for year: Int, month: Int) -> [Date: Int] {
        let mediaInfo = fetchMediaInfo(for: year, month: month)
        return mediaInfo.mapValues { $0.count }
    }

    // MARK: - Thumbnails

    /// Get thumbnail for a media item
    /// - Parameters:
    ///   - mediaItem: The media item
    ///   - size: The desired size of the thumbnail
    ///   - completion: Completion handler with the thumbnail image
    func getThumbnail(for mediaItem: MediaItem, size: CGSize, completion: @escaping (UIImage?) -> Void) {
        // Check cache first
        if let cachedImage = thumbnailCache[mediaItem.assetIdentifier] {
            completion(cachedImage)
            return
        }

        // Fetch asset
        guard let asset = mediaItem.asset else {
            completion(nil)
            return
        }

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        imageManager.requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { [weak self] image, _ in
            if let image = image {
                // Cache the thumbnail
                self?.thumbnailCache[mediaItem.assetIdentifier] = image
            }
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    /// Get thumbnail from asset identifier
    /// - Parameters:
    ///   - assetIdentifier: The PHAsset local identifier
    ///   - size: The desired size of the thumbnail
    ///   - completion: Completion handler with the thumbnail image
    func getThumbnail(for assetIdentifier: String, size: CGSize, completion: @escaping (UIImage?) -> Void) {
        // Check cache first
        if let cachedImage = thumbnailCache[assetIdentifier] {
            completion(cachedImage)
            return
        }

        // Fetch asset
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
        guard let asset = result.firstObject else {
            completion(nil)
            return
        }

        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false

        imageManager.requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { [weak self] image, _ in
            if let image = image {
                // Cache the thumbnail
                self?.thumbnailCache[assetIdentifier] = image
            }
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    /// Clear the thumbnail cache (useful for memory management)
    func clearCache() {
        thumbnailCache.removeAll()
    }

    // MARK: - Smart Default Selection

    /// Select the representative media from a collection of assets using smart defaults
    /// Priority: Videos first -> Live Photos second -> Chronological first
    /// - Parameter assets: Array of PHAssets
    /// - Returns: Asset identifier of the representative asset, or nil if no assets
    func selectDefaultRepresentativeAsset(from assets: [PHAsset]) -> String? {
        guard !assets.isEmpty else { return nil }

        // Sort assets by creation date (oldest first for chronological priority)
        let sortedAssets = assets.sorted {
            ($0.creationDate ?? Date.distantPast) < ($1.creationDate ?? Date.distantPast)
        }

        // Priority 1: Find first video
        if let video = sortedAssets.first(where: { $0.mediaType == .video }) {
            return video.localIdentifier
        }

        // Priority 2: Find first live photo
        if let livePhoto = sortedAssets.first(where: { $0.mediaSubtypes.contains(.photoLive) }) {
            return livePhoto.localIdentifier
        }

        // Priority 3: Return first asset chronologically
        return sortedAssets.first?.localIdentifier
    }

    /// Select the representative media from MediaItems using smart defaults
    /// Priority: Videos first -> Live Photos second -> Chronological first
    /// - Parameter items: Array of MediaItems
    /// - Returns: Asset identifier of the representative item, or nil if no items
    func selectDefaultRepresentativeMedia(from items: [MediaItem]) -> String? {
        guard !items.isEmpty else { return nil }

        // Sort items by creation date (oldest first for chronological priority)
        let sortedItems = items.sorted { $0.date < $1.date }

        // Priority 1: Find first video
        if let video = sortedItems.first(where: { $0.mediaType == .video }) {
            return video.assetIdentifier
        }

        // Priority 2: Find first live photo
        if let livePhoto = sortedItems.first(where: { $0.mediaType == .livePhoto }) {
            return livePhoto.assetIdentifier
        }

        // Priority 3: Return first item chronologically
        return sortedItems.first?.assetIdentifier
    }
}
