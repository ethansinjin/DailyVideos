//
//  VideoGenerationModelsTests.swift
//  DailyVideosTests
//
//  Unit tests for video generation models
//

import Testing
import Foundation
@testable import DailyVideos

struct VideoGenerationModelsTests {

    // MARK: - TimeframeSelection

    @Test func testTimeframeSelectionMonthDatesAndDayCount() async throws {
        let calendar = Calendar.current
        let timeframe = TimeframeSelection(type: .month(year: 2024, month: 3))

        let startComponents = calendar.dateComponents([.year, .month, .day], from: timeframe.startDate)
        #expect(startComponents.year == 2024)
        #expect(startComponents.month == 3)
        #expect(startComponents.day == 1)

        let range = calendar.range(of: .day, in: .month, for: timeframe.startDate)
        let expectedDayCount = range?.count ?? 31
        let endComponents = calendar.dateComponents([.year, .month, .day], from: timeframe.endDate)

        #expect(endComponents.year == 2024)
        #expect(endComponents.month == 3)
        #expect(endComponents.day == expectedDayCount)
        #expect(timeframe.dayCount == expectedDayCount)
    }

    @Test func testTimeframeSelectionYearDatesAndDayCount() async throws {
        let calendar = Calendar.current
        let timeframe = TimeframeSelection(type: .year(year: 2025))

        let startComponents = calendar.dateComponents([.year, .month, .day], from: timeframe.startDate)
        #expect(startComponents.year == 2025)
        #expect(startComponents.month == 1)
        #expect(startComponents.day == 1)

        let endComponents = calendar.dateComponents([.year, .month, .day], from: timeframe.endDate)
        #expect(endComponents.year == 2025)
        #expect(endComponents.month == 12)
        #expect(endComponents.day == 31)

        let dayCount = timeframe.dayCount
        #expect(dayCount == 365 || dayCount == 366)
    }

