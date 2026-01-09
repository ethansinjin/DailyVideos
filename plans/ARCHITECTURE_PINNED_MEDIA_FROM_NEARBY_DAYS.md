# Architecture Plan: Pin Media from Other Days Feature

## Status
✅ **Complete** — implemented in codebase (PinnedMedia model/manager, selection UI, badges, context menu removal, calendar indicators, settings cleanup).

## Overview
This document outlines the architecture for a new "cheat day" feature that allows users to pin media from nearby dates to display on days that may have no media or insufficient media. This is conceptually different from the existing "preferred media" feature, which selects a representative from media that already exists on a given day.

## Feature Requirements

### Core Functionality
1. **Pin media from nearby dates** to any day (regardless of whether media exists)
2. **Visual distinction** - pinned media from other days should have a distinct icon/badge
3. **Access from day detail** - available from DayDetailView for any day (empty or not)
4. **Date range selection** - allow browsing nearby dates (e.g., ±7 days) to find media
5. **Context menu removal** - long press on pinned media shows option to remove pin
6. **Calendar display** - pinned media appears on calendar cells like native media
7. **Persistent storage** - pin relationships saved and restored across app launches

### User Flow
1. User taps on a day (with or without existing media)
2. Day detail view shows a "Pin media from another day" button
3. Button opens a date picker/browser showing nearby dates with available media
4. User selects a source date, sees media from that date
5. User selects specific media item to pin
6. Media is pinned and appears on the target day with a distinct "cross-date pin" badge
7. User can long-press the pinned media to unpin via context menu

### Visual Indicators
- **Cross-date pinned media**: Special badge (e.g., calendar icon) indicating media is from another day
- **Preferred media** (existing): Pin badge indicating user's preferred media from that day's native media
- Both badges can coexist if a cross-date pinned item is also marked as preferred

---

## Architecture Changes

### 1. Data Models

#### New Model: PinnedMedia.swift
```swift
import Foundation
import SwiftData

/// SwiftData model for storing media pinned from other days
@Model
class PinnedMedia {
    /// The target day where media should appear (normalized to start of day)
    @Attribute(.unique) var targetDate: Date

    /// PHAsset local identifier for the pinned media
    var assetIdentifier: String

    /// The source date where the media actually originates from
    var sourceDate: Date

    /// Timestamp when the pin was created
    var pinnedAt: Date

    init(targetDate: Date, assetIdentifier: String, sourceDate: Date, pinnedAt: Date = Date()) {
        self.targetDate = targetDate
        self.assetIdentifier = assetIdentifier
        self.sourceDate = sourceDate
        self.pinnedAt = pinnedAt
    }
}
```

**Key Design Decisions:**
- **Separate from PreferredMedia**: While related, cross-date pinning is conceptually different from selecting preferred media from a day's native content
- **Store source date**: Needed to show "from Jan 15" indicator and for unpinning logic
- **One pin per day**: Using `@Attribute(.unique)` on `targetDate` means only one cross-date pin per day (can be relaxed if multiple pins needed)
- **Normalized dates**: Both dates normalized to start of day for consistency

#### Enhancements to MediaItem.swift
```swift
struct MediaItem: Identifiable {
    // ... existing properties ...

    /// Context for how this media appears on a specific day
    var displayContext: MediaDisplayContext = .native
}

enum MediaDisplayContext: Equatable {
    case native                           // Media from this day
    case pinnedFromOtherDay(Date)        // Cross-date pin (with source date)
}
```

**Purpose:**
- Track whether media is native to a day or pinned from elsewhere
- Display appropriate badge/icon based on context
- Can be computed when fetching media for a day

---

### 2. Services & Managers

#### New Service: PinnedMediaManager.swift
```swift
import Foundation
import SwiftData

class PinnedMediaManager {
    static let shared = PinnedMediaManager()

    private var modelContext: ModelContext?

    private init() {}

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Pin Management

    /// Pin media from a source date to a target date
    func pinMedia(assetIdentifier: String, sourceDate: Date, to targetDate: Date)

    /// Get pinned media for a specific target date
    func getPinnedMedia(for targetDate: Date) -> PinnedMedia?

    /// Remove pinned media for a target date
    func removePinnedMedia(for targetDate: Date)

    /// Check if specific media is pinned to a target date
    func isPinned(assetIdentifier: String, to targetDate: Date) -> Bool

    /// Get all pinned media (for management/cleanup)
    func getAllPinnedMedia() -> [PinnedMedia]

    // MARK: - Cleanup

    /// Remove pins older than specified timeframe
    func cleanupPins(olderThan timeframe: CleanupTimeframe) -> Int

    /// Remove pins for assets that no longer exist in photo library
    func cleanupOrphanedPins() -> Int
}
```

