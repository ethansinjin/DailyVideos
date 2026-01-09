# DailyVideos Testing Plan

This document outlines comprehensive unit tests and UI tests for the DailyVideos iOS app.

## Status
🚧 **In Progress** — implemented tests: CalendarDay, MonthData, CalendarManager, CalendarViewModel, NotificationManager, and video generation models, plus UI test suites. Remaining areas include pinned media managers, preferences, photo library integration, and video generation services/view models.

## Prerequisites

Before executing this plan:
1. Create a Unit Test target: `DailyVideosTests`
2. Create a UI Test target: `DailyVideosUITests`
3. Ensure test targets have access to app code (mark classes as `public` or use `@testable import`)

---

## Part 1: Unit Tests

Unit tests validate the business logic, data models, services, and view models in isolation.

### 1.1 Model Tests

#### MediaItemTests.swift
- **Test MediaItem initialization from PHAsset**
  - Verify correct assetIdentifier assignment
  - Verify correct date assignment (including nil creationDate handling)
  - Verify correct mediaType for video assets
  - Verify correct mediaType for Live Photo assets
  - Verify duration is set for video assets
  - Verify duration is nil for Live Photo assets

- **Test MediaItem.asset property**
  - Verify asset fetching with valid identifier returns PHAsset
  - Verify asset fetching with invalid identifier returns nil
  - Verify asset is fetched on-demand (not cached)

#### CalendarDayTests.swift
- **Test CalendarDay initialization**
  - Verify date, day, and isInCurrentMonth are set correctly
  - Verify default mediaCount is 0
  - Verify default representativeAssetIdentifier is nil

- **Test CalendarDay computed properties**
  - Verify hasMedia returns false when mediaCount is 0
  - Verify hasMedia returns true when mediaCount > 0
  - Verify id returns the date (stable identifier)

- **Test CalendarDay mutability**
  - Verify mediaCount can be updated
  - Verify representativeAssetIdentifier can be updated

#### MonthDataTests.swift
- **Test MonthData initialization**
  - Verify year, month, and days array are stored correctly
  - Verify days array can be empty

- **Test MonthData.monthName property**
  - Verify correct month name for each month (January-December)
  - Verify formatting is correct (full month name)

- **Test MonthData.displayString property**
  - Verify format is "{Month} {Year}" (e.g., "January 2024")
  - Verify correct output for various year/month combinations

#### PreferredMediaTests.swift
- **Test PreferredMedia initialization**
  - Verify date is stored correctly
  - Verify assetIdentifier is stored correctly
  - Verify selectedAt defaults to current time
  - Verify selectedAt can be set explicitly

- **Test PreferredMedia SwiftData attributes**
  - Verify date has unique constraint
  - Verify all required fields are non-optional

### 1.2 Service/Manager Tests

#### CalendarManagerTests.swift
- **Test singleton pattern**
  - Verify CalendarManager.shared returns same instance

- **Test currentMonth()**
  - Verify returns current year and month
  - Verify year is in valid range (e.g., 2000-2100)
  - Verify month is in range 1-12

- **Test nextMonth(from:)**
  - Verify January → February (same year)
  - Verify December → January (next year)
  - Verify mid-year transitions (e.g., June → July)
  - Verify year increments correctly at year boundary

- **Test previousMonth(from:)**
  - Verify February → January (same year)
  - Verify January → December (previous year)
  - Verify mid-year transitions (e.g., July → June)
  - Verify year decrements correctly at year boundary

- **Test generateMonth(year:month:)**
  - Verify days array is not empty
  - Verify days array length is 42 (6 weeks × 7 days)
  - Verify first day of month has correct weekday
  - Verify correct number of current month days
  - Verify correct number of padding days (previous month)
  - Verify correct number of padding days (next month)
  - Verify padding days have isInCurrentMonth = false
  - Verify current month days have isInCurrentMonth = true
  - Verify day numbers are sequential for padding days
  - Verify day numbers are 1...N for current month
  - Test edge cases:
    - Month starting on Sunday (no leading padding)
    - Month starting on Saturday (maximum leading padding)
    - 28-day February (non-leap year)
    - 29-day February (leap year)
    - 30-day months
    - 31-day months

