//
//  TimeframeSelection.swift
//  DailyVideos
//
//  Created by Claude on 1/7/26.
//

import Foundation

/// Type of timeframe for video generation
enum TimeframeType: Codable, Equatable {
    case month(year: Int, month: Int)
    case year(year: Int)
    case custom(startDate: Date, endDate: Date)
}

/// Represents a selected time range for video generation
struct TimeframeSelection: Identifiable, Equatable {
    let id: UUID
    let type: TimeframeType

    init(id: UUID = UUID(), type: TimeframeType) {
        self.id = id
        self.type = type
    }

    /// Computed start date based on timeframe type
    var startDate: Date {
        let calendar = Calendar.current

        switch type {
        case .month(let year, let month):
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = 1
            return calendar.date(from: components) ?? Date()

        case .year(let year):
            var components = DateComponents()
            components.year = year
            components.month = 1
            components.day = 1
            return calendar.date(from: components) ?? Date()

        case .custom(let startDate, _):
            return calendar.startOfDay(for: startDate)
        }
    }

    /// Computed end date based on timeframe type
    var endDate: Date {
        let calendar = Calendar.current

        switch type {
        case .month(let year, let month):
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = 1

            guard let monthStart = calendar.date(from: components),
                  let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else {
                return Date()
            }
            return calendar.startOfDay(for: monthEnd)

        case .year(let year):
            var components = DateComponents()
            components.year = year
            components.month = 12
            components.day = 31
            return calendar.date(from: components) ?? Date()

        case .custom(_, let endDate):
            return calendar.startOfDay(for: endDate)
        }
    }

    /// Human-readable display name for the timeframe
    var displayName: String {
        let formatter = DateFormatter()

        switch type {
        case .month(let year, let month):
            formatter.dateFormat = "MMMM yyyy"
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = 1
            if let date = Calendar.current.date(from: components) {
                return formatter.string(from: date)
            }
            return "\(month)/\(year)"

        case .year(let year):
            return "\(year)"

        case .custom(let start, let end):
            formatter.dateStyle = .medium
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
    }

    /// Number of days in the timeframe
    var dayCount: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return (components.day ?? 0) + 1 // +1 to include both start and end dates
    }
}
