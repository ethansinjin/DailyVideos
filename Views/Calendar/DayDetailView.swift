import SwiftUI

struct DayDetailView: View {
    let day: CalendarDay
    let mediaItems: [MediaItem]
    let onDismiss: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with date and count
                VStack(spacing: 8) {
                    Text(formattedDate)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("\(mediaItems.count) \(mediaItems.count == 1 ? "item" : "items")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()

                if mediaItems.isEmpty {
                    // Empty state
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No videos or Live Photos")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    // Media grid
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(mediaItems) { item in
                                MediaThumbnailView(mediaItem: item)
                                    .aspectRatio(1, contentMode: .fill)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: day.date)
    }
}
