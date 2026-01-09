//
//  PinMediaSelectionView.swift
//  DailyVideos
//
//  Created by Claude on 1/7/26.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif
#if os(macOS)
import AppKit
#endif

/// View for selecting media from nearby dates to pin to a target date
struct PinMediaSelectionView: View {
    let targetDate: Date
    let nearbyMediaByDate: [Date: [MediaItem]]
    @Binding var selectedSourceDate: Date?
    let isLoading: Bool
    let onPin: (String, Date) -> Void
    let onCancel: () -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // Platform-specific toolbar placements
    #if os(iOS)
    private let leadingPlacement: ToolbarItemPlacement = .navigationBarLeading
    #else
    private let leadingPlacement: ToolbarItemPlacement = .automatic
    #endif

    private var sortedDates: [Date] {
        nearbyMediaByDate.keys.sorted { date1, date2 in
            let distance1 = abs(date1.timeIntervalSince(targetDate))
            let distance2 = abs(date2.timeIntervalSince(targetDate))
            return distance1 < distance2
        }
    }

    private var selectedMedia: [MediaItem] {
        guard let selectedDate = selectedSourceDate else { return [] }
        return nearbyMediaByDate[selectedDate] ?? []
    }

    private var columns: [GridItem] {
        let count = horizontalSizeClass == .regular ? 5 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: count)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Target date header
                targetDateHeader
                    .padding()
                    .background(
                        {
                            #if os(iOS) || os(visionOS)
                            Color(UIColor.systemGroupedBackground)
                            #elseif os(macOS)
                            Color(NSColor.windowBackgroundColor)
                            #endif
                        }()
                    )

                Divider()

                if isLoading {
                    loadingView
                } else if sortedDates.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 0) {
                        // Date selection (horizontal scroll)
                        dateSelectionSection
                            .padding(.vertical, 12)
                            .background(
                                {
                                    #if os(iOS) || os(visionOS)
                                    Color(UIColor.systemGroupedBackground)
                                    #elseif os(macOS)
                                    Color(NSColor.windowBackgroundColor)
                                    #endif
                                }()
                            )

                        Divider()

                        // Media grid for selected date
                        if let sourceDate = selectedSourceDate {
                            mediaGridSection(for: sourceDate)
                        } else {
                            placeholderSection
                        }
                    }
                }
            }
            .navigationTitle("Pin Media")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: leadingPlacement) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }

    private var targetDateHeader: some View {
        VStack(spacing: 4) {
            Text("Pin media to")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(formattedDate(targetDate))
                .font(.headline)
                .foregroundColor(.primary)
        }
    }

    private var dateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Choose a nearby date")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(sortedDates, id: \.self) { date in
                        dateCard(for: date)
                            .onTapGesture {
                                selectedSourceDate = date
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func dateCard(for date: Date) -> some View {
        let isSelected = selectedSourceDate == date
        let mediaCount = nearbyMediaByDate[date]?.count ?? 0
        let dayDifference = Calendar.current.dateComponents([.day], from: targetDate, to: date).day ?? 0

        return VStack(spacing: 8) {
            // Date label
            VStack(spacing: 2) {
                Text(monthDayFormatter.string(from: date))
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(isSelected ? .white : .primary)

                Text(weekdayFormatter.string(from: date))
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }

            // Distance indicator
            Text(distanceLabel(dayDifference))
                .font(.caption2)
                .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)

            // Media count
            Text("\(mediaCount) \(mediaCount == 1 ? "item" : "items")")
                .font(.caption2)
                .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            isSelected ? Color.blue : {
                #if os(iOS)
                Color(UIColor.secondarySystemGroupedBackground)
                #elseif os(macOS)
                Color(NSColor.underPageBackgroundColor)
                #else
                Color(.secondarySystemGroupedBackground)
                #endif
            }()
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }

    private func mediaGridSection(for sourceDate: Date) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(selectedMedia) { item in
                    GeometryReader { geometry in
                        MediaThumbnailView(
                            mediaItem: item,
                            showPinBadge: false,
                            showCrossDatePinBadge: false,
                            pinSourceDate: nil
                        )
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            #if os(iOS)
                            // Haptic feedback
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            #endif

                            // Pin this media
                            onPin(item.assetIdentifier, sourceDate)
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                }
            }
            .padding()
        }
        .background(
            {
                #if os(iOS)
                Color(UIColor.systemBackground)
                #elseif os(macOS)
                Color(NSColor.windowBackgroundColor)
                #else
                Color(.systemBackground)
                #endif
            }()
        )
    }

    private var placeholderSection: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("Select a date to see media")
                .font(.headline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Finding nearby media...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            VStack(spacing: 8) {
                Text("No Nearby Media Found")
                    .font(.headline)

                Text("There are no videos or Live Photos within 7 days of this date.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            Spacer()
        }
    }

    // MARK: - Formatters

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private var monthDayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }

    private var weekdayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }

    private func distanceLabel(_ days: Int) -> String {
        if days == 0 {
            return "today"
        } else if days > 0 {
            return "\(days)d later"
        } else {
            return "\(abs(days))d ago"
        }
    }
}

#Preview {
    PinMediaSelectionView(
        targetDate: Date(),
        nearbyMediaByDate: [:],
        selectedSourceDate: .constant(nil),
        isLoading: false,
        onPin: { _, _ in },
        onCancel: {}
    )
}

