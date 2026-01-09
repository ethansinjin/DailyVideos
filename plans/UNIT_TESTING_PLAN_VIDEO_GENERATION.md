# Unit Testing Plan - Video Generation

## Status
📋 **Planned** — new plan focused on video generation and remaining untested areas.

## Scope
Focus on the Video Generation tab and its supporting models/services. Prioritize low-dependency unit tests first, then introduce test seams for PhotoKit/AVFoundation-backed services.

## Phase 1: Low-Dependency Model Tests (P1)
- TimeframeSelection
  - Start/end dates for month/year/custom
  - Day count inclusive of start/end
  - Display name formatting
- DayMediaSelection
  - isPinned/isCheating semantics
  - reasonLabel output for each reason
- VideoCompositionSettings
  - Default values
  - Resolution sizes and display names
  - File size multipliers
- VideoGenerationStatus
  - isActive/isFinished
  - overallProgress mapping
  - statusMessage formatting
- VideoGenerationJob
  - estimatedDuration and formatting
  - clipCount/pinnedCount/cheatingPinCount
- TimeframeSummary
  - durationString formatting
  - description text

## Phase 2: Service Logic with Test Seams (P1/P2)
Introduce protocols or dependency injection to allow deterministic tests.
- MediaSelectionService
  - pinned media takes precedence
  - fallback selection rules (video > live photo > chronological)
  - priority calculation
  - timeframe summary counts/duration
- PreferencesManager
  - set/get/remove preferred media
  - cleanup policies
- PinnedMediaManager
  - pin/unpin flows
  - orphan cleanup behavior

## Phase 3: Video Generation Services (P2)
Requires fakes/stubs for AVFoundation + PhotoKit.
- VideoCompositionService
  - rejects empty selections
  - composition/export error propagation
  - progress callback behavior
- VideoExportService
  - photo library save error handling
  - share item creation
  - temp file size formatting

## Phase 4: View Model Tests (P2/P3)
Requires dependency injection for services.
- VideoGenerationViewModel
  - loadMediaSelections updates state
  - generateVideo handles success/failure/cancel
  - reset restores initial state
  - save/share flows delegate to services

## Dependencies / Test Seams Needed
- Protocol abstractions for PhotoLibraryManager, PinnedMediaManager, MediaSelectionService, VideoCompositionService, VideoExportService.
- Injectable services in VideoGenerationViewModel and MediaSelectionService.
- Lightweight fake MediaItem factory for tests.

## Exit Criteria
- P1 tests green and stable without Photos/AVFoundation.
- P2 tests run with fakes/mocks in unit test target.
- Coverage expanded for video generation and pinning logic.
