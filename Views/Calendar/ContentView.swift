import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var showingDayDetail = false
    @State private var selectedDayMediaItems: [MediaItem] = []

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        Group {
            if viewModel.permissionStatus == .denied {
                // Show permission request view
                PermissionRequestView()
            } else {
                // Show calendar
                calendarView
            }
        }
        .sheet(isPresented: $showingDayDetail) {
            if let selectedDay = viewModel.selectedDay {
                DayDetailView(
                    day: selectedDay,
                    mediaItems: selectedDayMediaItems,
                    onDismiss: {
                        showingDayDetail = false
                        viewModel.selectedDay = nil
                    }
                )
            }
        }
    }

    private var calendarView: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Month header with navigation
                MonthHeaderView(
                    monthData: viewModel.currentMonth,
                    onPrevious: { viewModel.goToPreviousMonth() },
                    onNext: { viewModel.goToNextMonth() },
                    onToday: { viewModel.goToToday() }
                )
                .padding(.bottom, 16)

                // Day of week labels
                DayOfWeekLabels(weekdaySymbols: viewModel.weekdaySymbols())
                    .padding(.bottom, 8)

                // Calendar grid
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
                    .padding(.horizontal)

                    // Loading indicator
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                            .background(Color(.systemBackground).opacity(0.8))
                            .cornerRadius(10)
                    }
                }

                Spacer(minLength: 20)
            }
            .padding(.top)
        }
        .refreshable {
            await refreshCalendar()
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
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        viewModel.selectDay(day)
        // Load media items for the selected day on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            let items = viewModel.getMediaItems(for: day)
            DispatchQueue.main.async {
                selectedDayMediaItems = items
                showingDayDetail = true
            }
        }
    }
}