**Responsibilities:**
- CRUD operations for pinned media relationships
- Validation (ensure asset exists, dates are valid)
- Cleanup of old or orphaned pins
- Thread-safe access to SwiftData model context

#### Enhancements to PhotoLibraryManager.swift
```swift
class PhotoLibraryManager {
    // ... existing methods ...

    /// Fetch media for a date range (for pin selection UI)
    func fetchMediaForDateRange(from startDate: Date, to endDate: Date) -> [Date: [MediaItem]]

    /// Fetch media for a specific day, including pinned media from other days
    func fetchMediaForDate(date: Date, includePinnedMedia: Bool = true) -> [MediaItem]

    /// Get nearby dates that have media (for pin source selection)
    func getDatesWithMedia(around date: Date, within days: Int = 7) -> [Date]
}
```

**Key Changes:**
- When fetching media for a day, check `PinnedMediaManager` for cross-date pins
- Merge pinned media with native media, setting appropriate `displayContext`
- Provide methods for browsing nearby dates during pin selection

#### Enhancements to CalendarManager.swift
```swift
class CalendarManager {
    // ... existing methods ...

    /// Get date range for pin selection (e.g., ±7 days from target)
    func getPinSelectionDateRange(around date: Date, dayRadius: Int = 7) -> (start: Date, end: Date)

    /// Check if a date is within reasonable pin range
    func isValidPinSourceDate(_ sourceDate: Date, for targetDate: Date) -> Bool
}
```

---

### 3. ViewModels

#### Enhancements to CalendarViewModel.swift
```swift
class CalendarViewModel: ObservableObject {
    // ... existing properties ...

    @Published var showPinMediaSheet = false
    @Published var pinningTargetDate: Date?
    @Published var nearbyMediaByDate: [Date: [MediaItem]] = [:]
    @Published var selectedPinSourceDate: Date?

    // MARK: - Pin Media Actions

    /// Start pin media flow for a specific date
    func startPinningMedia(for date: Date)

    /// Load nearby dates with media for pin selection
    func loadNearbyMediaForPinning(around date: Date, days: Int = 7)

    /// Pin selected media to target date
    func pinMedia(assetIdentifier: String, sourceDate: Date, to targetDate: Date)

    /// Remove pinned media from a date
    func removePinnedMedia(for date: Date)

    /// Check if media is pinned from another day
    func getPinSourceDate(for assetIdentifier: String, on targetDate: Date) -> Date?
}
```

**State Management:**
- Track which day user is pinning media to
- Cache nearby dates and their media for selection UI
- Handle pin/unpin operations and refresh calendar

---

### 4. Views

#### New View: PinMediaSelectionView.swift
```swift
struct PinMediaSelectionView: View {
    let targetDate: Date
    let onPin: (String, Date) -> Void
    let onCancel: () -> Void

    @State private var selectedSourceDate: Date?
    @State private var nearbyDates: [Date] = []
    @State private var mediaByDate: [Date: [MediaItem]] = [:]
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Target date header
                targetDateHeader

                // Date selection (horizontal scroll or list)
                dateSelectionSection

                // Media grid for selected date
                if let sourceDate = selectedSourceDate {
                    mediaGridSection(for: sourceDate)
                } else {
                    placeholderSection
                }
            }
            .navigationTitle("Pin Media")
            .toolbar { /* Cancel button */ }
        }
    }
}
```

**Features:**
- Shows target date prominently
- Horizontal scrollable list of nearby dates with media
- Grid of media from selected source date
- Tap media to pin it
- Visual feedback (date range, media count per date)

#### Enhancements to DayDetailView.swift
```swift
struct DayDetailView: View {
    // ... existing properties ...

    @State private var showPinMediaSheet = false
    @State private var showUnpinConfirmation = false
    @State private var mediaToUnpin: MediaItem?

    var body: some View {
        NavigationStack {
            VStack {
                // ... existing header ...

                if mediaItems.isEmpty {
                    emptyStateWithPinOption
                } else {
                    mediaGridWithPinOption
                }
            }
            .toolbar {
                // Add "Pin from Another Day" toolbar button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showPinMediaSheet = true
                    } label: {
                        Label("Pin Media", systemImage: "calendar.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showPinMediaSheet) {
                PinMediaSelectionView(
                    targetDate: day.date,
                    onPin: handlePin,
                    onCancel: { showPinMediaSheet = false }
                )
            }
        }
    }

    private func mediaContextMenu(for item: MediaItem) -> some View {
        Group {
            if case .pinnedFromOtherDay(let sourceDate) = item.displayContext {
                Button(role: .destructive) {
                    mediaToUnpin = item
                    showUnpinConfirmation = true
                } label: {
                    Label("Remove Pin", systemImage: "pin.slash")
                }
            }

            // ... existing preferred media option ...
        }
    }
}
```

