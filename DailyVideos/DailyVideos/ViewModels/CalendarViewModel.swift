import Foundation
import SwiftUI
import Combine
internal import Photos

/// ViewModel for managing calendar state
class CalendarViewModel: ObservableObject {
    @Published var currentMonth: MonthData
    @Published var selectedDay: CalendarDay?
    @Published var permissionStatus: PHAuthorizationStatus = .notDetermined
    @Published var isLoading: Bool = false

    // Pin media state
    @Published var showPinMediaSheet: Bool = false
    @Published var pinningTargetDate: Date?
    @Published var nearbyMediaByDate: [Date: [MediaItem]] = [:]
    @Published var selectedPinSourceDate: Date?
    @Published var isLoadingNearbyMedia: Bool = false

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
                updatedDay.hasPinnedMedia = info?.hasPinnedMedia ?? false
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

    // MARK: - Pin Media Actions

    /// Start pin media flow for a specific date
    func startPinningMedia(for date: Date) {
        pinningTargetDate = date
        selectedPinSourceDate = nil
        nearbyMediaByDate = [:]
        loadNearbyMediaForPinning(around: date)
        showPinMediaSheet = true
    }

    /// Load nearby dates with media for pin selection
    func loadNearbyMediaForPinning(around date: Date, days: Int = 7) {
        isLoadingNearbyMedia = true

        // Capture for background thread
        let targetDate = date

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Get dates with media in the range
            let datesWithMedia = self.photoLibraryManager.getDatesWithMedia(around: targetDate, within: days)

            // Fetch media for each date
            var mediaByDate: [Date: [MediaItem]] = [:]
            for sourceDate in datesWithMedia {
                let media = self.photoLibraryManager.fetchMedia(for: sourceDate, includePinnedMedia: false)
                if !media.isEmpty {
                    mediaByDate[sourceDate] = media
                }
            }

            // Update UI on main thread
            DispatchQueue.main.async {
                self.nearbyMediaByDate = mediaByDate
                self.isLoadingNearbyMedia = false

                // Auto-select first date if available
                if self.selectedPinSourceDate == nil, let firstDate = datesWithMedia.first {
                    self.selectedPinSourceDate = firstDate
                }
            }
        }
    }

    /// Pin selected media to target date
    func pinMedia(assetIdentifier: String, sourceDate: Date, to targetDate: Date) {
        // Validate using calendar manager
        guard calendarManager.isValidPinSourceDate(sourceDate, for: targetDate) else {
            print("⚠️ CalendarViewModel: Invalid pin source date")
            return
        }

        // Perform the pin
        PinnedMediaManager.shared.pinMedia(
            assetIdentifier: assetIdentifier,
            sourceDate: sourceDate,
            to: targetDate
        )

        // Close the sheet
        showPinMediaSheet = false

        // Refresh calendar to show the pinned media
        refreshMediaData()
    }

    /// Remove pinned media from a date
    func removePinnedMedia(for date: Date) {
        PinnedMediaManager.shared.removePinnedMedia(for: date)

        // Refresh calendar to reflect the change
        refreshMediaData()
    }

    /// Check if media is pinned from another day
    func getPinSourceDate(for assetIdentifier: String, on targetDate: Date) -> Date? {
        guard let pin = PinnedMediaManager.shared.getPinnedMedia(for: targetDate) else {
            return nil
        }

        if pin.assetIdentifier == assetIdentifier {
            return pin.sourceDate
        }

        return nil
    }

    /// Cancel pin media flow
    func cancelPinning() {
        showPinMediaSheet = false
        pinningTargetDate = nil
        selectedPinSourceDate = nil
        nearbyMediaByDate = [:]
    }
}
