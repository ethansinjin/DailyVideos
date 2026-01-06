import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CalendarViewModel()

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
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
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(viewModel.currentMonth.days) { day in
                    DayCell(
                        calendarDay: day,
                        isToday: viewModel.isToday(day.date)
                    )
                    .onTapGesture {
                        viewModel.selectDay(day)
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top)
    }
}