**Changes:**
- Add "Pin Media" button in toolbar (always visible)
- Show pin media selection sheet when tapped
- Add context menu to media thumbnails
- Context menu shows "Remove Pin" for cross-date pinned media
- Confirmation alert before unpinning

#### Enhancements to MediaThumbnailView.swift
```swift
struct MediaThumbnailView: View {
    let mediaItem: MediaItem
    let showPinBadge: Bool
    let showCrossDatePinBadge: Bool  // NEW
    let pinSourceDate: Date?          // NEW

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // ... existing thumbnail image ...

            VStack(alignment: .trailing, spacing: 4) {
                // Cross-date pin badge (top priority)
                if showCrossDatePinBadge {
                    HStack(spacing: 2) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.caption2)
                        if let sourceDate = pinSourceDate {
                            Text(formatSourceDate(sourceDate))
                                .font(.caption2)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                }

                // Preferred pin badge (secondary)
                if showPinBadge {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
            .padding(8)
        }
    }
}
```

**Badge System:**
- **Cross-date pin badge**: Shows calendar icon + source date (e.g., "Jan 15")
- **Preferred pin badge**: Shows pin icon (existing feature)
- Both can display simultaneously if needed
- Badges use `.ultraThinMaterial` for clarity

#### Enhancements to DayCell.swift
```swift
struct DayCell: View {
    // ... existing properties ...
    let hasPinnedMedia: Bool  // NEW

    var body: some View {
        ZStack {
            // ... existing day number ...

            // Media indicator with pin badge if applicable
            if hasMedia {
                thumbnailIndicator
                    .overlay(alignment: .topTrailing) {
                        if hasPinnedMedia {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 8))
                                .foregroundColor(.white)
                                .padding(2)
                                .background(Color.blue.opacity(0.8))
                                .clipShape(Circle())
                        }
                    }
            }
        }
    }
}
```

**Calendar Cell Enhancement:**
- Small badge overlay on calendar cells with pinned media
- Indicates at-a-glance which days have "cheated" media

---

### 5. App Structure Updates

```
DailyVideos/
├── App/
│   └── DailyVideosApp.swift (register PinnedMediaManager context)
├── Models/
│   ├── MediaItem.swift (add displayContext)
│   ├── CalendarDay.swift
│   ├── MonthData.swift
│   ├── PreferredMedia.swift (existing)
│   └── PinnedMedia.swift (NEW)
├── ViewModels/
│   └── CalendarViewModel.swift (add pin methods)
├── Views/
│   ├── Calendar/
│   │   ├── CalendarView.swift
│   │   ├── DayCell.swift (add pin indicator)
│   │   ├── DayDetailView.swift (add pin button + context menu)
│   │   └── PinMediaSelectionView.swift (NEW)
│   └── Media/
│       └── MediaThumbnailView.swift (add cross-date badge)
├── Services/
│   ├── PhotoLibraryManager.swift (enhance with pin support)
│   ├── CalendarManager.swift (add pin date helpers)
│   ├── PreferencesManager.swift (existing)
│   └── PinnedMediaManager.swift (NEW)
└── Utilities/
    └── DateExtensions.swift (add pin-related formatters)
```

---

### 6. Implementation Phases

#### Phase 1: Data Layer (Foundation)
- [ ] Create `PinnedMedia` SwiftData model
- [ ] Implement `PinnedMediaManager` service
- [ ] Add `displayContext` to `MediaItem`
- [ ] Register `PinnedMedia` in SwiftData model container
- [ ] Add unit tests for `PinnedMediaManager`

#### Phase 2: Service Integration
- [ ] Enhance `PhotoLibraryManager.fetchMediaForDate()` to merge pinned media
- [ ] Add `PhotoLibraryManager.fetchMediaForDateRange()` for pin selection
- [ ] Add `PhotoLibraryManager.getDatesWithMedia()` for nearby dates
- [ ] Add date range helpers to `CalendarManager`
- [ ] Test merged media results (native + pinned)

