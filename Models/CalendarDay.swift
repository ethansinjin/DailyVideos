import Foundation

/// Represents a single day in the calendar
struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let day: Int
    let isInCurrentMonth: Bool

    // Media-related properties (to be populated in Phase 2)
    var mediaCount: Int = 0

    var hasMedia: Bool {
        mediaCount > 0
    }

    init(date: Date, day: Int, isInCurrentMonth: Bool) {
        self.date = date
        self.day = day
        self.isInCurrentMonth = isInCurrentMonth
    }
}
