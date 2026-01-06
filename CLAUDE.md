# DailyVideos - iOS Calendar Media App

## Overview
An iOS app that displays videos and Live Photos in a calendar view, allowing users to quickly see which days have media content and which days are blank.

## Current State
- ✅ Basic app structure (`DailyVideosApp.swift`)
- ✅ Simple calendar grid layout (`ContentView.swift`)
- ✅ Basic day cell component (`DayCell.swift`)

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

## Architecture Plan

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

### 6. App Structure

```
DailyVideos/
├── App/
│   └── DailyVideosApp.swift
├── Models/
│   ├── MediaItem.swift
│   ├── CalendarDay.swift
│   └── MonthData.swift
├── ViewModels/
│   └── CalendarViewModel.swift
├── Views/
│   ├── Calendar/
│   │   ├── CalendarView.swift (main)
│   │   ├── MonthHeaderView.swift
│   │   ├── DayOfWeekLabels.swift
│   │   ├── DayCell.swift
│   │   └── DayDetailView.swift
│   ├── Media/
│   │   ├── MediaGridView.swift
│   │   └── MediaDetailView.swift
│   └── Supporting/
│       ├── PermissionRequestView.swift
│       ├── EmptyStateView.swift
│       └── LoadingView.swift
├── Services/
│   ├── PhotoLibraryManager.swift
│   └── CalendarManager.swift
├── Utilities/
│   ├── DateExtensions.swift
│   ├── ImageCache.swift
│   └── Constants.swift
└── Resources/
    └── Info.plist (with photo library usage description)
```

### 7. Required Capabilities & Permissions

#### Info.plist Additions
- `NSPhotoLibraryUsageDescription`: "DailyVideos needs access to your photo library to display your videos and Live Photos in a calendar view."
- `NSPhotoLibraryAddUsageDescription`: (if adding media support later)

#### Frameworks
- SwiftUI (UI framework)
- PhotoKit (access Photos library)
- AVKit (video playback)
- PhotosUI (Live Photo playback)

### 8. Implementation Phases

#### Phase 1: Core Calendar Infrastructure ✅ (Partial)
- [x] Basic app structure
- [x] Simple calendar grid
- [x] Basic day cells
- [ ] Enhanced CalendarManager with proper date logic
- [ ] MonthData and CalendarDay models
- [ ] Month navigation (prev/next)
- [ ] Proper calendar grid with padding days

#### Phase 2: Photo Library Integration
- [ ] MediaItem model
- [ ] PhotoLibraryManager service
- [ ] Permission handling
- [ ] Fetch videos and Live Photos from library
- [ ] Filter by date range
- [ ] Generate thumbnails

#### Phase 3: Data Binding & Display
- [ ] CalendarViewModel
- [ ] Connect PhotoLibraryManager to calendar
- [ ] Display media indicators on day cells
- [ ] Show actual month data
- [ ] Loading and error states

#### Phase 4: Day Detail View
- [ ] DayDetailView with media grid
- [ ] Thumbnail display
- [ ] Media count badges
- [ ] Navigation to day detail

#### Phase 5: Media Viewer
- [ ] Full screen media viewer
- [ ] Video playback with AVKit
- [ ] Live Photo playback
- [ ] Swipe navigation between items

#### Phase 6: Polish & UX
- [ ] Thumbnail caching
- [ ] Performance optimization
- [ ] Empty states
- [ ] Today button
- [ ] Smooth animations
- [ ] Dark mode support
- [ ] Accessibility labels

#### Phase 7: Future Enhancements
- [ ] Search functionality
- [ ] Filter by media type
- [ ] Share media
- [ ] Export calendar view
- [ ] Widget support
- [ ] iCloud sync
- [ ] Multiple calendar views (week, year)

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

## Next Steps

1. Create proper folder structure
2. Implement CalendarManager with date logic
3. Create data models (MediaItem, CalendarDay, MonthData)
4. Set up PhotoLibraryManager
5. Enhance existing views with real data
6. Add month navigation
7. Implement day detail view
8. Add media viewer

## Notes

- Start with read-only access to photo library
- Focus on simple, clean UI
- Prioritize performance (calendar should feel instant)
- Test with large photo libraries
- Consider edge cases (no media, no permission, etc.)