- **Test isToday(_:)**
  - Verify returns true for current date
  - Verify returns false for yesterday
  - Verify returns false for tomorrow
  - Verify returns false for dates in different years
  - Verify handles timezone correctly

- **Test weekdaySymbols()**
  - Verify returns 7 symbols
  - Verify symbols are in order (Sun-Sat or locale-specific)
  - Verify symbols are short form (e.g., "Sun" not "Sunday")

#### PhotoLibraryManagerTests.swift
*Note: These tests require mocking PHPhotoLibrary or using a test photo library*

- **Test singleton pattern**
  - Verify PhotoLibraryManager.shared returns same instance

- **Test requestPermission(completion:)**
  - Verify completion is called on main thread
  - Verify permissionStatus is updated
  - Verify completion receives true for .authorized status
  - Verify completion receives true for .limited status
  - Verify completion receives false for .denied status
  - Verify completion receives false for .restricted status

- **Test permissionStatus updates**
  - Verify permissionStatus is @Published
  - Verify updatePermissionStatus sets correct status
  - Verify updates happen on main thread

- **Test fetchMedia(for:)**
  - Verify returns empty array when no media exists
  - Verify returns only videos for date with videos
  - Verify returns only Live Photos for date with Live Photos
  - Verify returns both videos and Live Photos when both exist
  - Verify filters by date correctly (start and end of day)
  - Verify results are sorted by date (newest first)
  - Verify MediaItem objects have correct properties

- **Test fetchMediaInfo(for:month:)**
  - Verify returns empty dictionary for month with no media
  - Verify keys are normalized to start of day
  - Verify DayMediaInfo has correct count
  - Verify DayMediaInfo has representativeAssetIdentifier
  - Verify fetches both videos and Live Photos
  - Verify groups media by day correctly

- **Test fetchMediaCounts(for:month:)**
  - Verify returns dictionary of date → count
  - Verify counts match actual media items
  - Verify returns empty dictionary for month with no media

- **Test getThumbnail(for:size:completion:)**
  - Verify completion is called
  - Verify completion is on main thread
  - Verify returns nil for invalid asset
  - Verify returns UIImage for valid asset
  - Verify caches thumbnail after first fetch
  - Verify cache is used on subsequent requests
  - Verify size parameter is respected

- **Test getThumbnail(for:size:completion:) [asset identifier overload]**
  - Same tests as above but using asset identifier

- **Test clearCache()**
  - Verify cache is cleared
  - Verify subsequent requests re-fetch thumbnails

- **Test selectDefaultRepresentativeAsset(from:)**
  - Verify returns nil for empty array
  - Verify prioritizes video over Live Photo
  - Verify prioritizes Live Photo over regular photo
  - Verify selects chronologically first when same media type
  - Verify handles mixed media types correctly
  - Verify handles assets without creation dates

- **Test selectDefaultRepresentativeMedia(from:)**
  - Same priority tests as selectDefaultRepresentativeAsset
  - Verify works with MediaItem array instead of PHAsset array

#### PreferencesManagerTests.swift
*Note: These tests require a test ModelContext or mocked SwiftData*

- **Test singleton pattern**
  - Verify PreferencesManager.shared returns same instance

- **Test setModelContext(_:)**
  - Verify context is stored
  - Verify subsequent operations use the context

- **Test setPreferredMedia(for:assetIdentifier:)**
  - Verify creates new PreferredMedia when none exists
  - Verify updates existing PreferredMedia when one exists
  - Verify normalizes date to start of day
  - Verify updates selectedAt timestamp
  - Verify saves context
  - Verify handles nil modelContext gracefully

- **Test getPreferredMedia(for:)**
  - Verify returns nil when no preference exists
  - Verify returns assetIdentifier when preference exists
  - Verify normalizes date to start of day for lookup
  - Verify returns most recently set preference
  - Verify handles nil modelContext gracefully

