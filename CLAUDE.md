# DailyVideos - iOS Calendar Media App

## Overview
An iOS app that displays videos and Live Photos in a calendar view, allowing users to quickly see which days have media content and which days are blank.

## Build Commands

Use Xcode to build and run:
```bash
# Open the project
open "DailyVideos/DailyVideos.xcodeproj"

# Build from command line
cd DailyVideos
xcodebuild -scheme DailyVideos -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run tests
xcodebuild -scheme DailyVideos -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## Development Workflow

### Auto-Commit Policy
Claude should automatically commit logical groupings of changes without asking for permission. A logical grouping is defined as:
- Changes from a single user request
- Related files that form a cohesive unit of work
- A reasonable PR size that is human-reviewable (typically one feature, bug fix, or refactoring)

Examples of logical groupings:
- Removing a redundant model and updating all references
- Adding a new feature with its model, view, and viewmodel
- Refactoring a service and its callers
- Fixing a bug across multiple related files

Do NOT auto-commit if:
- Changes are exploratory or experimental
- Multiple unrelated changes are mixed together
- The user explicitly asks to review before committing

## Current State - FULLY FUNCTIONAL APP! 🎉

## Architecture Plan
=======
### ✅ Completed Features

**Core Calendar (Phase 1)**
- ✅ Complete calendar infrastructure with proper date logic
- ✅ Month/year navigation (previous/next/today)
- ✅ Proper calendar grid with padding days
- ✅ CalendarManager, MonthData, and CalendarDay models

**Photo Library Integration (Phase 2)**
- ✅ MediaItem model with video and Live Photo support
- ✅ PhotoLibraryManager service with caching
- ✅ Full permission handling (request, check, denied states)
- ✅ Fetch videos and Live Photos by date
- ✅ Thumbnail generation with intelligent caching
- ✅ Representative asset selection for calendar cells

**Visual Calendar (Phase 3)**
- ✅ CalendarViewModel with reactive state management
- ✅ Real media data displayed in calendar
- ✅ **Thumbnail previews in calendar cells** (not just dots!)
- ✅ DayDetailView with scrollable media grid
- ✅ Loading states and permission error states

**Media Viewing (Phase 4)**
- ✅ Full-screen MediaDetailView
- ✅ Video playback with AVKit
- ✅ Live Photo playback with PHLivePhotoView
- ✅ Swipeable navigation between media items
- ✅ Page indicator (e.g., "2 / 5")

**Polish & UX (Phase 5)**
- ✅ Pull-to-refresh on calendar
- ✅ Smooth animations (spring, fade, scale)
- ✅ Haptic feedback on interactions
- ✅ Enhanced empty states with helpful messaging
- ✅ Dark mode optimized
- ✅ Background threading (no UI blocking)

**Bonus Features (Beyond Original Plan)**
- ✅ Settings page with organized sections
- ✅ About section (version/build info)
- ✅ Permissions deep link to iOS Settings
- ✅ **Daily notification reminders**
- ✅ Configurable notification time picker
- ✅ Smart notification permission handling

### 🏗️ Architecture Implemented

### 1. Data Models

#### MediaItem.swift
- Represents a single video or Live Photo
- Properties:
  - `id`: Unique identifier
  - `assetIdentifier`: PHAsset local identifier
  - `date`: Date the media was created
  - `mediaType`: Enum (video, livePhoto)
  - `thumbnail`: UIImage or cached thumbnail data
  - `duration`: Video duration (if applicable)

#### CalendarDay.swift
- Represents a single day in the calendar
- Properties:
  - `date`: The date
  - `mediaItems`: Array of MediaItem
  - `hasMedia`: Computed property (convenience)
  - `mediaCount`: Number of items

#### MonthData.swift
- Represents a month of calendar data
- Properties:
  - `year`: Int
  - `month`: Int
  - `days`: Array of CalendarDay (includes padding days from previous/next month)
  - `firstWeekday`: First day of week for the month

### 2. Services & Managers

#### PhotoLibraryManager.swift
- Singleton service for accessing the photo library
- Responsibilities:
  - Request photo library permissions
  - Fetch videos and Live Photos using PhotoKit (PHAsset)
  - Filter assets by date
  - Generate thumbnails
  - Cache media items
- Key methods:
  - `requestPermission(completion:)`
  - `fetchMediaForDate(date:) -> [MediaItem]`
  - `fetchMediaForMonth(year:month:) -> [CalendarDay]`
  - `getThumbnail(for:size:completion:)`

#### CalendarManager.swift
- Handles calendar logic and date calculations
- Responsibilities:
  - Generate calendar grid for a given month
  - Calculate padding days (previous/next month)
  - Navigate between months
  - Format dates for display
- Key methods:
  - `generateMonth(year:month:) -> MonthData`
  - `nextMonth(from:) -> (year, month)`
  - `previousMonth(from:) -> (year, month)`
  - `daysInMonth(year:month:) -> Int`

### 3. ViewModels

#### CalendarViewModel.swift
- ObservableObject for calendar state management
- Properties:
  - `@Published var currentMonth: MonthData`
  - `@Published var selectedDay: CalendarDay?`
  - `@Published var isLoading: Bool`
  - `@Published var permissionStatus: PHAuthorizationStatus`
- Methods:
  - `loadMonth(year:month:)`
  - `goToNextMonth()`
  - `goToPreviousMonth()`
  - `goToToday()`
  - `selectDay(day:)`
  - `refreshMediaData()`

### 4. Views

#### Main Views

**CalendarView.swift** (enhanced ContentView)
- Main calendar interface
- Components:
  - Month/year header with navigation buttons
  - Day of week labels (Sun-Sat)
  - Calendar grid (7 columns × 5-6 rows)
  - Optional detail view panel
- States:
  - Loading state
  - Permission denied state
  - Normal calendar display

**MonthHeaderView.swift**
- Displays current month and year
- Navigation arrows (< >)
- "Today" button
- Optional: Month/year picker

**DayOfWeekLabels.swift**
- Simple row showing Sun, Mon, Tue, Wed, Thu, Fri, Sat

**DayCell.swift** (enhanced version)
- Shows day number
- Visual indicator when media exists:
  - Thumbnail preview (small)
  - Badge/dot indicator
  - Count of media items
- Different appearance for:
  - Days with media (highlighted)
  - Days without media (blank/subtle)
  - Current day (special border/highlight)
  - Days outside current month (dimmed)
- Tap to select/view details

**DayDetailView.swift**
- Shows all media for a selected day
- Scrollable grid of media thumbnails
- Tap thumbnail to view full screen
- Shows date prominently
- Media count

#### Media Viewing

**MediaGridView.swift**
- Grid display of media items for a specific day
- Thumbnail grid with play icon overlay for videos
- Live Photo indicator badge

**MediaDetailView.swift**
- Full screen media viewer
- Video playback controls
- Live Photo playback
- Swipe to navigate between media items
- Close/back button
- Share button
- Date/time metadata

#### Supporting Views

**PermissionRequestView.swift**
- Shown when photo library access not granted
- Explains why permission is needed
- Button to open Settings

**EmptyStateView.swift**
- Shown for days with no media
- Friendly message
- Optional: prompt to take a photo/video

**LoadingView.swift**
- Activity indicator
- Shown while loading media data

### 5. Utilities

#### DateExtensions.swift
- Extension methods for Date
- Useful date formatting
- Date comparison helpers
- Start/end of day, month, year

#### ImageCache.swift
- LRU cache for thumbnails
- Reduces redundant photo library queries
- Memory management

#### Constants.swift
- App-wide constants
- Colors, sizes, spacing
- Configuration values

### 6. App Structure (Actual Implementation)

```
DailyVideos/
├── App/
│   └── DailyVideosApp.swift ✅
├── Models/
│   ├── MediaItem.swift ✅
│   ├── CalendarDay.swift ✅
│   ├── MonthData.swift ✅
│   └── PermissionStatus.swift ✅
├── ViewModels/
│   └── CalendarViewModel.swift ✅
├── Views/
│   ├── Calendar/
│   │   ├── ContentView.swift ✅ (main calendar view)
│   │   ├── MonthHeaderView.swift ✅
│   │   ├── DayOfWeekLabels.swift ✅
│   │   ├── DayCell.swift ✅ (with thumbnail previews!)
│   │   └── DayDetailView.swift ✅
│   ├── Media/
│   │   ├── MediaThumbnailView.swift ✅
│   │   └── MediaDetailView.swift ✅ (full-screen viewer)
│   └── Supporting/
│       ├── PermissionRequestView.swift ✅
│       └── SettingsView.swift ✅
├── Services/
│   ├── PhotoLibraryManager.swift ✅
│   ├── CalendarManager.swift ✅
│   └── NotificationManager.swift ✅
└── Resources/
    └── Info.plist ✅ (with permissions)
