//
//  VideoExportService.swift
//  DailyVideos
//
//  Created by Claude on 1/7/26.
//

import Foundation
import Photos
import UIKit

/// Service for exporting and sharing generated videos
actor VideoExportService {
    static let shared = VideoExportService()

    private init() {}

    // MARK: - Save to Photos Library

    /// Save video to Photos library
    /// - Parameter videoURL: URL of the video file
    /// - Throws: Export errors
    func saveToPhotoLibrary(_ videoURL: URL) async throws {
        // Verify file exists
        guard FileManager.default.fileExists(atPath: videoURL.path) else {
            throw VideoExportError.fileNotFound
        }

        // Check permissions
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        switch status {
        case .notDetermined:
            // Request permission
            let granted = await PHPhotoLibrary.requestAuthorization(for: .addOnly) == .authorized
            if !granted {
                throw VideoExportError.permissionDenied
            }

        case .restricted, .denied:
            throw VideoExportError.permissionDenied

        case .authorized, .limited:
            break

        @unknown default:
            throw VideoExportError.permissionDenied
        }

        // Save to library
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                PHAssetCreationRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }) { success, error in
                if success {
                    continuation.resume()
                } else if let error = error {
                    continuation.resume(throwing: VideoExportError.saveFailed(reason: error.localizedDescription))
                } else {
                    continuation.resume(throwing: VideoExportError.saveFailed(reason: "Unknown error"))
                }
            }
        }
    }

    // MARK: - Share Sheet

    /// Get a share item for the video
    /// - Parameter videoURL: URL of the video file
    /// - Returns: Array of items to share (for UIActivityViewController)
    func getShareItems(for videoURL: URL) -> [Any] {
        return [videoURL]
    }

    // MARK: - Cleanup

    /// Clean up temporary video files
    /// - Parameter url: URL of the temporary file
    func cleanupTemporaryFile(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    /// Get file size of video
    /// - Parameter url: URL of the video file
    /// - Returns: File size in bytes, or nil if file doesn't exist
    func getFileSize(of url: URL) -> Int64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64 else {
            return nil
        }
        return fileSize
    }

    /// Format file size for display
    /// - Parameter bytes: Size in bytes
    /// - Returns: Formatted string (e.g., "25.3 MB")
    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Export Errors

enum VideoExportError: Error, LocalizedError {
    case fileNotFound
    case permissionDenied
    case saveFailed(reason: String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Video file not found"
        case .permissionDenied:
            return "Permission to access Photos library was denied. Please grant access in Settings."
        case .saveFailed(let reason):
            return "Failed to save video: \(reason)"
        }
    }
}
