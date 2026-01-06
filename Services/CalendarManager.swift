import Foundation

/// Manages calendar logic and date calculations
class CalendarManager {
    static let shared = CalendarManager()

    private let calendar = Calendar.current

    private init() {}

    /// Generate calendar data for a specific month
    /// - Parameters:
    ///   - year: The year
    ///   - month: The month (1-12)
    /// - Returns: MonthData containing all days for the calendar grid
    func generateMonth(year: Int, month: Int) -> MonthData {
        var days: [CalendarDay] = []

        // Get the first day of the month
        guard let firstDayOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else {
            return MonthData(year: year, month: month, days: [])
        }

        // Get the weekday of the first day (1 = Sunday, 2 = Monday, etc.)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)

        // Get number of days in the month
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth)?.count ?? 30

        // Add padding days from previous month
        let paddingDays = firstWeekday - 1 // Days before the 1st
        if paddingDays > 0 {
            let previousMonth = self.previousMonth(from: (year, month))
            guard let firstDayOfPrevMonth = calendar.date(from: DateComponents(year: previousMonth.year, month: previousMonth.month, day: 1)) else {
                return MonthData(year: year, month: month, days: [])
            }
            let daysInPrevMonth = calendar.range(of: .day, in: .month, for: firstDayOfPrevMonth)?.count ?? 30

            for day in (daysInPrevMonth - paddingDays + 1)...daysInPrevMonth {
                if let date = calendar.date(from: DateComponents(year: previousMonth.year, month: previousMonth.month, day: day)) {
                    days.append(CalendarDay(date: date, day: day, isInCurrentMonth: false))
                }
            }
        }

        // Add days of current month
        for day in 1...daysInMonth {
            if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                days.append(CalendarDay(date: date, day: day, isInCurrentMonth: true))
            }
        }

        // Add padding days from next month to complete the grid
        let totalDays = days.count
        let remainingDays = 42 - totalDays // 6 rows * 7 days = 42
        if remainingDays > 0 {
            let nextMonth = self.nextMonth(from: (year, month))
            for day in 1...remainingDays {
                if let date = calendar.date(from: DateComponents(year: nextMonth.year, month: nextMonth.month, day: day)) {
                    days.append(CalendarDay(date: date, day: day, isInCurrentMonth: false))
                }
            }
        }

        return MonthData(year: year, month: month, days: days)
    }

    /// Get the current month and year
    /// - Returns: Tuple of (year, month)
    func currentMonth() -> (year: Int, month: Int) {
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        return (year, month)
    }

    /// Calculate the next month from a given month
    /// - Parameter from: Tuple of (year, month)
    /// - Returns: Tuple of next (year, month)
    func nextMonth(from: (year: Int, month: Int)) -> (year: Int, month: Int) {
        if from.month == 12 {
            return (from.year + 1, 1)
        } else {
            return (from.year, from.month + 1)
        }
    }

    /// Calculate the previous month from a given month
    /// - Parameter from: Tuple of (year, month)
    /// - Returns: Tuple of previous (year, month)
    func previousMonth(from: (year: Int, month: Int)) -> (year: Int, month: Int) {
        if from.month == 1 {
            return (from.year - 1, 12)
        } else {
            return (from.year, from.month - 1)
        }
    }

    /// Check if a date is today
    /// - Parameter date: The date to check
    /// - Returns: True if the date is today
    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    /// Get the day of week labels (Sun - Sat)
    /// - Returns: Array of weekday symbols
    func weekdaySymbols() -> [String] {
        calendar.shortWeekdaySymbols
    }
}
