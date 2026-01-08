//
//  VideoGenerationViewModel.swift
//  DailyVideos
//
//  Created by Claude on 1/7/26.
//

import Foundation
import SwiftUI
import Combine

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
    private let compositionService = VideoCompositionService.shared
    private let exportService = VideoExportService.shared

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

    // MARK: - Video Generation

    /// Generate video from selected media
    func generateVideo() async {
        guard !mediaSelections.isEmpty else {
            error = VideoGenerationError.noMediaSelected
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

        do {
            // Generate video using composition service
            let outputURL = try await compositionService.composeVideo(
                from: mediaSelections,
                settings: compositionSettings
            ) { [weak self] progress in
                Task { @MainActor in
                    self?.generationProgress = progress

                    // Update job status based on progress
                    if progress < 0.4 {
                        self?.currentJob?.status = .composing(progress: progress / 0.4)
                    } else {
                        self?.currentJob?.status = .exporting(progress: (progress - 0.4) / 0.6)
                    }
                }
            }

            // Success!
            currentJob?.status = .completed(outputURL: outputURL)
            currentJob?.completedAt = Date()
            generatedVideoURL = outputURL
            isGenerating = false

        } catch is CancellationError {
            // User cancelled
            currentJob?.status = .cancelled
            isGenerating = false
            generationProgress = 0

        } catch let error as VideoGenerationError {
            // Known error
            self.error = error
            currentJob?.status = .failed(error: error.localizedDescription ?? "Unknown error")
            isGenerating = false

        } catch {
            // Unknown error
            self.error = VideoGenerationError.unknown(error)
            currentJob?.status = .failed(error: error.localizedDescription)
            isGenerating = false
        }
    }

    /// Cancel video generation
    func cancelGeneration() async {
        await compositionService.cancelGeneration()
        isGenerating = false
        currentJob?.status = .cancelled
        generationProgress = 0
    }

    // MARK: - Preview

    /// Show preview of selected media
    func previewSelections() {
        showingPreview = true
    }

    // MARK: - Export

    /// Save video to Photos library
    func saveVideo() async {
        guard let videoURL = generatedVideoURL else { return }

        error = nil

        do {
            try await exportService.saveToPhotoLibrary(videoURL)
            // Success - could add a success message to UI
            print("✅ Video saved to Photos library successfully")
        } catch let exportError as VideoExportError {
            error = exportError
        } catch {
            self.error = error
        }
    }

    /// Get share items for system share sheet
    /// - Returns: Array of items to share
    func getShareItems() async -> [Any] {
        guard let videoURL = generatedVideoURL else { return [] }
        return await exportService.getShareItems(for: videoURL)
    }

    /// Get file size of generated video
    /// - Returns: Formatted file size string, or nil if not available
    func getVideoFileSize() async -> String? {
        guard let videoURL = generatedVideoURL else { return nil }

        if let bytes = await exportService.getFileSize(of: videoURL) {
            return await exportService.formatFileSize(bytes)
        }
        return nil
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
