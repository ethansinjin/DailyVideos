//
//  VideoGenerationViewModel.swift
//  DailyVideos
//
//  Created by Claude on 1/7/26.
//

import Foundation
import SwiftUI

/// ViewModel for the video generation tab
@MainActor
class VideoGenerationViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var selectedTimeframe: TimeframeSelection?
    @Published var mediaSelections: [DayMediaSelection] = []
    @Published var currentJob: VideoGenerationJob?
    @Published var generationProgress: Double = 0
    @Published var isGenerating: Bool = false
    @Published var isLoadingSelections: Bool = false
    @Published var generatedVideoURL: URL?
    @Published var error: Error?
    @Published var compositionSettings: VideoCompositionSettings = .default
    @Published var showingPreview: Bool = false
    @Published var timeframeSummary: TimeframeSummary?

    // MARK: - Services

    private let selectionService = MediaSelectionService.shared

    // MARK: - Initialization

    init() {
        // Initialize with current month as default timeframe suggestion
        let now = Date()
        let calendar = Calendar.current
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)

        self.selectedTimeframe = TimeframeSelection(
            type: .month(year: year, month: month)
        )
    }

    // MARK: - Timeframe Selection

    /// Select a new timeframe
    /// - Parameter type: The type of timeframe (month, year, custom)
    func selectTimeframe(_ type: TimeframeType) {
        selectedTimeframe = TimeframeSelection(type: type)
        // Clear previous selections when timeframe changes
        mediaSelections = []
        timeframeSummary = nil
    }

    /// Load media selections for the selected timeframe
    func loadMediaSelections() async {
        guard let timeframe = selectedTimeframe else {
            error = NSError(domain: "VideoGeneration", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "No timeframe selected"
            ])
            return
        }

        isLoadingSelections = true
        error = nil

        do {
            // Get media selections from service
            let selections = await selectionService.selectMedia(for: timeframe)

            // Get summary statistics
            let summary = await selectionService.getTimeframeSummary(timeframe)

            // Update on main thread (already guaranteed by @MainActor)
            self.mediaSelections = selections
            self.timeframeSummary = summary

            if selections.isEmpty {
                error = NSError(domain: "VideoGeneration", code: 2, userInfo: [
                    NSLocalizedDescriptionKey: "No media found in selected timeframe"
                ])
            }
        } catch {
            self.error = error
        }

        isLoadingSelections = false
    }

    // MARK: - Video Generation (Placeholder)

    /// Generate video from selected media
    /// Note: This is a placeholder. Full implementation will be in Phase 5.
    func generateVideo() async {
        guard !mediaSelections.isEmpty else {
            error = NSError(domain: "VideoGeneration", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "No media selected for video generation"
            ])
            return
        }

        guard let timeframe = selectedTimeframe else { return }

        isGenerating = true
        generationProgress = 0
        error = nil

        // Create job
        currentJob = VideoGenerationJob(
            timeframe: timeframe,
            mediaSelections: mediaSelections,
            status: .preparing,
            settings: compositionSettings
        )

        // TODO: Phase 5 - Implement actual video composition
        // For now, simulate progress
        await simulateGeneration()
    }

    /// Simulate video generation (placeholder for Phase 5)
    private func simulateGeneration() async {
        for i in 0...10 {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            generationProgress = Double(i) / 10.0

            if i < 5 {
                currentJob?.status = .composing(progress: Double(i) / 5.0)
            } else {
                currentJob?.status = .exporting(progress: Double(i - 5) / 5.0)
            }
        }

        // Complete
        currentJob?.status = .completed(outputURL: URL(fileURLWithPath: "/tmp/placeholder.mp4"))
        currentJob?.completedAt = Date()
        generatedVideoURL = URL(fileURLWithPath: "/tmp/placeholder.mp4")
        isGenerating = false
    }

    /// Cancel video generation
    func cancelGeneration() {
        isGenerating = false
        currentJob?.status = .cancelled
        generationProgress = 0
    }

    // MARK: - Preview

    /// Show preview of selected media
    func previewSelections() {
        showingPreview = true
    }

    // MARK: - Export (Placeholder)

    /// Save video to Photos library
    /// Note: This is a placeholder. Full implementation will be in Phase 8.
    func saveVideo() async {
        guard generatedVideoURL != nil else { return }

        // TODO: Phase 8 - Implement actual save to Photos library
        print("📹 Saving video to Photos library (placeholder)")
    }

    /// Share video via system share sheet
    /// Note: This is a placeholder. Full implementation will be in Phase 8.
    func shareVideo() {
        guard generatedVideoURL != nil else { return }

        // TODO: Phase 8 - Implement actual share sheet
        print("📹 Sharing video (placeholder)")
    }

    // MARK: - Settings

    /// Update composition settings
    /// - Parameter settings: New settings
    func updateSettings(_ settings: VideoCompositionSettings) {
        compositionSettings = settings
    }

    // MARK: - Reset

    /// Reset to initial state (for "Generate New" button)
    func reset() {
        mediaSelections = []
        currentJob = nil
        generationProgress = 0
        isGenerating = false
        generatedVideoURL = nil
        error = nil
        showingPreview = false
        timeframeSummary = nil

        // Keep timeframe and settings
    }
}
