import SwiftUI
internal import Photos
#if os(iOS)
import UIKit
#endif

struct ContentView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var selectedDayDetail: DayDetail?
    @State private var showingSettings = false
    @AppStorage("navigationControlsPosition") private var navigationControlsPosition: NavigationControlsPosition = .bottom

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    // Platform-specific toolbar placements
    #if os(iOS)
    private let leadingPlacement: ToolbarItemPlacement = .navigationBarLeading
    private let trailingPlacement: ToolbarItemPlacement = .navigationBarTrailing
    private let bottomPlacement: ToolbarItemPlacement = .bottomBar
    #else
    private let leadingPlacement: ToolbarItemPlacement = .automatic
    private let trailingPlacement: ToolbarItemPlacement = .automatic
    private let bottomPlacement: ToolbarItemPlacement = .automatic
    #endif

    private struct DayDetail: Identifiable {
        let id = UUID()
        let day: CalendarDay
        let mediaItems: [MediaItem]
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.permissionStatus == .denied {
                    // Show permission request view
                    PermissionRequestView()
                } else {
                    // Show calendar
                    calendarView
                }
            }
            .navigationTitle(viewModel.currentMonth.displayString)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                if navigationControlsPosition == .bottom {
                    // Bottom toolbar mode - settings only in top bar
                    ToolbarItem(placement: trailingPlacement) {
                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gear")
                                .foregroundColor(.primary)
                        }
                    }

                    ToolbarItem(placement: bottomPlacement) {
                        HStack(spacing: 20) {
                            Button(action: { viewModel.goToPreviousMonth() }) {
                                Image(systemName: "chevron.left")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button(action: { viewModel.goToToday() }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar.circle.fill")
                                        .font(.subheadline)
                                    Text("Today")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background {
                                    Capsule()
                                        .fill(.blue.gradient)
                                        .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                                }
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Button(action: { viewModel.goToNextMonth() }) {
                                Image(systemName: "chevron.right")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    // Top navigation bar mode - all controls in top bar
                    ToolbarItem(placement: leadingPlacement) {
                        Button(action: { viewModel.goToPreviousMonth() }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.blue)
                        }
                    }

                    ToolbarItem(placement: trailingPlacement) {
                        HStack(spacing: 12) {
                            Button(action: { viewModel.goToToday() }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar.circle.fill")
                                        .font(.caption)
                                    Text("Today")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background {
                                    Capsule()
                                        .fill(.blue.gradient)
                                        .shadow(color: .blue.opacity(0.3), radius: 3, x: 0, y: 1)
                                }
                            }
                            .buttonStyle(.plain)

                            Button(action: { viewModel.goToNextMonth() }) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.blue)
                            }

                            Button(action: { showingSettings = true }) {
                                Image(systemName: "gear")
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedDayDetail) { dayDetail in
            DayDetailView(
                day: dayDetail.day,
                mediaItems: dayDetail.mediaItems,
                viewModel: viewModel,
                onDismiss: {
                    selectedDayDetail = nil
                    viewModel.selectedDay = nil
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var calendarView: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Day of week labels and calendar grid container
                    VStack(spacing: 0) {
                        // Day of week labels
                        DayOfWeekLabels(weekdaySymbols: viewModel.weekdaySymbols())
                            .padding(.top, 8)
                            .padding(.bottom, 8)

                        // Calendar grid with size-appropriate constraints
                        ZStack {
                            LazyVGrid(columns: columns, spacing: 4) {
                                ForEach(viewModel.currentMonth.days) { day in
                                    DayCell(
                                        calendarDay: day,
                                        isToday: viewModel.isToday(day.date)
                                    )
                                    .onTapGesture {
                                        handleDayTap(day)
                                    }
                                }
                            }

                            // Loading indicator
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .padding()
                                    #if os(iOS) || os(visionOS)
                                    .background(Color(uiColor: .systemBackground).opacity(0.8))
                                    #elseif os(macOS)
                                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.8))
                                    #endif
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: min(geometry.size.width, 800))

                    Spacer(minLength: 20)
                }
                .padding(.top)
                .frame(maxWidth: .infinity)
            }
            .refreshable {
                await refreshCalendar()
            }
        }
    }

    private func refreshCalendar() async {
        await withCheckedContinuation { continuation in
            viewModel.refreshMediaData()
            // Give a small delay to ensure UI updates
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume()
            }
        }
    }

    private func handleDayTap(_ day: CalendarDay) {
        // Haptic feedback
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif

        viewModel.selectDay(day)
        // Load media items for the selected day on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            let items = viewModel.getMediaItems(for: day)
            DispatchQueue.main.async {
                // Only present sheet after media items are loaded
                selectedDayDetail = DayDetail(day: day, mediaItems: items)
            }
        }
    }
}

#Preview {
    ContentView()
}
