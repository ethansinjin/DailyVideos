import Foundation
import UIKit

// MARK: - Mock Data for Previews

extension MediaItem {
    /// Mock initializer for preview purposes
    static func mock(
        assetIdentifier: String = "mock-asset-id",
        date: Date = Date(),
        mediaType: MediaType = .video,
        duration: TimeInterval? = 125,
        displayContext: MediaDisplayContext = .native
    ) -> MediaItem {
        MediaItem(
            assetIdentifier: assetIdentifier,
            date: date,
            mediaType: mediaType,
            duration: duration,
            displayContext: displayContext
        )
    }

    static var sampleVideo: MediaItem {
        .mock(
            assetIdentifier: "sample-video-1",
            date: Date(),
            mediaType: .video,
            duration: 125
        )
    }

    static var sampleLivePhoto: MediaItem {
        .mock(
            assetIdentifier: "sample-live-photo-1",
            date: Date(),
            mediaType: .livePhoto,
            duration: nil
        )
    }

    static var sampleMediaItems: [MediaItem] {
        [
            .mock(assetIdentifier: "video-1", mediaType: .video, duration: 45),
            .mock(assetIdentifier: "live-1", mediaType: .livePhoto),
            .mock(assetIdentifier: "video-2", mediaType: .video, duration: 180),
            .mock(assetIdentifier: "live-2", mediaType: .livePhoto),
            .mock(assetIdentifier: "video-3", mediaType: .video, duration: 90)
        ]
    }
}

extension CalendarDay {
    static var sampleDayWithMedia: CalendarDay {
        var day = CalendarDay(date: Date(), day: 15, isInCurrentMonth: true)
        day.mediaCount = 3
        day.representativeAssetIdentifier = "sample-asset-1"
        return day
    }

    static var sampleDayWithoutMedia: CalendarDay {
        CalendarDay(date: Date(), day: 20, isInCurrentMonth: true)
    }

    static var sampleDayOutsideMonth: CalendarDay {
        CalendarDay(date: Date(), day: 28, isInCurrentMonth: false)
    }
}

extension MonthData {
    static var sampleMonth: MonthData {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        let year = components.year ?? 2024
        let month = components.month ?? 1

        // Create sample days for a month
        var days: [CalendarDay] = []

        // Add a few days from previous month
        for i in 28...30 {
            days.append(CalendarDay(
                date: calendar.date(from: DateComponents(year: year, month: month - 1, day: i)) ?? Date(),
                day: i,
                isInCurrentMonth: false
            ))
        }

        // Add current month days (simplified to 28 days)
        for day in 1...28 {
            var calDay = CalendarDay(
                date: calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date(),
                day: day,
                isInCurrentMonth: true
            )
            // Add media to some random days
            if [3, 7, 15, 20, 25].contains(day) {
                calDay.mediaCount = Int.random(in: 1...5)
                calDay.representativeAssetIdentifier = "mock-asset-\(day)"
            }
            days.append(calDay)
        }

        // Add a few days from next month to fill grid
        for i in 1...7 {
            days.append(CalendarDay(
                date: calendar.date(from: DateComponents(year: year, month: month + 1, day: i)) ?? Date(),
                day: i,
                isInCurrentMonth: false
            ))
        }

        return MonthData(year: year, month: month, days: days)
    }
}
