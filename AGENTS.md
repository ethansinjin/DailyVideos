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

## Project Plans

Architecture and feature plans are available in the `plans/` directory:

### 1. INITIAL_PLAN.md - Core App Architecture
**Status**: ✅ **COMPLETE** (Production Ready)
- Comprehensive architecture plan for the entire app
- All core features implemented (Phases 1-7)
  - Calendar infrastructure with date navigation
  - Photo library integration with permissions
  - Video and Live Photo playback
  - Settings and daily notifications
  - Polish, animations, and UX enhancements
- Phase 8 contains future enhancement ideas

### 2. ARCHITECTURE_PINNED_MEDIA.md - Preferred Media Selection
**Status**: 📋 **PLANNED** (Not yet implemented)
- Feature to let users choose which photo/video represents each day
- Uses SwiftData model `PreferredMedia` for persistence
- Pin badge UI to indicate preferred media
- Long-press interaction to set preferences
- 8 implementation phases outlined

### 3. ARCHITECTURE_PINNED_MEDIA_FROM_NEARBY_DAYS.md - Cross-Date Pin Feature
**Status**: 📋 **PLANNED** (Not yet implemented)
- "Cheat day" feature to pin media from other days
- Uses SwiftData model `PinnedMedia` (separate from preferred media)
- Browse nearby dates (±7 days) to find media to pin
- Distinct visual badges for cross-date pins
- 8 implementation phases outlined
- Depends on completion of preferred media feature

### 4. ARCHITECTURE_VIDEO_GENERATION.md - Video Compilation Tab
**Status**: 📋 **PLANNED** (Not yet implemented)
- New tab for generating compiled videos from timeframes
- Select month, year, or custom date range
- Automatically picks one media per day (prioritizes pinned media)
- Uses AVFoundation for video composition
- Export to Photos or share
- 10 implementation phases outlined
- Complex feature involving video processing

### 5. UNIT_TESTING_PLAN.md - Comprehensive Testing Strategy
**Status**: 📋 **PLANNED** (Tests not yet written)
- Detailed unit test plan for all models, services, and view models
- UI test plan for all user flows
- Accessibility and performance testing
- Testing infrastructure requirements
- Priority levels defined (P1: Critical → P3: Nice to have)
- Success criteria: 80% code coverage target