- **Test removePreferredMedia(for:)**
  - Verify removes existing preference
  - Verify does nothing when no preference exists
  - Verify saves context after deletion
  - Verify normalizes date to start of day
  - Verify handles nil modelContext gracefully

- **Test cleanupPreferences(olderThan:)**
  - Verify .all removes all preferences
  - Verify .olderThanOneYear removes only old preferences
  - Verify .olderThanTwoYears removes only old preferences
  - Verify returns correct count of deleted items
  - Verify saves context after cleanup
  - Verify recent preferences are not deleted
  - Verify handles nil modelContext gracefully

- **Test getPreferenceCount()**
  - Verify returns 0 when no preferences exist
  - Verify returns correct count after adding preferences
  - Verify count updates after deletions
  - Verify handles nil modelContext gracefully

#### NotificationManagerTests.swift
- **Test singleton pattern**
  - Verify NotificationManager.shared returns same instance

- **Test areNotificationsEnabled getter/setter**
  - Verify default value is false
  - Verify setter updates UserDefaults
  - Verify getter reads from UserDefaults
  - Verify value persists across manager instances

- **Test notificationTime getter/setter**
  - Verify default time is 8:00 PM
  - Verify setter updates UserDefaults
  - Verify getter reads from UserDefaults
  - Verify value persists across manager instances
  - Verify handles Date to TimeInterval conversion

- **Test requestPermission(completion:)**
  - Verify completion is called on main thread
  - Verify completion receives true when granted
  - Verify completion receives false when denied

- **Test checkAuthorizationStatus(completion:)**
  - Verify completion is called on main thread
  - Verify completion receives correct status

- **Test scheduleDailyReminder()**
  - Verify notification is scheduled when enabled
  - Verify notification is not scheduled when disabled
  - Verify cancels existing notifications first
  - Verify notification has correct content (title, body)
  - Verify notification trigger matches saved time
  - Verify trigger repeats daily
  - Verify notification identifier is correct

- **Test cancelNotifications()**
  - Verify removes pending notifications
  - Verify removes notification with correct identifier

- **Test updateNotificationSchedule()**
  - Verify schedules notification when enabled
  - Verify cancels notification when disabled

### 1.3 ViewModel Tests

#### CalendarViewModelTests.swift
- **Test initialization**
  - Verify currentMonth is set to current month
  - Verify selectedDay is nil initially
  - Verify isLoading starts as false
  - Verify permissionStatus is set correctly
  - Verify requestPermissionAndLoadMedia is called

- **Test goToNextMonth()**
  - Verify currentMonth updates to next month
  - Verify year increments at December → January
  - Verify loadCurrentMonth is called
  - Verify @Published property triggers update

- **Test goToPreviousMonth()**
  - Verify currentMonth updates to previous month
  - Verify year decrements at January → December
  - Verify loadCurrentMonth is called
  - Verify @Published property triggers update

- **Test goToToday()**
  - Verify currentMonth updates to current month
  - Verify works when currently viewing past month
  - Verify works when currently viewing future month
  - Verify loadCurrentMonth is called

- **Test selectDay(_:)**
  - Verify selectedDay is set
  - Verify @Published property triggers update

- **Test refreshMediaData()**
  - Verify calls loadCurrentMonth
  - Verify isLoading is set during refresh

- **Test loadCurrentMonth()**
  - Verify isLoading is true during load
  - Verify isLoading is false after load
  - Verify currentMonth is updated with media counts
  - Verify updates happen on main thread
  - Verify background thread is used for heavy operations
  - Verify days have correct mediaCount values
  - Verify days have correct representativeAssetIdentifier values

- **Test isToday(_:)**
  - Verify delegates to CalendarManager
  - Verify returns correct result

- **Test weekdaySymbols()**
  - Verify delegates to CalendarManager
  - Verify returns correct symbols

- **Test getMediaItems(for:)**
  - Verify delegates to PhotoLibraryManager
  - Verify returns media for correct day
  - Verify returns empty array for days without media

---

