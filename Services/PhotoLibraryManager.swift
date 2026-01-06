import Foundation
import Photos
import UIKit

/// Singleton service for accessing and managing the photo library
class PhotoLibraryManager: ObservableObject {
    static let shared = PhotoLibraryManager()

    @Published var permissionStatus: PermissionStatus = .notDetermined

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
        switch status {
        case .notDetermined:
            permissionStatus = .notDetermined
        case .restricted, .denied:
            permissionStatus = .denied
        case .authorized:
            permissionStatus = .authorized
        case .limited:
            permissionStatus = .limited
        @unknown default:
            permissionStatus = .notDetermined
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

    /// Fetch media for an entire month and organize by day
    /// - Parameters:
    ///   - year: The year
    ///   - month: The month (1-12)
    /// - Returns: Dictionary mapping dates to media counts
    func fetchMediaCounts(for year: Int, month: Int) -> [Date: Int] {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return [:]
        }

        let options = PHFetchOptions()
        options.predicate = NSPredicate(
            format: "(creationDate >= %@) AND (creationDate <= %@)",
            startOfMonth as NSDate,
            calendar.date(byAdding: .day, value: 1, to: endOfMonth)! as NSDate
        )

        // Fetch videos
        let videoAssets = PHAsset.fetchAssets(with: .video, options: options)

        // Fetch Live Photos
        let imageOptions = PHFetchOptions()
        imageOptions.predicate = NSPredicate(
            format: "(creationDate >= %@) AND (creationDate <= %@) AND (mediaSubtypes & %d) != 0",
            startOfMonth as NSDate,
            calendar.date(byAdding: .day, value: 1, to: endOfMonth)! as NSDate,
            PHAssetMediaSubtype.photoLive.rawValue
        )
        let livePhotoAssets = PHAsset.fetchAssets(with: .image, options: imageOptions)

        var mediaCounts: [Date: Int] = [:]

        // Count videos by day
        videoAssets.enumerateObjects { asset, _, _ in
            if let creationDate = asset.creationDate {
                let dayStart = calendar.startOfDay(for: creationDate)
                mediaCounts[dayStart, default: 0] += 1
            }
        }

        // Count Live Photos by day
        livePhotoAssets.enumerateObjects { asset, _, _ in
            if let creationDate = asset.creationDate {
                let dayStart = calendar.startOfDay(for: creationDate)
                mediaCounts[dayStart, default: 0] += 1
            }
        }

        return mediaCounts
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

    /// Clear the thumbnail cache (useful for memory management)
    func clearCache() {
        thumbnailCache.removeAll()
    }
}
