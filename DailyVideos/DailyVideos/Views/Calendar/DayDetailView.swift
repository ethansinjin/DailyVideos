import SwiftUI

struct DayDetailView: View {
    let day: CalendarDay
    let mediaItems: [MediaItem]
    let onDismiss: () -> Void

    @State private var selectedMedia: SelectedMedia?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var columns: [GridItem] {
        let count = horizontalSizeClass == .regular ? 5 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: count)
    }

    private struct SelectedMedia: Identifiable {
        let id = UUID()
        let index: Int
    }

    var body: some View {
        NavigationStack {
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
                                GeometryReader { geometry in
                                    MediaThumbnailView(mediaItem: item)
                                        .frame(width: geometry.size.width, height: geometry.size.width)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedMedia = SelectedMedia(index: index)
                                        }
                                }
                                .aspectRatio(1, contentMode: .fit)
                                .clipped()
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
        .fullScreenCover(item: $selectedMedia) { selected in
            MediaDetailView(
                mediaItems: mediaItems,
                initialIndex: selected.index,
                onDismiss: {
                    selectedMedia = nil
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

#Preview("With Media") {
    DayDetailView(
        day: .sampleDayWithMedia,
        mediaItems: MediaItem.sampleMediaItems,
        onDismiss: {}
    )
}

#Preview("Empty") {
    DayDetailView(
        day: .sampleDayWithoutMedia,
        mediaItems: [],
        onDismiss: {}
    )
}