    @Test func testTimeframeSelectionCustomNormalizesToStartOfDay() async throws {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2024, month: 8, day: 2, hour: 14, minute: 30))!
        let end = calendar.date(from: DateComponents(year: 2024, month: 8, day: 5, hour: 23, minute: 59))!
        let timeframe = TimeframeSelection(type: .custom(startDate: start, endDate: end))

        #expect(timeframe.startDate == calendar.startOfDay(for: start))
        #expect(timeframe.endDate == calendar.startOfDay(for: end))
        #expect(timeframe.dayCount == 4)
    }

    @Test func testTimeframeSelectionDisplayNames() async throws {
        let monthSelection = TimeframeSelection(type: .month(year: 2024, month: 1))
        #expect(monthSelection.displayName == "January 2024")

        let yearSelection = TimeframeSelection(type: .year(year: 2026))
        #expect(yearSelection.displayName == "2026")

        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2024, month: 10, day: 3))!
        let end = calendar.date(from: DateComponents(year: 2024, month: 10, day: 6))!
        let customSelection = TimeframeSelection(type: .custom(startDate: start, endDate: end))

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        #expect(customSelection.displayName == "\(formatter.string(from: start)) - \(formatter.string(from: end))")
    }

    // MARK: - DayMediaSelection

    @Test func testDayMediaSelectionFlagsAndLabels() async throws {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2024, month: 5, day: 12))!
        let sourceDate = calendar.date(from: DateComponents(year: 2024, month: 5, day: 1))!

        let media = MediaItem(
            assetIdentifier: "asset-1",
            date: date,
            mediaType: .video,
            duration: 2.5,
            displayContext: .native
        )

        let pinned = DayMediaSelection(date: date, selectedMedia: media, selectionReason: .pinnedNormal)
        #expect(pinned.isPinned == true)
        #expect(pinned.isCheating == false)
        #expect(pinned.reasonLabel == "Pinned")

        let cheating = DayMediaSelection(date: date, selectedMedia: media, selectionReason: .pinnedCheating(fromDate: sourceDate))
        #expect(cheating.isPinned == true)
        #expect(cheating.isCheating == true)

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        #expect(cheating.reasonLabel == "Pinned from \(formatter.string(from: sourceDate))")

        let automatic = DayMediaSelection(date: date, selectedMedia: media, selectionReason: .automatic(priority: 2))
        #expect(automatic.isPinned == false)
        #expect(automatic.isCheating == false)
        #expect(automatic.reasonLabel == "Auto (Priority 2)")

        let manual = DayMediaSelection(date: date, selectedMedia: media, selectionReason: .manualSelection)
        #expect(manual.reasonLabel == "Manually Selected")
    }

    // MARK: - VideoCompositionSettings

    @Test func testVideoCompositionSettingsDefaults() async throws {
        let settings = VideoCompositionSettings.default

        #expect(settings.resolution == .resolution1080p)
        #expect(settings.frameRate == 30)
        #expect(settings.transitionStyle == .crossDissolve)
        #expect(settings.transitionDuration == 0.5)
        #expect(settings.includeAudio == true)
        #expect(settings.audioCrossfadeDuration == 0.3)
        #expect(settings.includeDateOverlay == false)
        #expect(settings.dateOverlayPosition == .topLeft)
    }

    @Test func testVideoCompositionSettingsResolutionDetails() async throws {
        #expect(VideoCompositionSettings.VideoResolution.resolution720p.size.width == 1280)
        #expect(VideoCompositionSettings.VideoResolution.resolution1080p.size.height == 1080)
        #expect(VideoCompositionSettings.VideoResolution.resolution4K.displayName == "4K Ultra HD")
        #expect(VideoCompositionSettings.VideoResolution.original.size == .zero)
        #expect(VideoCompositionSettings.VideoResolution.resolution1080p.displayName == "1080p Full HD")
    }

    @Test func testVideoCompositionSettingsMultipliers() async throws {
        #expect(VideoCompositionSettings.VideoResolution.resolution720p.size.width > 0)
        #expect(VideoCompositionSettings.default.fileSizeMultiplier == 2.0)
        #expect(VideoCompositionSettings(resolution: .resolution4K,
                                         frameRate: 30,
                                         transitionStyle: .none,
                                         transitionDuration: 0,
                                         includeAudio: true,
                                         audioCrossfadeDuration: 0,
                                         includeDateOverlay: false,
                                         dateOverlayPosition: .topLeft).fileSizeMultiplier == 8.0)
        #expect(VideoCompositionSettings(resolution: .resolution720p,
                                         frameRate: 30,
                                         transitionStyle: .none,
                                         transitionDuration: 0,
                                         includeAudio: true,
                                         audioCrossfadeDuration: 0,
                                         includeDateOverlay: false,
                                         dateOverlayPosition: .topLeft).fileSizeMultiplier == 1.0)
        #expect(VideoCompositionSettings(resolution: .original,
                                         frameRate: 30,
                                         transitionStyle: .none,
                                         transitionDuration: 0,
                                         includeAudio: true,
                                         audioCrossfadeDuration: 0,
                                         includeDateOverlay: false,
                                         dateOverlayPosition: .topLeft).fileSizeMultiplier == 2.5)
    }

    // MARK: - VideoGenerationStatus

    @Test func testVideoGenerationStatusFlagsAndProgress() async throws {
        #expect(VideoGenerationStatus.preparing.isActive == true)
        #expect(VideoGenerationStatus.exporting(progress: 0.1).isActive == true)
        #expect(VideoGenerationStatus.completed(outputURL: URL(fileURLWithPath: "/tmp/video.mp4")).isActive == false)

        #expect(VideoGenerationStatus.cancelled.isFinished == true)
        #expect(VideoGenerationStatus.failed(error: "fail").isFinished == true)
        #expect(VideoGenerationStatus.composing(progress: 0.2).isFinished == false)

        let composingProgress = VideoGenerationStatus.composing(progress: 0.5).overallProgress
        #expect(abs(composingProgress - 0.35) < 0.0001)

        let exportingProgress = VideoGenerationStatus.exporting(progress: 0.2).overallProgress
        #expect(abs(exportingProgress - 0.6) < 0.0001)

        #expect(VideoGenerationStatus.composing(progress: 0.42).statusMessage == "Composing video... 42%")
        #expect(VideoGenerationStatus.exporting(progress: 0.7).statusMessage == "Exporting... 70%")
        #expect(VideoGenerationStatus.preparing.statusMessage == "Preparing...")
        #expect(VideoGenerationStatus.completed(outputURL: URL(fileURLWithPath: "/tmp/out.mp4")).statusMessage == "Completed")
        #expect(VideoGenerationStatus.failed(error: "nope").statusMessage == "Failed: nope")
    }

    // MARK: - VideoGenerationJob

    @Test func testVideoGenerationJobDerivedValues() async throws {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2024, month: 5, day: 12))!
        let mediaA = MediaItem(assetIdentifier: "asset-a", date: date, mediaType: .video, duration: 5.0, displayContext: .native)
        let mediaB = MediaItem(assetIdentifier: "asset-b", date: date, mediaType: .livePhoto, duration: nil, displayContext: .native)
        let mediaC = MediaItem(assetIdentifier: "asset-c", date: date, mediaType: .video, duration: 2.0, displayContext: .native)

        let selections = [
            DayMediaSelection(date: date, selectedMedia: mediaA, selectionReason: .pinnedNormal),
            DayMediaSelection(date: date, selectedMedia: mediaB, selectionReason: .automatic(priority: 2)),
            DayMediaSelection(date: date, selectedMedia: mediaC, selectionReason: .pinnedCheating(fromDate: date))
        ]

        let timeframe = TimeframeSelection(type: .month(year: 2024, month: 5))
        let job = VideoGenerationJob(timeframe: timeframe, mediaSelections: selections)

        #expect(job.clipCount == 3)
        #expect(job.pinnedCount == 2)
        #expect(job.cheatingPinCount == 1)
        #expect(job.estimatedDuration == 10.0)
        #expect(job.estimatedDurationString == "10s")
    }

    @Test func testVideoGenerationJobDurationFormattingInMinutes() async throws {
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2024, month: 6, day: 3))!
        let mediaA = MediaItem(assetIdentifier: "asset-a", date: date, mediaType: .video, duration: 62.0, displayContext: .native)

        let selection = DayMediaSelection(date: date, selectedMedia: mediaA, selectionReason: .automatic(priority: 1))
        let timeframe = TimeframeSelection(type: .month(year: 2024, month: 6))
        let job = VideoGenerationJob(timeframe: timeframe, mediaSelections: [selection])

        #expect(job.estimatedDuration == 62.0)
        #expect(job.estimatedDurationString == "1:02")
    }

    // MARK: - TimeframeSummary

    @Test func testTimeframeSummaryFormatting() async throws {
        let summary = TimeframeSummary(
            totalDays: 10,
            pinnedCount: 2,
            cheatingPinCount: 1,
            videoCount: 6,
            livePhotoCount: 4,
            estimatedDuration: 125
        )

        #expect(summary.durationString == "2:05")
        #expect(summary.description == "10 days • 2:05 • 2 pinned")

        let shortSummary = TimeframeSummary(
            totalDays: 1,
            pinnedCount: 0,
            cheatingPinCount: 0,
            videoCount: 1,
            livePhotoCount: 0,
            estimatedDuration: 45
        )

        #expect(shortSummary.durationString == "45s")
    }
}