#### Phase 3: ViewModel Layer
- [ ] Add pin-related state to `CalendarViewModel`
- [ ] Implement `startPinningMedia()` and `pinMedia()` methods
- [ ] Implement `removePinnedMedia()` method
- [ ] Add loading state for nearby media
- [ ] Test pin/unpin workflows

#### Phase 4: Pin Selection UI
- [ ] Create `PinMediaSelectionView` component
- [ ] Implement nearby date browser (horizontal scroll)
- [ ] Implement media grid for selected date
- [ ] Add tap-to-pin interaction
- [ ] Add loading and empty states
- [ ] Test on various screen sizes

#### Phase 5: Day Detail Enhancements
- [ ] Add "Pin Media" toolbar button to `DayDetailView`
- [ ] Integrate `PinMediaSelectionView` sheet
- [ ] Add context menu to media thumbnails
- [ ] Implement "Remove Pin" action with confirmation
- [ ] Update empty state to mention pin option
- [ ] Test pin/unpin from day detail

#### Phase 6: Visual Indicators
- [ ] Add cross-date pin badge to `MediaThumbnailView`
- [ ] Show source date on pinned media
- [ ] Add pin indicator to `DayCell` (calendar grid)
- [ ] Ensure badges work with preferred media pins
- [ ] Test badge visibility and styling
- [ ] Accessibility labels for all badges

#### Phase 7: Polish & Edge Cases
- [ ] Handle orphaned pins (asset deleted from library)
- [ ] Implement pin cleanup in settings
- [ ] Add pin statistics (total pins, date range)
- [ ] Optimize performance with many pins
- [ ] Handle timezone edge cases
- [ ] Add animations (pin/unpin feedback)
- [ ] Dark mode support for new UI elements

#### Phase 8: Testing & Documentation
- [ ] Unit tests for all pin logic
- [ ] UI tests for pin/unpin workflow
- [ ] Test with large photo libraries
- [ ] Test edge cases (no media, same-day pin attempt)
- [ ] Update user documentation
- [ ] Add code documentation

---

### 7. Key Technical Considerations

#### Data Integrity
- **Orphaned pins**: If a PHAsset is deleted from photo library, the pin becomes invalid
  - Solution: Add cleanup method to detect and remove orphaned pins
  - Check during fetch and gracefully skip invalid pins
- **Date normalization**: Always normalize dates to start of day to prevent duplicate pins
- **Concurrent access**: SwiftData handles this, but ensure all operations on main actor

#### Performance
- **Lazy loading**: Don't fetch all nearby media upfront, load as user scrolls
- **Caching**: Cache nearby dates and media during pin selection
- **Thumbnail reuse**: Leverage existing thumbnail cache for pinned media
- **Background fetching**: Fetch nearby media in background thread

#### User Experience
- **Date range selection**: Default to ±7 days, but make configurable
- **Visual clarity**: Clear distinction between native, preferred, and cross-date pins
- **Undo support**: Consider adding undo for unpin action
- **Bulk operations**: Future: pin multiple media or unpin all
- **Search**: Future: search for specific media to pin (not just browse nearby)

#### Edge Cases
- **Pin from future date**: Allow? Or restrict to past dates only?
- **Pin same day**: Prevent pinning media from the same day (redundant)
- **Multiple pins per day**: Current design allows one; easy to extend to multiple
- **Circular pins**: Not possible (one pin per target date)
- **Preferred + pinned**: Pinned media can also be marked as preferred

#### Accessibility
- **VoiceOver labels**:
  - "Pinned from January 15th"
  - "Remove pin from this day"
  - "Pin media from another day"
- **Dynamic Type**: Ensure badge text scales appropriately
- **Color blind**: Don't rely solely on color for pin indication (use icons)

#### Settings & Management
- **Settings screen additions**:
  - Total pinned media count
  - "Clean up old pins" button (older than 1 year, 2 years, all)
  - "Remove orphaned pins" button
  - Pin date range preference (±7, ±14, ±30 days)
- **Storage considerations**: Pins are lightweight (just date + asset ID), minimal storage impact

---

### 8. Data Flow Diagrams

#### Pin Media Flow
```
User taps "Pin Media" on Day Detail
    ↓
CalendarViewModel.startPinningMedia(for: date)
    ↓
PinMediaSelectionView opens
    ↓
PhotoLibraryManager.getDatesWithMedia(around: date, within: 7)
    ↓
User selects source date
    ↓
PhotoLibraryManager.fetchMediaForDate(sourceDate)
    ↓
User selects media
    ↓
CalendarViewModel.pinMedia(assetID, sourceDate, targetDate)
    ↓
PinnedMediaManager.pinMedia(assetID, sourceDate, to: targetDate)
    ↓
SwiftData saves PinnedMedia record
    ↓
CalendarViewModel.refreshMediaData()
    ↓
Calendar updates, day shows pinned media
```