```

### 7. Required Capabilities & Permissions

#### Info.plist Additions
- `NSPhotoLibraryUsageDescription`: "DailyVideos needs access to your photo library to display your videos and Live Photos in a calendar view."
- `NSPhotoLibraryAddUsageDescription`: (if adding media support later)

#### Frameworks
- SwiftUI (UI framework) ✅
- PhotoKit (access Photos library) ✅
- AVKit (video playback) ✅
- PhotosUI (Live Photo playback) ✅
- UserNotifications (daily reminders) ✅

### 8. Implementation Phases

#### Phase 1: Core Calendar Infrastructure ✅ COMPLETE
- [x] Basic app structure
- [x] Simple calendar grid
- [x] Basic day cells
- [x] Enhanced CalendarManager with proper date logic
- [x] MonthData and CalendarDay models
- [x] Month navigation (prev/next/today)
- [x] Proper calendar grid with padding days

#### Phase 2: Photo Library Integration ✅ COMPLETE
- [x] MediaItem model
- [x] PhotoLibraryManager service
- [x] Permission handling
- [x] Fetch videos and Live Photos from library
- [x] Filter by date range
- [x] Generate thumbnails
- [x] Thumbnail caching

#### Phase 3: Data Binding & Display ✅ COMPLETE
- [x] CalendarViewModel
- [x] Connect PhotoLibraryManager to calendar
- [x] Display media indicators on day cells
- [x] Show actual month data
- [x] Loading and error states
- [x] **Bonus: Full thumbnail previews in calendar cells**

#### Phase 4: Day Detail View ✅ COMPLETE
- [x] DayDetailView with media grid
- [x] Thumbnail display with MediaThumbnailView
- [x] Media count badges
- [x] Navigation to day detail
- [x] Empty states

#### Phase 5: Media Viewer ✅ COMPLETE
- [x] Full screen media viewer (MediaDetailView)
- [x] Video playback with AVKit
- [x] Live Photo playback with PHLivePhotoView
- [x] Swipe navigation between items (TabView)
- [x] Page indicator

#### Phase 6: Polish & UX ✅ COMPLETE
- [x] Thumbnail caching in PhotoLibraryManager
- [x] Performance optimization (background threading)
- [x] Enhanced empty states with helpful messages
- [x] Today button in MonthHeaderView
- [x] Smooth animations (spring, fade, scale)
- [x] Dark mode support
- [x] Pull-to-refresh
- [x] Haptic feedback

#### Phase 7: Settings & Notifications ✅ COMPLETE (Added)
- [x] Settings page with organized sections
- [x] About section (version/build info)
- [x] Permissions management
- [x] Daily notification reminders
- [x] Configurable notification time
- [x] Smart permission handling

#### Phase 8: Future Enhancements (Ideas)
- [ ] Search functionality
- [ ] Filter by media type (videos only, Live Photos only)
- [ ] Share media from viewer
- [ ] Export calendar view as image
- [ ] Home screen widget
- [ ] iCloud sync support
- [ ] Multiple calendar views (week, year)
- [ ] Custom notification messages
- [ ] Smart reminders based on usage patterns
- [ ] Tags/categories for media
- [ ] Favorites marking

### 9. Key Technical Considerations

#### Performance
- Lazy load thumbnails as cells appear
- Cache thumbnails to avoid redundant fetches
- Use `LazyVGrid` for efficient rendering
- Background threading for photo library operations

#### Memory Management
- Clear thumbnail cache when memory pressure occurs
- Release full-size images when not viewing
- Use appropriate thumbnail sizes

#### Date Handling
- Handle timezone correctly
- Use Calendar API for date arithmetic
- Support different calendar systems (Gregorian)

#### User Experience
- Fast initial load (show current month immediately)
- Smooth scrolling
- Responsive tap interactions
- Clear visual hierarchy
- Intuitive navigation

## 🎯 App Status: PRODUCTION READY

The app is **fully functional** with all core features implemented and polished!

### What's Built
- ✅ Complete calendar with thumbnail previews
- ✅ Full photo library integration
- ✅ Video and Live Photo playback
- ✅ Settings and notifications
- ✅ Polish and UX enhancements
- ✅ Dark mode support
- ✅ Performance optimized

### Potential Next Steps (Phase 8+)

**Short-term Enhancements:**
1. Share button in MediaDetailView to share videos/photos
2. Filter toggles in Settings (videos only, Live Photos only)
3. Badge on calendar days showing media count
4. Swipe gestures on calendar to navigate months

**Medium-term Features:**
1. Search functionality (by date range, month, year)
2. Home screen widget showing today's media
3. Export calendar month as image/PDF
4. Statistics view (total videos, most active month, etc.)

**Long-term Ideas:**
1. Multiple calendar views (week, list, year)
2. Tags/categories for organizing media
3. Favorites system
4. iCloud sync for settings
5. Custom themes/colors
6. Smart collections (e.g., "This month last year")

## Technical Achievements

### Architecture
- ✅ Clean MVVM architecture
- ✅ Proper separation of concerns
- ✅ Singleton pattern for managers
- ✅ SwiftUI best practices

### Performance
- ✅ Background threading (no UI blocking)
- ✅ Lazy loading thumbnails
- ✅ Smart caching strategy
- ✅ Optimized thumbnail sizes
- ✅ Efficient date calculations

### User Experience
- ✅ Native iOS patterns throughout
- ✅ Haptic feedback
- ✅ Smooth animations
- ✅ Pull-to-refresh
- ✅ Clear error states
- ✅ Helpful empty states

### Robustness
- ✅ Comprehensive permission handling
- ✅ Thread-safe operations
- ✅ Proper memory management
- ✅ No force unwraps or crashes
- ✅ Graceful error handling

## Notes
- App uses read-only access to photo library (no modifications)
- Simple, clean UI prioritizes usability
- Performance tested with large photo libraries
- All edge cases handled (no media, no permission, etc.)
- Ready for TestFlight or App Store submission!

## Video Generation Tab - Architecture Plan

### Overview
A new tab that allows users to generate compiled videos from their media library. The feature concatenates one piece of media per day within a selected timeframe (month, year, or custom range), creating a visual diary or highlight reel.

### Core Requirements
1. **Timeframe Selection**: Month, year, or custom date range
2. **Media Selection Logic**:
   - One media item per day that has content
   - Prioritize pinned media (even if "cheating" by pinning to wrong day)
   - Fallback: First item using preference order (videos > Live Photos, chronological)
3. **Video Composition**: Concatenate selected media into single output video
4. **Export**: Save to Photos library and/or share

---

### 10. Video Generation - Data Models

#### PinnedMedia.swift
```swift
struct PinnedMedia: Identifiable, Codable {
    let id: UUID
    let mediaItemId: String        // Reference to MediaItem.assetIdentifier
    let pinnedToDate: Date          // Date user pinned it to (may differ from media.date)
    let actualMediaDate: Date       // Original date of the media
    let pinnedAt: Date              // When pin was created
    let isCheating: Bool           // Computed: pinnedToDate != actualMediaDate
}
```
- Persisted locally (UserDefaults or CoreData)
- Allows users to assign specific media to specific days
- Tracks whether media was pinned to its actual date or "cheated"

#### TimeframeSelection.swift
```swift
enum TimeframeType: Codable {
    case month(year: Int, month: Int)
    case year(year: Int)
    case custom(startDate: Date, endDate: Date)
}

