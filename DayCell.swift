import SwiftUI

struct DayCell: View {
    var day: Int
    var body: some View {
        GroupBox(label: DayCellLabel(day: day)) {
            Image(systemName: "video") 
        }
    }
}

struct DayCellLabel: View {
    var day: Int
    var body: some View {
        Text(String(day)).foregroundStyle(.red)
    }
}