#### Fetch Media with Pins Flow
```
CalendarViewModel.loadMonth(year, month)
    ↓
PhotoLibraryManager.fetchMediaForDate(date)
    ↓
Fetch native media from Photos library
    ↓
PinnedMediaManager.getPinnedMedia(for: date)
    ↓
If pinned media exists:
    ↓
Fetch PHAsset for pinned assetIdentifier
    ↓
Create MediaItem with displayContext = .pinnedFromOtherDay(sourceDate)
    ↓
Merge pinned media with native media
    ↓
Return combined [MediaItem] array
```

---

### 9. API Design Examples

#### Pin a media item
```swift
// From DayDetailView or CalendarViewModel
PinnedMediaManager.shared.pinMedia(
    assetIdentifier: "ABC-123-XYZ",
    sourceDate: Date(2024, 1, 15),
    to: Date(2024, 1, 20)
)
```

#### Fetch media including pins
```swift
// PhotoLibraryManager automatically merges
let mediaItems = PhotoLibraryManager.shared.fetchMediaForDate(
    date: targetDate,
    includePinnedMedia: true  // default
)

// Check display context
for item in mediaItems {
    switch item.displayContext {
    case .native:
        print("Native media")
    case .pinnedFromOtherDay(let sourceDate):
        print("Pinned from \(sourceDate)")
    }
}
```

#### Remove a pin
```swift
// From context menu action
PinnedMediaManager.shared.removePinnedMedia(for: targetDate)

// Or with confirmation
showUnpinConfirmation(for: targetDate) { confirmed in
    if confirmed {
        PinnedMediaManager.shared.removePinnedMedia(for: targetDate)
        viewModel.refreshMediaData()
    }
}
```

---

### 10. Testing Strategy

#### Unit Tests
- `PinnedMediaManager`:
  - Pin creation
  - Pin retrieval
  - Pin removal
  - Duplicate handling (update existing)
  - Cleanup operations
- `PhotoLibraryManager`:
  - Merged media results (native + pinned)
  - Date range fetching
  - Nearby dates with media
- Date normalization edge cases

#### Integration Tests
- Pin → Display on calendar → Unpin lifecycle
- Preferred media + cross-date pin (both badges)
- Orphaned pin cleanup (asset deleted)
- Large number of pins (performance)

#### UI Tests
- Complete pin flow (tap pin button → select date → select media → see on calendar)
- Unpin via context menu
- Pin badge visibility on calendar and detail
- Empty state with pin option
- Pin selection sheet behavior

---

### 11. Future Enhancements

#### Advanced Pin Management
- **Multiple pins per day**: Allow pinning several media items from different dates
- **Pin priorities**: Order pinned media (which shows first)
- **Bulk operations**: Pin/unpin multiple days at once
- **Templates**: Save common pin patterns ("fill all empty days in month")

#### Enhanced Discovery
- **Smart suggestions**: AI/ML suggests media to pin based on content similarity
- **Search**: Search entire library to pin specific memory
- **Filters**: Filter pin candidates by location, people, media type
- **Timeline view**: Visualize pins in a timeline/graph

#### Sharing & Social
- **Share pins**: Export calendar view showing which days used pins
- **Pin explanations**: Add notes explaining why media was pinned
- **Challenges**: "No-pin challenge" - try to fill calendar without cheating

#### Analytics
- **Pin statistics**: Track most-pinned-from dates, pin frequency
- **Coverage metrics**: Days with native media vs. pinned media
- **Trends**: Visualize pin patterns over time

---

## Summary

This architecture plan adds a comprehensive "pin media from other days" feature that:

1. **Stores cross-date pin relationships** in SwiftData via `PinnedMedia` model
2. **Manages pins** through dedicated `PinnedMediaManager` service
3. **Integrates seamlessly** with existing preferred media system
4. **Provides clear visual distinction** between native, preferred, and cross-date pinned media
5. **Offers intuitive UI** for browsing nearby dates and selecting media to pin
6. **Supports context menu** for easy unpinning
7. **Maintains performance** with lazy loading and caching
8. **Handles edge cases** like orphaned pins and data integrity

The implementation is phased to build foundation first (data layer), then services, then UI, ensuring each layer is tested before moving to the next.

The feature enhances the app's utility for users who want to maintain a consistent daily media presence even when some days lack original content, while being transparent about which media is "borrowed" from other dates.
