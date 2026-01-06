import Foundation
import SwiftUI

/// ViewModel for managing calendar state
class CalendarViewModel: ObservableObject {
    @Published var currentMonth: MonthData
    @Published var selectedDay: CalendarDay?

    private let calendarManager = CalendarManager.shared
    private var currentYear: Int
    private var currentMonthNumber: Int

    init() {
        let current = calendarManager.currentMonth()
        self.currentYear = current.year
        self.currentMonthNumber = current.month
        self.currentMonth = calendarManager.generateMonth(year: currentYear, month: currentMonthNumber)
    }

    /// Navigate to the next month
    func goToNextMonth() {
        let next = calendarManager.nextMonth(from: (currentYear, currentMonthNumber))
        currentYear = next.year
        currentMonthNumber = next.month
        loadCurrentMonth()
    }

    /// Navigate to the previous month
    func goToPreviousMonth() {
        let previous = calendarManager.previousMonth(from: (currentYear, currentMonthNumber))
        currentYear = previous.year
        currentMonthNumber = previous.month
        loadCurrentMonth()
    }

    /// Navigate to today's month
    func goToToday() {
        let today = calendarManager.currentMonth()
        currentYear = today.year
        currentMonthNumber = today.month
        loadCurrentMonth()
    }

    /// Select a specific day
    func selectDay(_ day: CalendarDay) {
        selectedDay = day
    }

    /// Load the current month data
    private func loadCurrentMonth() {
        currentMonth = calendarManager.generateMonth(year: currentYear, month: currentMonthNumber)
    }

    /// Check if a date is today
    func isToday(_ date: Date) -> Bool {
        calendarManager.isToday(date)
    }

    /// Get weekday symbols
    func weekdaySymbols() -> [String] {
        calendarManager.weekdaySymbols()
    }
}
