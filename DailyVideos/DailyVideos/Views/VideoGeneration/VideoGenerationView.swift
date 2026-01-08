//
//  VideoGenerationView.swift
//  DailyVideos
//
//  Created by Claude on 1/7/26.
//

import SwiftUI

/// Main view for video generation tab
struct VideoGenerationView: View {
    @StateObject private var viewModel = VideoGenerationViewModel()
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Timeframe Selection
                    timeframeSelectionSection

                    // Media Selection Preview or Empty State
                    if viewModel.isLoadingSelections {
                        loadingView
                    } else if viewModel.mediaSelections.isEmpty {
                        emptySelectionView
                    } else {
                        mediaSelectionPreviewSection
                        videoSettingsSection
                        generateButton
                    }

                    // Generation Progress
                    if viewModel.isGenerating {
                        generationProgressView
                    }

                    // Video Result
                    if let _ = viewModel.generatedVideoURL {
                        videoResultView
                    }

                    // Error Display
                    if let error = viewModel.error {
                        errorView(error)
                    }
                }
                .padding()
            }
            .navigationTitle("Generate Video")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingShareSheet) {
            if !shareItems.isEmpty {
                ShareSheet(items: shareItems)
            }
        }
        .task(id: showingShareSheet) {
            if showingShareSheet {
                shareItems = await viewModel.getShareItems()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Create a Video Compilation")
                .font(.title2)
                .fontWeight(.bold)

            Text("Select a timeframe and compile one media per day into a single video.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Timeframe Selection Section (Placeholder)

    private var timeframeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Timeframe")
                .font(.headline)

            // TODO: Phase 3 - Implement full TimeframeSelectionSection
            // For now, show basic info
            if let timeframe = viewModel.selectedTimeframe {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                    Text(timeframe.displayName)
                        .font(.body)

                    Spacer()

                    Text("\(timeframe.dayCount) days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }

            Button(action: {
                Task {
                    await viewModel.loadMediaSelections()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                    Text("Load Media")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(viewModel.isLoadingSelections)
        }
    }

    // MARK: - Empty Selection View

    private var emptySelectionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "film.stack")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Media Selected")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Select a timeframe and tap 'Load Media' to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading media...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Media Selection Preview Section (Placeholder)

    private var mediaSelectionPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Selected Media")
                    .font(.headline)

                Spacer()

                if let summary = viewModel.timeframeSummary {
                    Text(summary.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // TODO: Phase 4 - Implement full MediaSelectionPreviewSection
            // For now, show simple list
            VStack(spacing: 8) {
                ForEach(Array(viewModel.mediaSelections.prefix(5)), id: \.id) { selection in
                    HStack {
                        Image(systemName: selection.selectedMedia.mediaType == .video ? "video.fill" : "livephoto")
                            .foregroundColor(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(formatDate(selection.date))
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text(selection.reasonLabel)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if let duration = selection.selectedMedia.duration {
                            Text(formatDuration(duration))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }

                if viewModel.mediaSelections.count > 5 {
                    Text("+ \(viewModel.mediaSelections.count - 5) more days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                }
            }
        }
    }

    // MARK: - Video Settings Section (Placeholder)

    private var videoSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Video Settings")
                .font(.headline)

            // TODO: Phase 6 - Implement full VideoSettingsSection
            // For now, show basic info
            HStack {
                Image(systemName: "gearshape")
                    .foregroundColor(.gray)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Resolution: \(viewModel.compositionSettings.resolution.displayName)")
                        .font(.subheadline)

                    Text("Transition: \(viewModel.compositionSettings.transitionStyle.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button(action: {
            Task {
                await viewModel.generateVideo()
            }
        }) {
            HStack {
                Image(systemName: "film")
                Text("Generate Video")

                if let summary = viewModel.timeframeSummary {
                    Text("(\(summary.durationString))")
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .fontWeight(.semibold)
        }
        .disabled(viewModel.isGenerating || viewModel.mediaSelections.isEmpty)
        .opacity(viewModel.isGenerating || viewModel.mediaSelections.isEmpty ? 0.6 : 1.0)
    }

    // MARK: - Generation Progress View (Placeholder)

    private var generationProgressView: some View {
        VStack(spacing: 16) {
            Text(viewModel.currentJob?.status.statusMessage ?? "Generating...")
                .font(.headline)

            ProgressView(value: viewModel.generationProgress)
                .progressViewStyle(.linear)

            HStack {
                Text("\(Int(viewModel.generationProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button("Cancel") {
                    Task {
                        await viewModel.cancelGeneration()
                    }
                }
                .font(.caption)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Video Result View (Placeholder)

    private var videoResultView: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)

                Text("Video Generated Successfully!")
                    .font(.headline)
            }

            // TODO: Phase 7 - Implement full VideoResultView with player
            Text("Video preview and export options coming in Phase 7")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Button("Save to Photos") {
                    Task {
                        await viewModel.saveVideo()
                    }
                }
                .buttonStyle(.bordered)

                Button("Share") {
                    showingShareSheet = true
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Generate New") {
                    viewModel.reset()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Error View

    private func errorView(_ error: Error) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.red)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Helper Methods

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60

        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Share Sheet

/// UIKit share sheet wrapper for SwiftUI
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

#Preview {
    VideoGenerationView()
}
