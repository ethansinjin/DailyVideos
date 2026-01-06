import SwiftUI

struct DayDetailView: View {
    let day: CalendarDay
    let mediaItems: [MediaItem]
    let onDismiss: () -> Void

    @State private var showingMediaDetail = false
    @State private var selectedMediaIndex = 0

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
                        Image(systemName: "video.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        VStack(spacing: 8) {
                            Text("No Videos or Live Photos")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text("Record some memories for this day!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    Spacer()
                } else {
                    // Media grid
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(Array(mediaItems.enumerated()), id: \.element.id) { index, item in
                                MediaThumbnailView(mediaItem: item)
                                    .aspectRatio(1, contentMode: .fill)
                                    .onTapGesture {
                                        selectedMediaIndex = index
                                        showingMediaDetail = true
                                    }
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
        .fullScreenCover(isPresented: $showingMediaDetail) {
            MediaDetailView(
                mediaItems: mediaItems,
                initialIndex: selectedMediaIndex,
                onDismiss: {
                    showingMediaDetail = false
                }
            )
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: day.date)
    }
}
