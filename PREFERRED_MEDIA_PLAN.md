# Preferred Media Selection - Architecture Plan

## Overview
Enable users to choose which photo or video represents each day in the calendar view when multiple media items exist for that day.

## 1. Data Model Layer

### New SwiftData Model: `PreferredMedia`
```swift
@Model
class PreferredMedia {
    var date: Date                    // The day (normalized to start of day)
    var assetIdentifier: String       // PHAsset local identifier
    var selectedAt: Date              // Timestamp of selection

    // Unique constraint on date
}
```

**Why SwiftData?**
- Already used in the project
- Provides persistence across app launches
- Easy querying by date
- Automatic iCloud sync (if enabled later)

**Alternative considered:** `@AppStorage` with Dictionary - rejected because it doesn't scale well and harder to query

---

## 2. Service Layer

### New Service: `PreferencesManager`
```swift
class PreferencesManager {
    static let shared = PreferencesManager()

    private let modelContext: ModelContext

    // Save user's preferred media for a specific day
    func setPreferredMedia(for date: Date, assetIdentifier: String)

    // Get user's preferred media for a specific day
    func getPreferredMedia(for date: Date) -> String?

    // Remove preference (cleanup)
    func removePreferredMedia(for date: Date)

    // Cleanup old preferences
    func cleanupPreferences(olderThan timeframe: CleanupTimeframe)
}

enum CleanupTimeframe {
    case all
    case olderThanOneYear
    case olderThanTwoYears
}
```

**Integration Point:** `PhotoLibraryManager.fetchMediaInfo()`
- When building media info for a day, first check `PreferencesManager`
- If preference exists and asset is valid, use it
- Otherwise, use smart default logic (see below)

---

## 3. Smart Default Selection Logic

When no user preference exists, automatically select the representative media using this priority:

1. **Videos first** - Prefer any video over photos
2. **Live Photos second** - If no videos, prefer live photos
3. **Within each category** - Use chronological order (first created)

**Implementation:**
```swift
// In PhotoLibraryManager
func selectDefaultRepresentativeMedia(from items: [MediaItem]) -> String? {
    // Priority 1: Videos
    if let video = items.first(where: { $0.mediaType == .video }) {
        return video.assetIdentifier
    }

    // Priority 2: Live Photos
    if let livePhoto = items.first(where: { $0.mediaType == .livePhoto }) {
        return livePhoto.assetIdentifier
    }

    // Priority 3: First item chronologically
    return items.first?.assetIdentifier
}
```

---

## 4. UI/UX Design

### Visual Indicator: Pin Badge
- Use SF Symbol `"pin.fill"` to mark the preferred media
- Badge positioned in **top-right corner** of thumbnail
- Color: White with subtle shadow for visibility
- Size: Small, non-intrusive

### Selection Interaction: Long Press
- **Long press** any thumbnail in `DayDetailView`
- **Haptic feedback** on press
- Pin icon animates to new thumbnail
- **Toast/banner confirmation:** "Pinned as preferred for [date]"

**Why long press?**
- Most direct and iOS-native pattern
- No extra UI chrome needed
- Discoverable through exploration

---

## 5. Visual Design

```
┌─────────────────────────────────┐
│  DayDetailView                  │
│  January 15, 2026               │
│  5 items                        │
├─────────────────────────────────┤
│  ┌───┐  ┌───┐  ┌───┐           │
│  │📌 │  │   │  │   │           │  ← Pin on preferred
│  │ 1 │  │ 2 │  │ 3 │           │
│  └───┘  └───┘  └───┘           │
│  ┌───┐  ┌───┐                  │
│  │   │  │   │                  │
│  │ 4 │  │ 5 │                  │
│  └───┘  └───┘                  │
└─────────────────────────────────┘
```

---

## 6. Implementation Flow

### When User Selects Preferred Media:

1. **DayDetailView** detects long press on thumbnail
2. Calls `PreferencesManager.setPreferredMedia(for: day.date, assetIdentifier: item.assetIdentifier)`
3. Updates local UI state to move pin badge
4. Shows toast confirmation with haptic feedback
5. Refreshes the calendar to update the specific day cell thumbnail

### When Loading Calendar:

1. **PhotoLibraryManager.fetchMediaInfo()** queries photo library for each day
2. For each day with media:
   - Calls `PreferencesManager.getPreferredMedia(for: date)`
   - If preference exists:
     - Verify asset still exists in photo library
     - Use as `representativeAssetIdentifier`
   - If no preference or asset deleted:
     - Use smart default selection (video > live photo > chronological)
3. Returns media info with correct representative asset

### When Loading DayDetailView:

1. Fetch all media items for the day
2. Check `PreferencesManager.getPreferredMedia(for: day.date)`
3. Mark that item with pin badge in UI
4. If no preference, mark smart default with pin badge

---

## 7. Edge Cases & Error Handling

| Scenario | Handling |
|----------|----------|
| **Preferred asset deleted from library** | Fallback to smart default selection, clean up preference record |
| **Only 1 media item for day** | Show pin badge but don't allow changing (no choice to make) |
| **Date has no media** | No preference stored/shown |
| **App upgrade from version without preferences** | Graceful - no preferences exist, uses smart defaults |
| **User changes preference multiple times** | Overwrite previous preference, update `selectedAt` timestamp |
| **iCloud photo library sync issues** | Asset identifier should remain valid; verify before using |

