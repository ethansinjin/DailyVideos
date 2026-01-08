//
//  VideoGenerationJob.swift
//  DailyVideos
//
//  Created by Claude on 1/7/26.
//

import Foundation
import CoreGraphics

/// Status of a video generation job
enum VideoGenerationStatus: Equatable {
    case preparing
    case composing(progress: Double) // 0.0 to 1.0
    case exporting(progress: Double) // 0.0 to 1.0
    case completed(outputURL: URL)
    case failed(error: String)
    case cancelled

    /// Whether the job is currently active
    var isActive: Bool {
        switch self {
        case .preparing, .composing, .exporting:
            return true
        default:
            return false
        }
    }

    /// Whether the job is finished (success or failure)
    var isFinished: Bool {
        switch self {
        case .completed, .failed, .cancelled:
            return true
        default:
            return false
        }
    }

    /// Overall progress (0.0 to 1.0)
    var overallProgress: Double {
        switch self {
        case .preparing:
            return 0.0
        case .composing(let progress):
            return 0.2 + (progress * 0.3) // 20-50%
        case .exporting(let progress):
            return 0.5 + (progress * 0.5) // 50-100%
        case .completed:
            return 1.0
        default:
            return 0.0
        }
    }

    /// User-friendly status message
    var statusMessage: String {
        switch self {
        case .preparing:
            return "Preparing..."
        case .composing(let progress):
            return "Composing video... \(Int(progress * 100))%"
        case .exporting(let progress):
            return "Exporting... \(Int(progress * 100))%"
        case .completed:
            return "Completed"
        case .failed(let error):
            return "Failed: \(error)"
        case .cancelled:
            return "Cancelled"
        }
    }
}

/// Custom error type for video generation
enum VideoGenerationError: Error, LocalizedError {
    case noMediaSelected
    case assetLoadingFailed(assetId: String)
    case compositionFailed(reason: String)
    case exportFailed(reason: String)
    case insufficientStorage
    case cancelled
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .noMediaSelected:
            return "No media was selected for the video"
        case .assetLoadingFailed(let assetId):
            return "Failed to load asset: \(assetId)"
        case .compositionFailed(let reason):
            return "Video composition failed: \(reason)"
        case .exportFailed(let reason):
            return "Video export failed: \(reason)"
        case .insufficientStorage:
            return "Insufficient storage space for video export"
        case .cancelled:
            return "Video generation was cancelled"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

/// Represents a video generation job
struct VideoGenerationJob: Identifiable {
    let id: UUID
    let timeframe: TimeframeSelection
    let mediaSelections: [DayMediaSelection]
    var status: VideoGenerationStatus
    let createdAt: Date
    var completedAt: Date?

    // Video settings
    var settings: VideoCompositionSettings

    init(
        id: UUID = UUID(),
        timeframe: TimeframeSelection,
        mediaSelections: [DayMediaSelection],
        status: VideoGenerationStatus = .preparing,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        settings: VideoCompositionSettings = .default
    ) {
        self.id = id
        self.timeframe = timeframe
        self.mediaSelections = mediaSelections
        self.status = status
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.settings = settings
    }

    /// Total duration estimate based on media selections
    var estimatedDuration: TimeInterval {
        return mediaSelections.reduce(0.0) { total, selection in
            total + (selection.selectedMedia.duration ?? 3.0) // Default 3s for Live Photos
        }
    }

    /// Total number of clips in the compilation
    var clipCount: Int {
        return mediaSelections.count
    }

    /// Number of days with pinned media
    var pinnedCount: Int {
        return mediaSelections.filter { $0.isPinned }.count
    }

    /// Number of "cheat" pins
    var cheatingPinCount: Int {
        return mediaSelections.filter { $0.isCheating }.count
    }

    /// Duration since job was created
    var elapsedTime: TimeInterval {
        if let completed = completedAt {
            return completed.timeIntervalSince(createdAt)
        }
        return Date().timeIntervalSince(createdAt)
    }

    /// Human-readable duration estimate
    var estimatedDurationString: String {
        let minutes = Int(estimatedDuration) / 60
        let seconds = Int(estimatedDuration) % 60

        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }
}
