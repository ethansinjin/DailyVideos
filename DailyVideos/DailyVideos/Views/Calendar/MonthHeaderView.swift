import SwiftUI

struct MonthHeaderView: View {
    let monthData: MonthData
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToday: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Navigation row
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
                Text(monthData.displayString)
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                // Next month button
                Button(action: onNext) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }

            // Today button with liquid glass style
            Button(action: onToday) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.circle.fill")
                        .font(.subheadline)
                    Text("Today")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(.blue.gradient)
                        .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

#Preview {
    MonthHeaderView(
        monthData: .sampleMonth,
        onPrevious: {},
        onNext: {},
        onToday: {}
    )
    .padding()
}