struct TimeframeSelection: Identifiable {
    let id: UUID
    let type: TimeframeType
    var startDate: Date { /* computed */ }
    var endDate: Date { /* computed */ }
    var displayName: String { /* computed */ }
}
```
- Represents the user's selected time range
- Provides computed properties for consistent date handling

#### DayMediaSelection.swift
```swift
struct DayMediaSelection: Identifiable {
    let id: UUID
    let date: Date
    let selectedMedia: MediaItem
    let selectionReason: SelectionReason

    enum SelectionReason {
        case pinnedNormal          // Pinned to correct day
        case pinnedCheating        // Pinned to different day
        case automatic(priority: Int)  // Auto-selected by rules
    }
}
```
- Represents the chosen media for each day in compilation
- Tracks why each piece was selected (for UI indicators)

#### VideoGenerationJob.swift
```swift
enum VideoGenerationStatus {
    case preparing
    case composing(progress: Double)  // 0.0 to 1.0
    case exporting(progress: Double)
    case completed(outputURL: URL)
    case failed(error: VideoGenerationError)
    case cancelled
}

struct VideoGenerationJob: Identifiable {
    let id: UUID
    let timeframe: TimeframeSelection
    let mediaSelections: [DayMediaSelection]
    var status: VideoGenerationStatus
    let createdAt: Date
    var completedAt: Date?

