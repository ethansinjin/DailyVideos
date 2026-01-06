import SwiftUI
internal import Photos

struct ContentView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var selectedDayDetail: DayDetail?
    @State private var showingSettings = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { viewModel.goToPreviousMonth() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                    }
                }

                ToolbarItem(placement: .principal) {
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
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
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
        .sheet(item: $selectedDayDetail) { dayDetail in
            DayDetailView(
                day: dayDetail.day,
                mediaItems: dayDetail.mediaItems,
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
                                    .background(Color(.systemBackground).opacity(0.8))
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
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

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
