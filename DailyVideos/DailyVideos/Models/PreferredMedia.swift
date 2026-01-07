import Foundation
import SwiftData

/// SwiftData model for storing user's preferred media selection for each day
@Model
class PreferredMedia {
    /// The day (normalized to start of day)
    @Attribute(.unique) var date: Date

    /// PHAsset local identifier for the preferred media
    var assetIdentifier: String

    /// Timestamp when the preference was set/updated
    var selectedAt: Date

    init(date: Date, assetIdentifier: String, selectedAt: Date = Date()) {
        self.date = date
        self.assetIdentifier = assetIdentifier
        self.selectedAt = selectedAt
    }
}
