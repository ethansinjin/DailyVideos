import Foundation
import SwiftData

/// Timeframe options for cleaning up old preferences
enum CleanupTimeframe {
    case all
    case olderThanOneYear
    case olderThanTwoYears
}

/// Service for managing user's preferred media selections
class PreferencesManager {
    static let shared = PreferencesManager()

    private var modelContext: ModelContext?

    private init() {}

    /// Set the model context (called from app initialization)
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Preference Management

    /// Save user's preferred media for a specific day
    /// - Parameters:
    ///   - date: The day (will be normalized to start of day)
    ///   - assetIdentifier: PHAsset local identifier
    func setPreferredMedia(for date: Date, assetIdentifier: String) {
        guard let context = modelContext else {
            print("⚠️ PreferencesManager: ModelContext not set")
            return
        }

        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)

        // Check if preference already exists for this day
        let descriptor = FetchDescriptor<PreferredMedia>(
            predicate: #Predicate { $0.date == normalizedDate }
        )

        do {
            let existing = try context.fetch(descriptor)

            if let existingPreference = existing.first {
                // Update existing preference
                existingPreference.assetIdentifier = assetIdentifier
                existingPreference.selectedAt = Date()
            } else {
                // Create new preference
                let newPreference = PreferredMedia(
                    date: normalizedDate,
                    assetIdentifier: assetIdentifier
                )
                context.insert(newPreference)
            }

            try context.save()
        } catch {
            print("❌ PreferencesManager: Failed to save preference - \(error)")
        }
    }

    /// Get user's preferred media for a specific day
    /// - Parameter date: The day to query
    /// - Returns: Asset identifier if preference exists, nil otherwise
    func getPreferredMedia(for date: Date) -> String? {
        guard let context = modelContext else {
            print("⚠️ PreferencesManager: ModelContext not set")
            return nil
        }

        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)

        let descriptor = FetchDescriptor<PreferredMedia>(
            predicate: #Predicate { $0.date == normalizedDate }
        )

        do {
            let results = try context.fetch(descriptor)
            return results.first?.assetIdentifier
        } catch {
            print("❌ PreferencesManager: Failed to fetch preference - \(error)")
            return nil
        }
    }

    /// Remove preference for a specific day
    /// - Parameter date: The day to remove preference for
    func removePreferredMedia(for date: Date) {
        guard let context = modelContext else {
            print("⚠️ PreferencesManager: ModelContext not set")
            return
        }

        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)

        let descriptor = FetchDescriptor<PreferredMedia>(
            predicate: #Predicate { $0.date == normalizedDate }
        )

        do {
            let results = try context.fetch(descriptor)
            if let preference = results.first {
                context.delete(preference)
                try context.save()
            }
        } catch {
            print("❌ PreferencesManager: Failed to remove preference - \(error)")
        }
    }

    // MARK: - Cleanup

    /// Cleanup old preferences based on timeframe
    /// - Parameter timeframe: The cleanup timeframe
    /// - Returns: Number of preferences removed
    @discardableResult
    func cleanupPreferences(olderThan timeframe: CleanupTimeframe) -> Int {
        guard let context = modelContext else {
            print("⚠️ PreferencesManager: ModelContext not set")
            return 0
        }

        var descriptor: FetchDescriptor<PreferredMedia>

        switch timeframe {
        case .all:
            descriptor = FetchDescriptor<PreferredMedia>()

        case .olderThanOneYear:
            let calendar = Calendar.current
            guard let cutoffDate = calendar.date(byAdding: .year, value: -1, to: Date()) else {
                return 0
            }
            descriptor = FetchDescriptor<PreferredMedia>(
                predicate: #Predicate { $0.date < cutoffDate }
            )

        case .olderThanTwoYears:
            let calendar = Calendar.current
            guard let cutoffDate = calendar.date(byAdding: .year, value: -2, to: Date()) else {
                return 0
            }
            descriptor = FetchDescriptor<PreferredMedia>(
                predicate: #Predicate { $0.date < cutoffDate }
            )
        }

        do {
            let preferencesToDelete = try context.fetch(descriptor)
            let count = preferencesToDelete.count

            for preference in preferencesToDelete {
                context.delete(preference)
            }

            try context.save()
            print("✅ PreferencesManager: Cleaned up \(count) preferences")
            return count
        } catch {
            print("❌ PreferencesManager: Failed to cleanup preferences - \(error)")
            return 0
        }
    }

    /// Get total count of stored preferences
    /// - Returns: Number of preferences
    func getPreferenceCount() -> Int {
        guard let context = modelContext else {
            print("⚠️ PreferencesManager: ModelContext not set")
            return 0
        }

        let descriptor = FetchDescriptor<PreferredMedia>()

        do {
            let count = try context.fetchCount(descriptor)
            return count
        } catch {
            print("❌ PreferencesManager: Failed to get preference count - \(error)")
            return 0
        }
    }
}
