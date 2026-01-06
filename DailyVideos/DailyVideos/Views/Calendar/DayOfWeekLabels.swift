import SwiftUI

struct DayOfWeekLabels: View {
    let weekdaySymbols: [String]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    DayOfWeekLabels(weekdaySymbols: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"])
}
