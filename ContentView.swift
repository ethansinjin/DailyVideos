import SwiftUI

struct ContentView: View {
    var body: some View {
        LazyVGrid(columns: [
         GridItem(.flexible()), 
         GridItem(.flexible()),
         GridItem(.flexible()),
         GridItem(.flexible()),
         GridItem(.flexible()),
         GridItem(.flexible()),
         GridItem(.flexible())
        ]) {
            ForEach(1..<31) { i in
                DayCell(day: i)
            }
        }
    }
}
