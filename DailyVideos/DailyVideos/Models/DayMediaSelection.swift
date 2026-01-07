//
//  DayMediaSelection.swift
//  DailyVideos
//
//  Created by Claude on 1/7/26.
//

import Foundation

/// Represents the media selected for a specific day in a video compilation
struct DayMediaSelection: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let selectedMedia: MediaItem
    let selectionReason: SelectionReason

    init(id: UUID = UUID(), date: Date, selectedMedia: MediaItem, selectionReason: SelectionReason) {
        self.id = id
        self.date = date
        self.selectedMedia = selectedMedia
        self.selectionReason = selectionReason
    }

    /// Reason why this media was selected for this day
    enum SelectionReason: Equatable {
        /// Media was pinned to its original day
        case pinnedNormal

        /// Media was pinned from a different day ("cheating")
        case pinnedCheating(fromDate: Date)

        /// Automatically selected by preference rules
        case automatic(priority: Int)

        /// User manually selected from multiple options
        case manualSelection
    }

    /// Whether this selection represents a "cheat" pin
    var isCheating: Bool {
        if case .pinnedCheating = selectionReason {
            return true
        }
        return false
    }

    /// Whether this selection was pinned (normal or cheating)
    var isPinned: Bool {
        switch selectionReason {
        case .pinnedNormal, .pinnedCheating:
            return true
        default:
            return false
        }
    }

    /// Display label for the selection reason
    var reasonLabel: String {
        switch selectionReason {
        case .pinnedNormal:
            return "Pinned"
        case .pinnedCheating(let fromDate):
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return "Pinned from \(formatter.string(from: fromDate))"
        case .automatic(let priority):
            return "Auto (Priority \(priority))"
        case .manualSelection:
            return "Manually Selected"
        }
    }
}
