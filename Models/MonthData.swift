import Foundation

/// Represents a month of calendar data
struct MonthData {
    let year: Int
    let month: Int
    let days: [CalendarDay]

    /// The name of the month (e.g., "January")
    var monthName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        let date = Calendar.current.date(from: DateComponents(year: year, month: month)) ?? Date()
        return dateFormatter.string(from: date)
    }

    /// Full display string (e.g., "January 2024")
    var displayString: String {
        "\(monthName) \(year)"
    }
}