## Part 2: UI Tests

UI tests validate the user interface, user interactions, and end-to-end workflows.

### 2.1 Calendar View Tests

#### CalendarViewUITests.swift
- **Test initial app launch**
  - Verify calendar view appears
  - Verify current month header is displayed
  - Verify day of week labels appear (Sun-Sat)
  - Verify calendar grid is visible
  - Verify navigation buttons appear (< >)
  - Verify "Today" button appears

- **Test permission request flow**
  - Verify permission alert appears on first launch
  - Verify tapping "Allow" grants permission
  - Verify tapping "Don't Allow" shows permission request view
  - Verify permission request view has explanation text
  - Verify "Open Settings" button appears when denied

- **Test calendar grid layout**
  - Verify 7 columns (days of week)
  - Verify 5-6 rows (weeks)
  - Verify day cells are tappable
  - Verify current day has special visual indicator
  - Verify days outside current month are dimmed

- **Test month navigation**
  - Verify tapping ">" goes to next month
  - Verify tapping "<" goes to previous month
  - Verify month header updates correctly
  - Verify year updates at December/January boundary
  - Verify calendar grid updates with new days

- **Test "Today" button**
  - Verify tapping "Today" returns to current month
  - Verify works from past months
  - Verify works from future months
  - Verify current day is highlighted

- **Test day selection**
  - Verify tapping day cell shows detail view
  - Verify day detail view displays correct date
  - Verify day detail view shows media (if exists)
  - Verify tapping outside dismisses detail view

- **Test days with media indicators**
  - Verify days with media show visual indicator
  - Verify media count badge appears when count > 1
  - Verify thumbnail appears (if enabled)
  - Verify days without media have blank appearance

- **Test scrolling through multiple months**
  - Verify can navigate multiple months forward
  - Verify can navigate multiple months backward
  - Verify performance is acceptable (no lag)
  - Verify media counts update for each month

### 2.2 Day Detail View Tests

#### DayDetailViewUITests.swift
- **Test day detail view appearance**
  - Verify detail view appears when day is tapped
  - Verify date header is displayed prominently
  - Verify close/back button is present
  - Verify media grid is visible

- **Test empty day detail**
  - Verify empty state message appears
  - Verify message is user-friendly
  - Verify no media grid when empty

- **Test day with single media item**
  - Verify single media item is displayed
  - Verify thumbnail is visible
  - Verify play icon overlay for videos
  - Verify Live Photo badge for Live Photos
  - Verify tapping media opens full screen viewer

- **Test day with multiple media items**
  - Verify all media items are displayed in grid
  - Verify media count is correct
  - Verify grid layout is organized
  - Verify scrolling works for many items

- **Test media selection/preference**
  - Verify long-press or tap-hold on media item shows options
  - Verify "Set as Preferred" option appears
  - Verify tapping option updates preference
  - Verify calendar view updates with new thumbnail

- **Test navigation**
  - Verify tapping close button dismisses view
  - Verify swipe down gesture dismisses view (if supported)

### 2.3 Media Detail View Tests

#### MediaDetailViewUITests.swift
- **Test media viewer appearance**
  - Verify full screen media viewer appears
  - Verify close button is visible
  - Verify media fills screen appropriately

- **Test video playback**
  - Verify video player appears for video media
  - Verify play/pause controls are visible
  - Verify tapping play starts video
  - Verify tapping pause stops video
  - Verify progress bar updates during playback
  - Verify video can be scrubbed

- **Test Live Photo playback**
  - Verify Live Photo displays static image initially
  - Verify long-press activates Live Photo animation
  - Verify releasing stops animation

- **Test navigation between media**
  - Verify swipe left shows next media (if exists)
  - Verify swipe right shows previous media (if exists)
  - Verify navigation wraps or stops at boundaries
  - Verify media index/count indicator updates

- **Test media metadata**
  - Verify date/time information is displayed
  - Verify media type indicator (video/Live Photo)
  - Verify duration display for videos