---

## 8. File Structure

```
DailyVideos/
├── Models/
│   ├── MediaItem.swift
│   ├── CalendarDay.swift
│   ├── MonthData.swift
│   └── PreferredMedia.swift           ← NEW
├── Services/
│   ├── PhotoLibraryManager.swift     (modified)
│   ├── CalendarManager.swift
│   └── PreferencesManager.swift       ← NEW
├── Views/
│   ├── Calendar/
│   │   └── DayDetailView.swift        (modified)
│   └── Media/
│       └── MediaThumbnailView.swift   (modified - add pin badge)
└── Supporting/
    └── SettingsView.swift             (modified - add cleanup options)
```

---

## 9. Implementation Phases

### Phase 1: Core Infrastructure
- [ ] Create `PreferredMedia` SwiftData model
- [ ] Create `PreferencesManager` service
- [ ] Set up model context injection in app
- [ ] Basic save/retrieve functionality

### Phase 2: Smart Default Selection
- [ ] Implement smart default logic in `PhotoLibraryManager`
- [ ] Update `fetchMediaInfo()` to use smart defaults
- [ ] Test priority selection (video > live photo > chronological)

### Phase 3: Integration
- [ ] Modify `PhotoLibraryManager.fetchMediaInfo()` to check preferences
- [ ] Add preference lookup logic
- [ ] Add fallback logic for deleted assets

### Phase 4: UI - Visual Indicators
- [ ] Add pin badge overlay to `MediaThumbnailView`
- [ ] Show badge on preferred item in `DayDetailView`
- [ ] Add animation for pin movement

### Phase 5: UI - Selection
- [ ] Add long press gesture to thumbnails in `DayDetailView`
- [ ] Implement preference saving on long press
- [ ] Add haptic feedback
- [ ] Show confirmation toast/banner

### Phase 6: Settings - Cleanup Options
- [ ] Add "Preferred Media" section in Settings
- [ ] Add cleanup options:
  - Clear all preferences
  - Clear older than 1 year
  - Clear older than 2 years
- [ ] Implement cleanup logic in `PreferencesManager`
- [ ] Show confirmation alert before cleanup

### Phase 7: Polish & Testing
- [ ] Test edge cases (deleted assets, single item days, etc.)
- [ ] Performance testing with large preference sets
- [ ] Accessibility labels (VoiceOver support for pin badge)
- [ ] Animation polish

### Phase 8: Future Enhancements
- [ ] Settings to change smart default priority
- [ ] Bulk operations (set preferred for multiple days)
- [ ] "Reset to smart default" option per day
- [ ] Export/import preferences

---

## 10. Settings UI - Cleanup Options

### New Section in SettingsView

```
Preferred Media
├─ Clear All Preferences                [Button]
├─ Clear Older Than 1 Year             [Button]
└─ Clear Older Than 2 Years            [Button]

Footer: "Remove saved preferences for which photo or video
         represents each day in the calendar."
```

**Confirmation Dialog:**
- Alert before clearing: "Are you sure you want to clear [timeframe]?"
- Action button: "Clear" (destructive style)
- Cancel button: "Cancel"

---

## 11. Technical Considerations

### Performance
- Preferences lookup should be fast (SwiftData indexed by date)
- Don't reload entire calendar when preference changes - just update affected day cell
- Cache preference lookups during month view (avoid redundant queries)

### Memory
- Preferences are small (date + string) - minimal footprint
- No automatic cleanup - user controls via Settings

### User Experience
- Make it obvious which is preferred (pin badge)
- Make it easy to change (long press is discoverable)
- Provide feedback (haptic + visual confirmation)
- Don't interrupt workflow (no modal dialogs)

### Accessibility
- VoiceOver label: "Pinned as preferred" for badged items
- Long press gesture should work with VoiceOver actions
- Toast messages should be announced

---

## 12. Testing Checklist

- [ ] Preference saves correctly
- [ ] Preference persists across app launches
- [ ] Pin badge shows on correct item
- [ ] Long press changes preference
- [ ] Haptic feedback works
- [ ] Toast confirmation appears
- [ ] Calendar day cell updates when preference changes
- [ ] Smart default selects video first
- [ ] Smart default selects live photo if no video
- [ ] Deleted asset fallback works
- [ ] Single item day shows pin but can't change
- [ ] Cleanup options work correctly
- [ ] VoiceOver announces pin status
- [ ] Performance is good with 1000+ preferences

---

## 13. Dependencies

### Required Frameworks
- SwiftData (already in project)
- SwiftUI (already in project)
- Photos/PhotoKit (already in project)

### New Dependencies
- None

---

## 14. Migration Strategy

Since this is a new feature:
- No migration needed for existing users
- First launch will use smart defaults
- Users can customize as they explore the app
- No breaking changes to existing data models

---

## 15. Success Metrics

- Users can easily identify which media represents each day
- Changing preferences is intuitive (discoverable via long press)
- Calendar view shows user's preferred media consistently
- Performance remains smooth even with many preferences
- No data loss or corruption of preferences
