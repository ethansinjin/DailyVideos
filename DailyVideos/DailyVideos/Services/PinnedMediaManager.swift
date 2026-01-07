//
//  PinnedMediaManager.swift
//  DailyVideos
//
//  Created by Claude on 1/7/26.
//

import Foundation
import SwiftData
internal import Photos

/// Service for managing media pinned from other days
class PinnedMediaManager {
    static let shared = PinnedMediaManager()

    private var modelContext: ModelContext?

    private init() {}

    /// Set the model context (called from app initialization)
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Pin Management

    /// Pin media from a source date to a target date
    /// - Parameters:
    ///   - assetIdentifier: PHAsset local identifier
    ///   - sourceDate: The date where the media actually originates from
    ///   - targetDate: The day where media should appear (will be normalized to start of day)
    func pinMedia(assetIdentifier: String, sourceDate: Date, to targetDate: Date) {
        guard let context = modelContext else {
            print("⚠️ PinnedMediaManager: ModelContext not set")
            return
        }

        let calendar = Calendar.current
        let normalizedTarget = calendar.startOfDay(for: targetDate)
        let normalizedSource = calendar.startOfDay(for: sourceDate)

        // Validate that we're not pinning to the same day
        if normalizedTarget == normalizedSource {
            print("⚠️ PinnedMediaManager: Cannot pin media to the same day it originates from")
            return
        }

        // Verify the asset exists
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
        guard result.firstObject != nil else {
            print("⚠️ PinnedMediaManager: Asset not found in photo library")
            return
        }

        // Check if pin already exists for this target date
        let descriptor = FetchDescriptor<PinnedMedia>(
            predicate: #Predicate { $0.targetDate == normalizedTarget }
        )

        do {
            let existing = try context.fetch(descriptor)

            if let existingPin = existing.first {
                // Update existing pin
                existingPin.assetIdentifier = assetIdentifier
                existingPin.sourceDate = normalizedSource
                existingPin.pinnedAt = Date()
                print("✅ PinnedMediaManager: Updated pin for \(normalizedTarget)")
            } else {
                // Create new pin
                let newPin = PinnedMedia(
                    targetDate: normalizedTarget,
                    assetIdentifier: assetIdentifier,
                    sourceDate: normalizedSource
                )
                context.insert(newPin)
                print("✅ PinnedMediaManager: Created new pin for \(normalizedTarget)")
            }

            try context.save()
        } catch {
            print("❌ PinnedMediaManager: Failed to save pin - \(error)")
        }
    }

    /// Get pinned media for a specific target date
    /// - Parameter targetDate: The day to query
    /// - Returns: PinnedMedia if exists, nil otherwise
    func getPinnedMedia(for targetDate: Date) -> PinnedMedia? {
        guard let context = modelContext else {
            print("⚠️ PinnedMediaManager: ModelContext not set")
            return nil
        }

        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: targetDate)

        let descriptor = FetchDescriptor<PinnedMedia>(
            predicate: #Predicate { $0.targetDate == normalizedDate }
        )