- **Test share functionality** (if implemented)
  - Verify share button is visible
  - Verify tapping share shows system share sheet
  - Verify can select share destination

- **Test closing media viewer**
  - Verify tapping close button returns to day detail
  - Verify swipe down dismisses viewer (if supported)

### 2.4 Settings View Tests

#### SettingsViewUITests.swift
- **Test settings view access**
  - Verify settings button/icon is accessible
  - Verify tapping opens settings view

- **Test notification settings**
  - Verify notification toggle appears
  - Verify time picker appears when enabled
  - Verify toggling on requests notification permission
  - Verify toggling off disables notifications
  - Verify time selection updates notification schedule

- **Test preference cleanup**
  - Verify cleanup section appears
  - Verify cleanup options are displayed (1 year, 2 years, all)
  - Verify tapping cleanup option shows confirmation
  - Verify confirming cleanup removes preferences
  - Verify preference count updates after cleanup

- **Test photo library permission**
  - Verify current permission status is displayed
  - Verify "Open Settings" button appears if denied
  - Verify tapping button opens system Settings app

### 2.5 Permission Request View Tests

#### PermissionRequestViewUITests.swift
- **Test permission request appearance**
  - Verify view appears when permission denied
  - Verify explanation text is clear and friendly
  - Verify icon/image is displayed

- **Test permission actions**
  - Verify "Open Settings" button is visible
  - Verify tapping button opens system Settings app
  - Verify returning from Settings updates permission status

- **Test permission granted flow**
  - Verify view dismisses when permission is granted
  - Verify calendar view loads media after permission granted

### 2.6 Accessibility Tests

#### AccessibilityUITests.swift
- **Test VoiceOver support**
  - Verify all buttons have accessibility labels
  - Verify day cells have descriptive labels (e.g., "January 1, 2 videos")
  - Verify media items have labels (e.g., "Video, January 1, 10:30 AM")
  - Verify navigation is logical with VoiceOver

- **Test Dynamic Type**
  - Verify text scales with system font size
  - Verify layout adjusts appropriately
  - Verify no text truncation at larger sizes

- **Test Color Contrast**
  - Verify sufficient contrast ratios
  - Verify interactive elements are distinguishable

- **Test Reduce Motion**
  - Verify animations respect reduce motion setting
  - Verify transitions are still functional

### 2.7 Performance Tests

#### PerformanceUITests.swift
- **Test app launch time**
  - Verify app launches within acceptable time
  - Verify calendar view appears quickly

- **Test calendar rendering performance**
  - Verify month transitions are smooth
  - Verify no dropped frames during scrolling
  - Verify thumbnail loading doesn't block UI

- **Test large photo library handling**
  - Verify app handles 1000+ media items
  - Verify app handles 10,000+ media items
  - Verify memory usage stays reasonable
  - Verify no crashes with large datasets

- **Test background thread usage**
  - Verify media fetching happens off main thread
  - Verify UI remains responsive during heavy operations
  - Verify thumbnail loading is asynchronous

### 2.8 Edge Case Tests

#### EdgeCaseUITests.swift
- **Test empty photo library**
  - Verify app handles no media gracefully
  - Verify empty state messages appear
  - Verify calendar still navigable

- **Test date boundaries**
  - Verify year 2000 displays correctly
  - Verify year 2100 displays correctly
  - Verify leap year February has 29 days
  - Verify non-leap year February has 28 days

- **Test timezone changes**
  - Verify media displays in correct timezone
  - Verify date boundaries are correct across timezones

- **Test orientation changes**
  - Verify layout adapts to landscape orientation
  - Verify layout adapts to portrait orientation
  - Verify no data loss during rotation

- **Test app backgrounding/foregrounding**
  - Verify state is preserved when backgrounded
  - Verify media is refreshed when foregrounded
  - Verify selected day persists

- **Test memory warnings**
  - Verify app responds to memory warnings
  - Verify cache is cleared appropriately
  - Verify no crashes under memory pressure

### 2.9 Integration Tests

