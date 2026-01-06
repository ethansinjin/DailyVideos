import SwiftUI

struct MonthHeaderView: View {
    let monthData: MonthData
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToday: () -> Void

    var body: some View {
        HStack {
            // Previous month button
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)

            Spacer()

            // Month and year display
            VStack(spacing: 4) {
                Text(monthData.displayString)
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            Spacer()

            // Next month button
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
            // Today button in the center bottom
            Button(action: onToday) {
                Text("Today")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            .offset(y: 20)
        }
    }
}
