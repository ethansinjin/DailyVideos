//
//  VideoCompositionService.swift
//  DailyVideos
//
//  Created by Claude on 1/7/26.
//

import Foundation
import AVFoundation
internal import Photos
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Service for composing videos from media selections using AVFoundation
actor VideoCompositionService {
    static let shared = VideoCompositionService()

    private var currentExportSession: AVAssetExportSession?
    private var progressTimer: Timer?

    private init() {}

    // MARK: - Main Composition Method

    /// Compose a video from selected media
    /// - Parameters:
    ///   - selections: Array of DayMediaSelection objects
    ///   - settings: Video composition settings
    ///   - progressHandler: Progress callback (0.0 to 1.0)
    /// - Returns: URL of the exported video file
    func composeVideo(
        from selections: [DayMediaSelection],
        settings: VideoCompositionSettings,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        guard !selections.isEmpty else {
            throw VideoGenerationError.noMediaSelected
        }

        // Phase 1: Load all assets (0-20% progress)
        progressHandler(0.0)
        let assets = try await loadAssets(from: selections)
        progressHandler(0.2)

        // Phase 2: Create composition (20-40% progress)
        let composition = try await createComposition(from: assets, settings: settings)
        progressHandler(0.4)

        // Phase 3: Export video (40-100% progress)
        let outputURL = try await exportVideo(
            composition: composition,
            settings: settings,
            progressHandler: { exportProgress in
                // Map export progress (0-1) to overall progress (0.4-1.0)
                progressHandler(0.4 + (exportProgress * 0.6))
            }
        )

        return outputURL
    }

    /// Cancel current video generation
    func cancelGeneration() async {
        currentExportSession?.cancelExport()
        currentExportSession = nil
    }

    // MARK: - Asset Loading

    /// Load PHAssets from media selections
    /// - Parameter selections: Array of selections
    /// - Returns: Array of loaded AVAssets
    private func loadAssets(from selections: [DayMediaSelection]) async throws -> [AVAsset] {
        var assets: [AVAsset] = []

        for selection in selections {
            let asset = try await loadAsset(from: selection.selectedMedia)
            assets.append(asset)
        }

        return assets
    }

    /// Load a single AVAsset from a MediaItem
    /// - Parameter mediaItem: The media item to load
    /// - Returns: AVAsset for the media
    private func loadAsset(from mediaItem: MediaItem) async throws -> AVAsset {
        guard let phAsset = mediaItem.asset else {
            throw VideoGenerationError.assetLoadingFailed(assetId: mediaItem.assetIdentifier)
        }

        // For videos, load as AVAsset
        if mediaItem.mediaType == .video {
            return try await loadVideoAsset(from: phAsset)
        }

        // For Live Photos, extract the video component
        if mediaItem.mediaType == .livePhoto {
            return try await loadLivePhotoAsset(from: phAsset)
        }

        throw VideoGenerationError.assetLoadingFailed(assetId: mediaItem.assetIdentifier)
    }

    /// Load video asset from PHAsset
    /// - Parameter phAsset: The PHAsset
    /// - Returns: AVAsset
    private func loadVideoAsset(from phAsset: PHAsset) async throws -> AVAsset {
        return try await withCheckedThrowingContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.version = .current
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true

            PHImageManager.default().requestAVAsset(forVideo: phAsset, options: options) { avAsset, _, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: VideoGenerationError.assetLoadingFailed(assetId: phAsset.localIdentifier))
                } else if let avAsset = avAsset {
                    continuation.resume(returning: avAsset)
                } else {
                    continuation.resume(throwing: VideoGenerationError.assetLoadingFailed(assetId: phAsset.localIdentifier))
                }
            }
        }
    }

    /// Load Live Photo as video asset
    /// - Parameter phAsset: The PHAsset (Live Photo)
    /// - Returns: AVAsset extracted from Live Photo
    private func loadLivePhotoAsset(from phAsset: PHAsset) async throws -> AVAsset {
        // For Live Photos, we need to get the paired video resource
        return try await withCheckedThrowingContinuation { continuation in
            let resources = PHAssetResource.assetResources(for: phAsset)

            // Find the paired video resource
            guard let videoResource = resources.first(where: { $0.type == .pairedVideo }) else {
                continuation.resume(throwing: VideoGenerationError.assetLoadingFailed(assetId: phAsset.localIdentifier))
                return
            }

            // Create a temporary file URL for the video
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")

            // Write the video resource to the temporary file
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true

            PHAssetResourceManager.default().writeData(
                for: videoResource,
                toFile: tempURL,
                options: options
            ) { error in
                if let error = error {
                    continuation.resume(throwing: VideoGenerationError.assetLoadingFailed(assetId: phAsset.localIdentifier))
                } else {
                    let asset = AVAsset(url: tempURL)
                    continuation.resume(returning: asset)
                }
            }
        }
    }

    // MARK: - Composition Creation

    /// Create video composition from assets
    /// - Parameters:
    ///   - assets: Array of AVAssets
    ///   - settings: Composition settings
    /// - Returns: AVMutableComposition
    private func createComposition(
        from assets: [AVAsset],
        settings: VideoCompositionSettings
    ) async throws -> AVMutableComposition {
        let composition = AVMutableComposition()

        guard let videoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw VideoGenerationError.compositionFailed(reason: "Failed to create video track")
        }

        guard let audioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw VideoGenerationError.compositionFailed(reason: "Failed to create audio track")
        }

        var currentTime = CMTime.zero

        // Add each asset to the composition
        for (index, asset) in assets.enumerated() {
            // Load tracks
            guard let sourceVideoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
                print("⚠️ VideoCompositionService: Skipping asset \(index) - no video track")
                continue
            }

            let sourceAudioTracks = try? await asset.loadTracks(withMediaType: .audio)
            let sourceAudioTrack = sourceAudioTracks?.first

            // Get duration
            let duration = try await asset.load(.duration)

            // Insert video track
            do {
                try videoTrack.insertTimeRange(
                    CMTimeRange(start: .zero, duration: duration),
                    of: sourceVideoTrack,
                    at: currentTime
                )
            } catch {
                throw VideoGenerationError.compositionFailed(reason: "Failed to insert video track: \(error.localizedDescription)")
            }

            // Insert audio track (if exists and audio is enabled)
            if settings.includeAudio, let sourceAudioTrack = sourceAudioTrack {
                do {
                    try audioTrack.insertTimeRange(
                        CMTimeRange(start: .zero, duration: duration),
                        of: sourceAudioTrack,
                        at: currentTime
                    )
                } catch {
                    print("⚠️ VideoCompositionService: Failed to insert audio for asset \(index): \(error)")
                    // Continue even if audio fails
                }
            }

            currentTime = CMTimeAdd(currentTime, duration)
        }

        return composition
    }

    // MARK: - Video Export

    /// Export video composition to file
    /// - Parameters:
    ///   - composition: The composition to export
    ///   - settings: Export settings
    ///   - progressHandler: Progress callback
    /// - Returns: URL of exported file
    private func exportVideo(
        composition: AVMutableComposition,
        settings: VideoCompositionSettings,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        // Create output URL
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")

        // Remove file if it exists
        try? FileManager.default.removeItem(at: outputURL)

        // Select export preset based on resolution
        let exportPreset = selectExportPreset(for: settings.resolution)

        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: exportPreset
        ) else {
            throw VideoGenerationError.exportFailed(reason: "Failed to create export session")
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true

        // Store session reference for cancellation
        currentExportSession = exportSession

        // Start export
        await exportSession.export()

        // Monitor progress
        await monitorExportProgress(exportSession: exportSession, progressHandler: progressHandler)

        // Check status
        switch exportSession.status {
        case .completed:
            currentExportSession = nil
            return outputURL

        case .cancelled:
            currentExportSession = nil
            try? FileManager.default.removeItem(at: outputURL)
            throw VideoGenerationError.cancelled

        case .failed:
            currentExportSession = nil
            try? FileManager.default.removeItem(at: outputURL)
            let errorMessage = exportSession.error?.localizedDescription ?? "Unknown error"
            throw VideoGenerationError.exportFailed(reason: errorMessage)

        default:
            currentExportSession = nil
            throw VideoGenerationError.exportFailed(reason: "Export ended in unexpected state")
        }
    }

    /// Monitor export progress
    /// - Parameters:
    ///   - exportSession: The export session
    ///   - progressHandler: Progress callback
    private func monitorExportProgress(
        exportSession: AVAssetExportSession,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async {
        while exportSession.status == .exporting || exportSession.status == .waiting {
            let progress = Double(exportSession.progress)
            progressHandler(progress)

            // Wait a bit before checking again
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }

        // Final progress update
        progressHandler(1.0)
    }

    /// Select export preset based on resolution
    /// - Parameter resolution: The target resolution
    /// - Returns: AVAssetExportPreset string
    private func selectExportPreset(for resolution: VideoCompositionSettings.VideoResolution) -> String {
        switch resolution {
        case .resolution720p:
            return AVAssetExportPreset1280x720
        case .resolution1080p:
            return AVAssetExportPreset1920x1080
        case .resolution4K:
            if #available(iOS 11.0, *) {
                return AVAssetExportPreset3840x2160
            } else {
                return AVAssetExportPreset1920x1080
            }
        case .original:
            return AVAssetExportPresetHighestQuality
        }
    }

    // MARK: - Cleanup

    /// Clean up temporary files
    /// - Parameter url: URL to clean up
    func cleanupTemporaryFile(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}