#### IntegrationUITests.swift
- **Test end-to-end user flow: View media for today**
  1. Launch app
  2. Grant photo library permission
  3. Verify today is highlighted
  4. Tap today's date
  5. Verify day detail shows today's media
  6. Tap media item
  7. Verify full screen viewer appears
  8. Close viewer
  9. Verify returns to day detail

- **Test end-to-end user flow: Browse past months**
  1. Launch app
  2. Navigate back 3 months
  3. Verify month header updates
  4. Tap day with media
  5. Verify media from that month appears
  6. Tap "Today" button
  7. Verify returns to current month

- **Test end-to-end user flow: Set preferred media**
  1. Navigate to day with multiple media items
  2. Tap day to open detail view
  3. Long-press a media item
  4. Select "Set as Preferred"
  5. Close day detail
  6. Verify calendar cell shows selected thumbnail
  7. Navigate away and back
  8. Verify preference persists

- **Test end-to-end user flow: Configure notifications**
  1. Open settings
  2. Enable notifications
  3. Grant notification permission
  4. Set notification time to 9:00 PM
  5. Close settings
  6. Verify notification is scheduled (check system settings)

- **Test end-to-end user flow: Cleanup old preferences**
  1. Open settings
  2. View preference count
  3. Tap cleanup "Older than 1 year"
  4. Confirm cleanup
  5. Verify count updates
  6. Close settings
  7. Verify old preferences removed from calendar

---

## Testing Infrastructure Requirements

### Test Data Setup
- **Mock Photo Library**: Create sample PHAssets for testing
- **Test Calendar Dates**: Define standard test dates (leap years, boundaries, etc.)
- **Test SwiftData Context**: Set up in-memory ModelContext for preferences testing
- **Mock Notifications**: Mock UNUserNotificationCenter for notification tests

### Test Helpers
- **DateHelpers**: Create dates easily for tests
- **MediaItemFactory**: Generate test MediaItem instances
- **CalendarDayFactory**: Generate test CalendarDay instances
- **AssertHelpers**: Custom assertions for common validations

### CI/CD Integration
- Run unit tests on every commit
- Run UI tests on pull requests
- Generate code coverage reports
- Fail builds if coverage drops below threshold (e.g., 80%)

### Performance Baselines
- Establish baseline metrics for:
  - App launch time
  - Month navigation time
  - Media loading time
  - Memory usage
- Alert on regressions

---

## Test Execution Priority

### Priority 1 (Critical - Must Pass)
- CalendarManager date logic tests
- PhotoLibraryManager media fetching tests
- CalendarViewModel state management tests
- Basic calendar navigation UI tests
- Permission handling tests

### Priority 2 (High - Should Pass)
- PreferencesManager CRUD tests
- NotificationManager scheduling tests
- Day detail view tests
- Media viewer tests
- Accessibility tests

### Priority 3 (Medium - Nice to Have)
- Edge case tests
- Performance tests
- Integration tests
- Cleanup functionality tests

---

## Success Criteria

The testing plan is considered complete when:
- [ ] All Priority 1 tests are implemented and passing
- [ ] Code coverage is ≥ 80% for models, services, and view models
- [ ] All critical user flows have UI tests
- [ ] Tests run successfully in CI/CD pipeline
- [ ] No memory leaks detected in performance tests
- [ ] Accessibility tests pass with VoiceOver enabled

---

## Notes for Test Implementation

1. **Mocking Strategy**: Use dependency injection for services to enable testing
2. **Async Testing**: Use XCTestExpectation for async operations
3. **Photo Library**: Consider using a test photo library or mocking PHPhotoLibrary
4. **SwiftData**: Use in-memory ModelContainer for tests
5. **UI Tests**: Use Page Object pattern to organize UI test code
6. **Test Isolation**: Ensure tests don't depend on each other
7. **Cleanup**: Reset state between tests (clear UserDefaults, caches, etc.)

---

## Future Test Enhancements

- Snapshot testing for UI regression detection
- Property-based testing for date calculations
- Stress testing with large datasets
- Localization testing for different languages
- Network condition testing (for iCloud sync in future)