        do {
            let results = try context.fetch(descriptor)
            return results.first
        } catch {
            print("❌ PinnedMediaManager: Failed to fetch pin - \(error)")
            return nil
        }
    }

    /// Remove pinned media for a target date
    /// - Parameter targetDate: The day to remove pin for
    func removePinnedMedia(for targetDate: Date) {
        guard let context = modelContext else {
            print("⚠️ PinnedMediaManager: ModelContext not set")
            return
        }

        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: targetDate)

        let descriptor = FetchDescriptor<PinnedMedia>(
            predicate: #Predicate { $0.targetDate == normalizedDate }
        )

        do {
            let results = try context.fetch(descriptor)
            if let pin = results.first {
                context.delete(pin)
                try context.save()
                print("✅ PinnedMediaManager: Removed pin for \(normalizedDate)")
            }
        } catch {
            print("❌ PinnedMediaManager: Failed to remove pin - \(error)")
        }
    }

    /// Check if specific media is pinned to a target date
    /// - Parameters:
    ///   - assetIdentifier: PHAsset local identifier
    ///   - targetDate: The day to check
    /// - Returns: True if this specific asset is pinned to this date
    func isPinned(assetIdentifier: String, to targetDate: Date) -> Bool {
        guard let pin = getPinnedMedia(for: targetDate) else {
            return false
        }
        return pin.assetIdentifier == assetIdentifier
    }

    /// Get all pinned media (for management/cleanup)
    /// - Returns: Array of all PinnedMedia records
    func getAllPinnedMedia() -> [PinnedMedia] {
        guard let context = modelContext else {
            print("⚠️ PinnedMediaManager: ModelContext not set")
            return []
        }

        let descriptor = FetchDescriptor<PinnedMedia>(
            sortBy: [SortDescriptor(\.targetDate, order: .reverse)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("❌ PinnedMediaManager: Failed to fetch all pins - \(error)")
            return []
        }
    }

    // MARK: - Cleanup

    /// Remove pins older than specified timeframe
    /// - Parameter timeframe: The cleanup timeframe
    /// - Returns: Number of pins removed
    @discardableResult
    func cleanupPins(olderThan timeframe: CleanupTimeframe) -> Int {
        guard let context = modelContext else {
            print("⚠️ PinnedMediaManager: ModelContext not set")
            return 0
        }

        var descriptor: FetchDescriptor<PinnedMedia>

        switch timeframe {
        case .all:
            descriptor = FetchDescriptor<PinnedMedia>()

        case .olderThanOneYear:
            let calendar = Calendar.current
            guard let cutoffDate = calendar.date(byAdding: .year, value: -1, to: Date()) else {
                return 0
            }
            descriptor = FetchDescriptor<PinnedMedia>(
                predicate: #Predicate { $0.targetDate < cutoffDate }
            )

        case .olderThanTwoYears:
            let calendar = Calendar.current
            guard let cutoffDate = calendar.date(byAdding: .year, value: -2, to: Date()) else {
                return 0
            }
            descriptor = FetchDescriptor<PinnedMedia>(
                predicate: #Predicate { $0.targetDate < cutoffDate }
            )
        }

        do {
            let pinsToDelete = try context.fetch(descriptor)
            let count = pinsToDelete.count

            for pin in pinsToDelete {
                context.delete(pin)
            }

            try context.save()
            print("✅ PinnedMediaManager: Cleaned up \(count) pins")
            return count
        } catch {
            print("❌ PinnedMediaManager: Failed to cleanup pins - \(error)")
            return 0
        }
    }

    /// Remove pins for assets that no longer exist in photo library
    /// - Returns: Number of orphaned pins removed
    @discardableResult
    func cleanupOrphanedPins() -> Int {
        guard let context = modelContext else {
            print("⚠️ PinnedMediaManager: ModelContext not set")
            return 0
        }

        let allPins = getAllPinnedMedia()
        var orphanedCount = 0

        for pin in allPins {
            let result = PHAsset.fetchAssets(withLocalIdentifiers: [pin.assetIdentifier], options: nil)
            if result.firstObject == nil {
                // Asset no longer exists, remove pin
                context.delete(pin)
                orphanedCount += 1
            }
        }

        if orphanedCount > 0 {
            do {
                try context.save()
                print("✅ PinnedMediaManager: Removed \(orphanedCount) orphaned pins")
            } catch {
                print("❌ PinnedMediaManager: Failed to save after orphan cleanup - \(error)")
            }
        }

        return orphanedCount
    }

    /// Get total count of stored pins
    /// - Returns: Number of pins
    func getPinCount() -> Int {
        guard let context = modelContext else {
            print("⚠️ PinnedMediaManager: ModelContext not set")
            return 0
        }

        let descriptor = FetchDescriptor<PinnedMedia>()

        do {
            let count = try context.fetchCount(descriptor)
            return count
        } catch {
            print("❌ PinnedMediaManager: Failed to get pin count - \(error)")
            return 0
        }
    }
}