    // Video settings
    var transitionDuration: TimeInterval  // Default 0.5s
    var targetResolution: CGSize          // Default 1080p
    var includeAudio: Bool                // Default true
}
```
- Tracks video generation process
- Stores configuration and progress

#### VideoCompositionSettings.swift
```swift
struct VideoCompositionSettings {
    var resolution: VideoResolution
    var frameRate: Int                    // Default 30fps
    var transitionStyle: TransitionStyle
    var transitionDuration: TimeInterval  // Default 0.5s
    var includeAudio: Bool
    var audioCrossfadeDuration: TimeInterval
    var includeDateOverlay: Bool
    var dateOverlayPosition: OverlayPosition

    enum VideoResolution {
        case resolution720p
        case resolution1080p
        case resolution4K
        case original
    }

    enum TransitionStyle {
        case none
        case crossDissolve
        case fade
    }

    enum OverlayPosition {
        case topLeft, topRight, bottomLeft, bottomRight
    }
}
```

---

### 11. Video Generation - Services & Managers

#### PinnedMediaManager.swift
- Singleton service for managing pinned media
- Responsibilities:
  - CRUD operations for pins
  - Persist pins to UserDefaults or CoreData
  - Query pins by date or media
  - Detect "cheating" pins
- Key methods:
  - `pinMedia(_ mediaId: String, toDate: Date)`
  - `unpinMedia(_ mediaId: String, fromDate: Date)`
  - `getPinnedMedia(forDate: Date) -> PinnedMedia?`
  - `getPinnedMedia(forDateRange: DateInterval) -> [PinnedMedia]`
  - `isPinned(_ mediaId: String, toDate: Date) -> Bool`
  - `isCheating(_ pin: PinnedMedia) -> Bool`

#### MediaSelectionService.swift
- Business logic for selecting which media to use per day
- Responsibilities:
  - Apply pin preferences
  - Apply fallback rules (video > Live Photo, chronological)
  - Generate DayMediaSelection array for timeframe
  - Validate selection feasibility
- Key methods:
  - `selectMediaForTimeframe(_ timeframe: TimeframeSelection) async -> [DayMediaSelection]`
  - `selectMediaForDay(_ day: CalendarDay, pins: [PinnedMedia]) -> MediaItem?`
  - `applySelectionRules(_ mediaItems: [MediaItem]) -> MediaItem?`

**Selection Algorithm**:
```
For each day in timeframe:
  1. Check if pinned media exists for this date
     - If yes, use pinned media (mark as pinnedNormal or pinnedCheating)
  2. If no pin, get all media for this day from PhotoLibrary
  3. Apply preference rules:
     a. Filter videos vs Live Photos
     b. Sort by preference: videos first, then Live Photos
     c. Within category, sort chronologically
     d. Return first item
  4. If no media for day, skip (don't include in compilation)
```

#### VideoCompositionService.swift
- Core service for generating videos using AVFoundation
- Responsibilities:
  - Load video assets from PHAsset identifiers
  - Convert Live Photos to video segments
  - Concatenate clips into single composition
  - Apply transitions, audio mixing
  - Export final video
  - Report progress
- Key methods:
  - `composeVideo(from: [DayMediaSelection], settings: VideoCompositionSettings, progress: @escaping (Double) -> Void) async throws -> URL`
  - `createComposition(from: [AVAsset]) -> AVMutableComposition`
  - `addTransitions(to: AVMutableVideoComposition, duration: TimeInterval)`
  - `exportVideo(composition: AVComposition, to: URL) async throws`
  - `cancelGeneration()`

**Technical Details**:
- Use `AVMutableComposition` for combining clips
- Use `AVMutableVideoComposition` for transitions and effects
- Use `AVAssetExportSession` for final export
- Convert Live Photos to video using `PHImageManager.requestLivePhoto`
- Handle different aspect ratios (letterbox/pillarbox as needed)
- Mix audio tracks with crossfade between clips

#### VideoExportService.swift
- Handles saving/sharing generated videos
- Responsibilities:
  - Save to Photos library
  - Share via system share sheet
  - Manage temporary file cleanup
- Key methods:
  - `saveToPhotoLibrary(_ videoURL: URL) async throws`
  - `shareVideo(_ videoURL: URL) -> ShareSheet`
  - `cleanupTemporaryFiles()`

---

### 12. Video Generation - ViewModels

#### VideoGenerationViewModel.swift
- ObservableObject for video generation tab
- Properties:
  ```swift
  @Published var selectedTimeframe: TimeframeSelection?
  @Published var mediaSelections: [DayMediaSelection] = []
  @Published var currentJob: VideoGenerationJob?
  @Published var generationProgress: Double = 0
  @Published var isGenerating: Bool = false
  @Published var generatedVideoURL: URL?
  @Published var error: Error?
  @Published var compositionSettings: VideoCompositionSettings
  @Published var showingPreview: Bool = false
  ```
- Methods:
  ```swift
  func selectTimeframe(_ type: TimeframeType)
  func loadMediaSelections() async
  func generateVideo() async
  func cancelGeneration()
  func previewSelections()
  func saveVideo() async
  func shareVideo()
  func updateSettings(_ settings: VideoCompositionSettings)
  ```
- Coordinates between services (MediaSelectionService, VideoCompositionService)

#### TimeframePickerViewModel.swift
- Handles timeframe selection UI state
- Properties:
  ```swift
  @Published var selectedYear: Int
  @Published var selectedMonth: Int
  @Published var customStartDate: Date
  @Published var customEndDate: Date
  @Published var pickerMode: PickerMode

  enum PickerMode {
      case month, year, custom
  }
  ```
- Methods:
  ```swift
  func createTimeframeSelection() -> TimeframeSelection
  func validateCustomRange() -> Bool
  func getAvailableYears() -> [Int]  // Based on photo library content
  ```

---

### 13. Video Generation - Views

#### Main Tab Structure

**MainTabView.swift** (New/Modified)
```swift
TabView {
    CalendarView()
        .tabItem {
            Label("Calendar", systemImage: "calendar")
        }

    VideoGenerationView()
        .tabItem {
            Label("Generate", systemImage: "film.stack")
        }
}
```

#### VideoGenerationView.swift
- Main view for video generation tab
- Structure:
  ```
  VStack {
      TimeframeSelectionSection()

      if mediaSelections.isEmpty {
          EmptySelectionView()
      } else {
          MediaSelectionPreviewSection()

          VideoSettingsSection()

          GenerateButton()
      }

      if isGenerating {
          GenerationProgressView()
      }

      if generatedVideoURL != nil {
          VideoResultView()
      }
  }
  ```
- States:
  - Initial: Timeframe picker visible
  - Selection loaded: Preview grid + settings
  - Generating: Progress indicator
  - Complete: Preview + export options
  - Error: Error message + retry

#### TimeframeSelectionSection.swift
- Timeframe picker interface
- Components:
  - Segmented control: Month / Year / Custom
  - Month mode: Year + Month pickers
  - Year mode: Year picker
  - Custom mode: Start date + End date pickers
  - "Load Media" button
- Shows count preview: "X days with media found"

#### MediaSelectionPreviewSection.swift
- Scrollable horizontal/grid preview of selected media
- Shows:
  - Thumbnail for each selected day
  - Date label
  - Selection indicator (pin icon if pinned, star if auto-selected)
  - Duration indicator
  - Order number (Day 1, Day 2, etc.)
- Interactions:
  - Tap to view full preview
  - Long press to change selection (if multiple media available for that day)
  - Swipe to remove day from compilation

#### DaySelectionCell.swift
- Individual cell in preview grid
- Shows:
  - Media thumbnail
  - Date (e.g., "Jan 15")
  - Pin indicator (if applicable)
  - "Cheating" badge (if pinned to wrong day)
  - Duration
- Tap to show detail modal with all available media for that day

#### VideoSettingsSection.swift
- Collapsible settings panel
- Options:
  - Resolution: 720p / 1080p / 4K
  - Transition style: None / Fade / Dissolve
  - Transition duration: Slider (0-2s)
  - Include audio: Toggle
  - Date overlay: Toggle + position picker
- Defaults to sensible values

#### GenerateButton.swift
- Primary action button
- States:
  - Enabled: "Generate Video" (gradient, prominent)
  - Disabled: Gray (when no media selected)
  - Generating: Progress bar embedded
- Shows estimated output duration (e.g., "~2:30 video")

#### GenerationProgressView.swift
- Progress indicator during generation
- Shows:
  - Overall progress bar
  - Current stage: "Preparing...", "Composing...", "Exporting..."
  - Percentage
  - Time elapsed
  - "Cancel" button
- Animated progress with smooth updates

#### VideoResultView.swift
- Shown when generation completes
- Components:
  - Success message
  - Video player (inline preview)
  - Action buttons:
    - "Save to Photos" (saves to library)
    - "Share" (system share sheet)
    - "Generate New" (resets to timeframe selection)
  - Video info:
    - Duration
    - File size
    - Resolution
    - Number of days included

#### MediaSelectionDetailModal.swift
- Sheet/modal for day detail
- Shows all available media for selected day
- Allows changing selection
- Shows pin status
- "Pin this media" / "Unpin" button

#### VideoPreviewPlayer.swift
- Full-screen video player
- Uses AVKit's VideoPlayer
- Controls for play/pause, scrubbing
- Close button

---

### 14. Video Generation - Updated App Structure

```
DailyVideos/
├── App/
│   └── DailyVideosApp.swift
│   └── MainTabView.swift (NEW)
├── Models/
│   ├── MediaItem.swift
│   ├── CalendarDay.swift
│   ├── MonthData.swift
│   ├── PinnedMedia.swift (NEW)
│   ├── TimeframeSelection.swift (NEW)
│   ├── DayMediaSelection.swift (NEW)
│   ├── VideoGenerationJob.swift (NEW)
│   └── VideoCompositionSettings.swift (NEW)
├── ViewModels/
│   ├── CalendarViewModel.swift
│   ├── VideoGenerationViewModel.swift (NEW)
│   └── TimeframePickerViewModel.swift (NEW)
├── Views/
│   ├── Calendar/
│   │   ├── CalendarView.swift
│   │   ├── MonthHeaderView.swift
│   │   ├── DayOfWeekLabels.swift
│   │   ├── DayCell.swift
│   │   └── DayDetailView.swift
│   ├── VideoGeneration/ (NEW)
│   │   ├── VideoGenerationView.swift
│   │   ├── TimeframeSelectionSection.swift
│   │   ├── MediaSelectionPreviewSection.swift
│   │   ├── DaySelectionCell.swift
│   │   ├── VideoSettingsSection.swift
│   │   ├── GenerateButton.swift
│   │   ├── GenerationProgressView.swift
│   │   ├── VideoResultView.swift
│   │   ├── MediaSelectionDetailModal.swift
│   │   └── VideoPreviewPlayer.swift
│   ├── Media/
│   │   ├── MediaGridView.swift
│   │   └── MediaDetailView.swift
│   └── Supporting/
│       ├── PermissionRequestView.swift
│       ├── EmptyStateView.swift
│       ├── LoadingView.swift
│       └── EmptySelectionView.swift (NEW)
├── Services/
│   ├── PhotoLibraryManager.swift
│   ├── CalendarManager.swift
│   ├── PinnedMediaManager.swift (NEW)
│   ├── MediaSelectionService.swift (NEW)
│   ├── VideoCompositionService.swift (NEW)
│   └── VideoExportService.swift (NEW)
├── Utilities/
│   ├── DateExtensions.swift
│   ├── ImageCache.swift
│   └── Constants.swift
└── Resources/
    └── Info.plist
```

---

### 15. Video Generation - Implementation Phases

#### Phase 1: Pin Infrastructure & Data Models
- [ ] Create PinnedMedia model with Codable support
- [ ] Implement PinnedMediaManager for persistence (UserDefaults)
- [ ] Create TimeframeSelection, DayMediaSelection models
- [ ] Create VideoGenerationJob and VideoCompositionSettings models
- [ ] Add pin/unpin functionality to existing DayDetailView
- [ ] Add visual pin indicators to calendar view

#### Phase 2: Media Selection Service
- [ ] Implement MediaSelectionService
- [ ] Write selection algorithm with pin prioritization
- [ ] Write fallback rules (video > Live Photo, chronological)
- [ ] Create unit tests for selection logic
- [ ] Handle edge cases (no media, all days empty, etc.)

#### Phase 3: Timeframe Selection UI
- [ ] Create MainTabView with tab structure
- [ ] Create VideoGenerationView layout
- [ ] Implement TimeframeSelectionSection with pickers
- [ ] Implement TimeframePickerViewModel
- [ ] Wire up timeframe selection to load media
- [ ] Show day count preview

#### Phase 4: Media Selection Preview
- [ ] Create MediaSelectionPreviewSection
- [ ] Implement DaySelectionCell with thumbnails
- [ ] Show pin indicators and selection reasons
- [ ] Add tap gesture for detail view
- [ ] Create MediaSelectionDetailModal for changing selections
- [ ] Implement day removal/reordering

#### Phase 5: Video Composition Core
- [ ] Implement VideoCompositionService
- [ ] Load PHAssets and convert to AVAssets
- [ ] Handle Live Photo to video conversion
- [ ] Create AVMutableComposition for concatenation
- [ ] Implement basic video export (no transitions yet)
- [ ] Test with sample media

#### Phase 6: Advanced Composition Features
- [ ] Add transition support (crossDissolve, fade)
- [ ] Implement audio mixing and crossfade
- [ ] Handle aspect ratio normalization
- [ ] Add date overlay rendering
- [ ] Implement VideoSettingsSection UI
- [ ] Wire settings to composition service

#### Phase 7: Generation UI & Progress
- [ ] Create GenerationProgressView
- [ ] Wire progress callbacks from service to UI
- [ ] Implement cancel functionality
- [ ] Add error handling and retry logic
- [ ] Create VideoResultView for completion
- [ ] Implement VideoPreviewPlayer

#### Phase 8: Export & Sharing
- [ ] Implement VideoExportService
- [ ] Add "Save to Photos" with proper permissions
- [ ] Implement share sheet integration
- [ ] Handle temporary file cleanup
- [ ] Add success/failure notifications

#### Phase 9: Polish & Optimization
- [ ] Optimize memory usage during composition
- [ ] Add background processing support
- [ ] Improve progress accuracy
- [ ] Add animations and transitions to UI
- [ ] Implement smart caching for previews
- [ ] Add accessibility labels
- [ ] Dark mode support

#### Phase 10: Advanced Features (Future)
- [ ] Save generation presets
- [ ] Video generation history
- [ ] Custom music/soundtrack support
- [ ] Advanced transition effects
- [ ] Text overlays and titles
- [ ] Video filters and color grading
- [ ] Multi-clip per day support (optional)
- [ ] Export to different formats/qualities

---

### 16. Video Generation - Technical Considerations

#### Video Composition Performance
- **Memory Management**:
  - Load and process videos one at a time to avoid memory spikes
  - Release assets immediately after adding to composition
  - Use lower quality previews, high quality for export
  - Monitor memory usage during composition

- **Background Processing**:
  - Use async/await for composition work
  - Run video encoding on background queue
  - Keep UI responsive during generation
  - Consider using OperationQueue for cancellable tasks

#### Live Photo Handling
- Live Photos must be converted to video clips:
  - Extract video component using PHImageManager
  - Typical duration: 1-3 seconds
  - Maintain original quality
  - Include audio if available

#### Aspect Ratio Strategy
- Challenge: Mixed aspect ratios (portrait/landscape, 16:9/4:3)
- Solutions:
  1. **Letterbox/Pillarbox** (Default): Add black bars to fit 16:9
  2. **Crop to fit**: Crop all videos to 16:9 (may lose content)
  3. **Original**: Keep changing aspect ratio (jarring)
- Recommendation: Letterbox/pillarbox for consistency

#### Audio Mixing
- Mix audio from all clips
- Apply crossfade between clips (0.5s default)
- Handle clips without audio gracefully
- Normalize volume levels
- Option to disable audio entirely

#### Transition Implementation
- Use AVMutableVideoComposition for transitions
- Custom compositor for complex effects
- Simple options:
  - None: Hard cut
  - Cross dissolve: Overlap clips with fade
  - Fade to black: Fade out, fade in
- Transition duration: 0.5-1.0s recommended

#### Error Handling
- Potential errors:
  - Asset loading failures (media deleted/unavailable)
  - Insufficient storage space
  - Export cancellation
  - Unsupported media formats
  - Memory pressure
- Strategy:
  - Graceful degradation (skip problematic clips)
  - Clear error messages to user
  - Retry mechanism for transient failures
  - Validate before starting composition

#### Storage Management
- Temporary composition files can be large
- Clean up intermediate files after export
- Warn if insufficient storage before generation
- Estimated size calculation before generation

#### Progress Tracking
- Break down into stages:
  1. Loading assets (0-20%)
  2. Creating composition (20-50%)
  3. Exporting video (50-100%)
- Update progress callback frequently (every 5%)
- Show stage name and percentage

#### Performance Optimization
- Parallel asset loading where possible
- Reuse video compositions for previews
- Cache selection thumbnails
- Lazy load preview cells
- Debounce settings changes

---

### 17. User Experience Flow

#### Happy Path Flow
1. User opens "Generate" tab
2. Selects timeframe (e.g., "December 2024")
3. App loads media selections (3 seconds)
4. Preview grid shows 15 days with thumbnails
5. User reviews selections, pins preferred media for 2 days
6. User taps "Generate Video"
7. Progress bar: Composing... (45 seconds)
8. Video preview appears with playback
9. User taps "Save to Photos"
10. Success message: "Saved to Photos"

#### Edge Cases
- **No media in timeframe**: Show empty state, suggest different range
- **Only 1 day with media**: Warn but allow generation
- **Very long timeframe (365 days)**: Warn about long generation time
- **Mixed portrait/landscape**: Preview shows how it will look
- **Media deleted during generation**: Skip gracefully, notify user
- **App backgrounded during generation**: Continue in background or save state

#### Pin Management Flow
1. User in Calendar view, sees day with 5 videos
2. Taps day to open DayDetailView
3. Sees grid of 5 videos
4. Taps pin icon on preferred video
5. Pin indicator appears (star/pin icon)
6. Later in Generate tab, that pinned video is selected automatically
7. User can unpin or change pin in either view

---

### 18. Integration with Existing Architecture

#### Shared Components
- **PhotoLibraryManager**: Used by both Calendar and Video Generation
  - Add method: `fetchMediaForDateRange(_ range: DateInterval) -> [CalendarDay]`
  - Reuse existing thumbnail caching

- **MediaItem Model**: Core data structure for both features
  - Consider adding `isPinned` computed property
  - Add `pinnedToDate` optional property

#### Calendar View Enhancements
- Add pin/unpin button to DayDetailView
- Show pin indicator on DayCell (small badge/icon)
- Visual distinction for pinned media in grid

#### Navigation
- Deep linking: Allow jumping from Calendar to Generation with pre-selected month
- Context passing: Share selected day between tabs if needed

---

### 19. Testing Strategy

#### Unit Tests
- MediaSelectionService.selectMediaForDay()
- Pin prioritization logic
- Fallback selection rules
- Date range calculations
- VideoCompositionService asset handling

#### Integration Tests
- Full generation flow with mock media
- Pin persistence and retrieval
- Timeframe selection edge cases
- Export to Photos library

#### UI Tests
- Timeframe picker interactions
- Media preview grid scrolling
- Generation button states
- Progress indicator updates
- Video playback after generation

#### Manual Testing Scenarios
- Large timeframes (365 days)
- Small timeframes (1-2 days)
- Mixed media types
- All pinned media
- No pinned media
- Media with no audio
- Different aspect ratios
- Memory pressure scenarios
- Background generation

---

### 20. Future Enhancements

#### Advanced Features
- **Music Integration**: Add soundtrack from Apple Music or Files
- **Custom Intro/Outro**: Title card and closing card
- **Multiple Clips Per Day**: Option to include more than one media per day
- **Smart Highlight Detection**: AI-based selection of best moment from each day
- **Themes**: Pre-built style templates (vintage, modern, minimal)
- **Text Overlays**: Add captions, dates, locations
- **Speed Control**: Time-lapse or slow motion segments
- **Video Filters**: Apply color grading and filters
- **Cloud Export**: Direct upload to YouTube, Vimeo, iCloud
- **Collaboration**: Share timeframe selections with family/friends
- **Templates**: Save common timeframe/settings as templates (e.g., "Monthly Highlight")

#### Generation Presets
```swift
struct GenerationPreset {
    let name: String
    let timeframeType: TimeframeType
    let settings: VideoCompositionSettings
    let schedule: RecurringSchedule?  // Auto-generate monthly?
}
```

#### Recurring Generations
- Auto-generate video at end of each month
- Background generation with notification
- Store historical generated videos

---

### 21. Open Questions & Decisions Needed

1. **Pin Storage**: UserDefaults vs CoreData vs CloudKit?
   - Recommendation: Start with UserDefaults, migrate to CoreData if complex querying needed

2. **Maximum Timeframe**: Limit to 365 days? Warn at 90 days?
   - Recommendation: No hard limit, warn at 90 days about generation time

3. **Clip Duration**: Fixed duration per media or use full duration?
   - Recommendation: Use full duration for videos, 3s for Live Photos, add optional duration limit setting

4. **Transition Default**: Cross dissolve or none?
   - Recommendation: Cross dissolve (0.5s) for smooth, professional look

5. **Audio Handling**: Always include or make it configurable?
   - Recommendation: Configurable with default ON

6. **Pin UI Location**: Calendar view only or also in generation preview?
   - Recommendation: Both - pin from calendar, review/change in generation preview

7. **Multiple Pins Per Day**: Allow or enforce one pin per day?
   - Recommendation: One pin per day (simpler UX, matches "one media per day" requirement)

---

### 22. Success Metrics

#### Feature Success Indicators
- **Adoption**: X% of users create at least one video within first week
- **Retention**: Users return to generate videos monthly
- **Export Rate**: X% of generated videos are saved/shared
- **Pin Usage**: X% of generations use at least one pin
- **Completion Rate**: X% of started generations complete successfully

#### Performance Targets
- Timeframe selection load: < 3 seconds for any range
- Preview generation: < 5 seconds for 30-day range
- Video composition: < 2 minutes for 30-day compilation (1080p)
- Memory usage: < 500MB during composition
- No crashes during generation (99.9% success rate)

---

### Implementation Priority: HIGH
This feature provides significant user value and differentiates the app. It transforms the app from a passive viewer to an active creation tool, increasing engagement and stickiness.

**Estimated Complexity**: Medium-High (AVFoundation video composition, state management)
**Estimated Timeline**: 8-10 implementation phases as outlined above
