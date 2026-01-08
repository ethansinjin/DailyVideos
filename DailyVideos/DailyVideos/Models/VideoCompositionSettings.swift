//
//  VideoCompositionSettings.swift
//  DailyVideos
//
//  Created by Claude on 1/7/26.
//

import Foundation
import CoreGraphics

/// Settings for video composition and export
struct VideoCompositionSettings: Codable, Equatable {
    var resolution: VideoResolution
    var frameRate: Int
    var transitionStyle: TransitionStyle
    var transitionDuration: TimeInterval
    var includeAudio: Bool
    var audioCrossfadeDuration: TimeInterval
    var includeDateOverlay: Bool
    var dateOverlayPosition: OverlayPosition

    /// Default settings for video composition
    static let `default` = VideoCompositionSettings(
        resolution: .resolution1080p,
        frameRate: 30,
        transitionStyle: .crossDissolve,
        transitionDuration: 0.5,
        includeAudio: true,
        audioCrossfadeDuration: 0.3,
        includeDateOverlay: false,
        dateOverlayPosition: .topLeft
    )

    /// Video resolution options
    enum VideoResolution: String, Codable, CaseIterable {
        case resolution720p = "720p"
        case resolution1080p = "1080p"
        case resolution4K = "4K"
        case original = "Original"

        /// Size in pixels
        var size: CGSize {
            switch self {
            case .resolution720p:
                return CGSize(width: 1280, height: 720)
            case .resolution1080p:
                return CGSize(width: 1920, height: 1080)
            case .resolution4K:
                return CGSize(width: 3840, height: 2160)
            case .original:
                return .zero // Will use source resolution
            }
        }

        /// Display name
        var displayName: String {
            switch self {
            case .resolution720p:
                return "720p HD"
            case .resolution1080p:
                return "1080p Full HD"
            case .resolution4K:
                return "4K Ultra HD"
            case .original:
                return "Original Quality"
            }
        }
    }

    /// Transition style between clips
    enum TransitionStyle: String, Codable, CaseIterable {
        case none = "none"
        case crossDissolve = "crossDissolve"
        case fade = "fade"

        /// Display name
        var displayName: String {
            switch self {
            case .none:
                return "None (Hard Cut)"
            case .crossDissolve:
                return "Cross Dissolve"
            case .fade:
                return "Fade to Black"
            }
        }
    }

    /// Position for date overlay
    enum OverlayPosition: String, Codable, CaseIterable {
        case topLeft = "topLeft"
        case topRight = "topRight"
        case bottomLeft = "bottomLeft"
        case bottomRight = "bottomRight"

        /// Display name
        var displayName: String {
            switch self {
            case .topLeft:
                return "Top Left"
            case .topRight:
                return "Top Right"
            case .bottomLeft:
                return "Bottom Left"
            case .bottomRight:
                return "Bottom Right"
            }
        }
    }

    /// Estimated file size multiplier based on resolution
    var fileSizeMultiplier: Double {
        switch resolution {
        case .resolution720p:
            return 1.0
        case .resolution1080p:
            return 2.0
        case .resolution4K:
            return 8.0
        case .original:
            return 2.5 // Average estimate
        }
    }
}
