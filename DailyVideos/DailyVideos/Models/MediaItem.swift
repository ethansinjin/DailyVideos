import Foundation
import UIKit
import Photos

/// Represents a single video or Live Photo from the photo library
struct MediaItem: Identifiable {
    let id = UUID()
    let assetIdentifier: String
    let date: Date
    let mediaType: MediaType
    let duration: TimeInterval?

    /// Reference to the PHAsset (not stored, fetched when needed)
    var asset: PHAsset? {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
        return result.firstObject
    }

    init(asset: PHAsset) {
        self.assetIdentifier = asset.localIdentifier
        self.date = asset.creationDate ?? Date()
        self.mediaType = asset.mediaSubtypes.contains(.photoLive) ? .livePhoto : .video
        self.duration = asset.mediaType == .video ? asset.duration : nil
    }
}

/// Type of media item
enum MediaType {
    case video
    case livePhoto
}
