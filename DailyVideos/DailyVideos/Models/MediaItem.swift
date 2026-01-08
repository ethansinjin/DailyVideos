import Foundation
import UIKit
internal import Photos

/// Represents a single video or Live Photo from the photo library
struct MediaItem: Identifiable, Equatable {
    let id = UUID()
    let assetIdentifier: String
    let date: Date
    let mediaType: MediaType
    let duration: TimeInterval?

    /// Context for how this media appears on a specific day
    var displayContext: MediaDisplayContext = .native

    // MARK: - Equatable

    static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        lhs.assetIdentifier == rhs.assetIdentifier &&
        lhs.displayContext == rhs.displayContext
    }

    /// Reference to the PHAsset (not stored, fetched when needed)
    var asset: PHAsset? {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
        return result.firstObject
    }

    init(asset: PHAsset, displayContext: MediaDisplayContext = .native) {
        self.assetIdentifier = asset.localIdentifier
        self.date = asset.creationDate ?? Date()
        self.mediaType = asset.mediaSubtypes.contains(.photoLive) ? .livePhoto : .video
        self.duration = asset.mediaType == .video ? asset.duration : nil
        self.displayContext = displayContext
    }

    /// Create a MediaItem with a specific display context
    init(assetIdentifier: String, date: Date, mediaType: MediaType, duration: TimeInterval?, displayContext: MediaDisplayContext) {
        self.assetIdentifier = assetIdentifier
        self.date = date
        self.mediaType = mediaType
        self.duration = duration
        self.displayContext = displayContext
    }
}

/// Type of media item
enum MediaType: Equatable {
    case video
    case livePhoto
}

/// Context for how media is displayed on a given day
enum MediaDisplayContext: Equatable {
    /// Media that naturally belongs to this day
    case native

    /// Media pinned from another day (with source date)
    case pinnedFromOtherDay(Date)
}
