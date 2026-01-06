import SwiftUI

struct DayCell: View {
    let calendarDay: CalendarDay
    let isToday: Bool

    var body: some View {
        VStack(spacing: 4) {
            // Day number
            Text("\(calendarDay.day)")
                .font(.system(size: 16, weight: isToday ? .bold : .regular))
                .foregroundColor(textColor)

            // Media indicator (placeholder for Phase 2)
            if calendarDay.hasMedia {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 6, height: 6)
            } else {
                Spacer()
                    .frame(height: 6)
            }
        }
        .frame(height: 60)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: isToday ? 2 : 0)
        )
    }

    private var textColor: Color {
        if !calendarDay.isInCurrentMonth {
            return .gray.opacity(0.4)
        }
        return isToday ? .blue : .primary
    }

    private var backgroundColor: Color {
        if calendarDay.hasMedia && calendarDay.isInCurrentMonth {
            return Color.blue.opacity(0.1)
        }
        return Color.clear
    }

    private var borderColor: Color {
        isToday ? .blue : .clear
    }
}
