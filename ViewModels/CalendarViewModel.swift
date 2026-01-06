import Foundation
import SwiftUI

/// ViewModel for managing calendar state
class CalendarViewModel: ObservableObject {
    @Published var currentMonth: MonthData
    @Published var selectedDay: CalendarDay?
    @Published var permissionStatus: PermissionStatus = .notDetermined
    @Published var isLoading: Bool = false

    private let calendarManager = CalendarManager.shared
    private let photoLibraryManager = PhotoLibraryManager.shared
    private var currentYear: Int
    private var currentMonthNumber: Int

    init() {
        let current = calendarManager.currentMonth()
        self.currentYear = current.year
        self.currentMonthNumber = current.month
        self.currentMonth = calendarManager.generateMonth(year: currentYear, month: currentMonthNumber)

        // Request permission and load media
        requestPermissionAndLoadMedia()
    }

    /// Request photo library permission and load media data
    func requestPermissionAndLoadMedia() {
        photoLibraryManager.requestPermission { [weak self] granted in
            guard let self = self else { return }
            self.permissionStatus = self.photoLibraryManager.permissionStatus
            if granted {
                self.loadCurrentMonth()
            }
        }
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

    /// Refresh media data for current month
    func refreshMediaData() {
        loadCurrentMonth()
    }

    /// Load the current month data with media counts
    private func loadCurrentMonth() {
        isLoading = true

        // Capture current values for background thread
        let year = currentYear
        let month = currentMonthNumber

        // Perform heavy operations on background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Generate calendar structure
            var monthData = self.calendarManager.generateMonth(year: year, month: month)

            // Fetch media info for the month (counts + representative assets)
            let mediaInfo = self.photoLibraryManager.fetchMediaInfo(for: year, month: month)

            // Update days with media counts and representative assets
            let calendar = Calendar.current
            let updatedDays = monthData.days.map { day -> CalendarDay in
                var updatedDay = day
                let dayStart = calendar.startOfDay(for: day.date)
                let info = mediaInfo[dayStart]
                updatedDay.mediaCount = info?.count ?? 0
                updatedDay.representativeAssetIdentifier = info?.representativeAssetIdentifier
                return updatedDay
            }

            monthData = MonthData(year: year, month: month, days: updatedDays)

            // Update UI on main thread
            DispatchQueue.main.async {
                self.currentMonth = monthData
                self.isLoading = false
            }
        }
    }

    /// Check if a date is today
    func isToday(_ date: Date) -> Bool {
        calendarManager.isToday(date)
    }

    /// Get weekday symbols
    func weekdaySymbols() -> [String] {
        calendarManager.weekdaySymbols()
    }

    /// Get media items for a specific day
    func getMediaItems(for day: CalendarDay) -> [MediaItem] {
        photoLibraryManager.fetchMedia(for: day.date)
    }
}
