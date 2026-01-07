//
//  PinnedMedia.swift
//  DailyVideos
//
//  Created by Claude on 1/7/26.
//

import Foundation
import SwiftData

/// SwiftData model for storing media pinned from other days
/// This represents the "cheat day" feature where users can pin media from nearby dates
@Model
class PinnedMedia {
    /// The target day where media should appear (normalized to start of day)
    @Attribute(.unique) var targetDate: Date

    /// PHAsset local identifier for the pinned media
    var assetIdentifier: String

    /// The source date where the media actually originates from
    var sourceDate: Date

    /// Timestamp when the pin was created
    var pinnedAt: Date

    init(targetDate: Date, assetIdentifier: String, sourceDate: Date, pinnedAt: Date = Date()) {
        self.targetDate = targetDate
        self.assetIdentifier = assetIdentifier
        self.sourceDate = sourceDate
        self.pinnedAt = pinnedAt
    }
}
