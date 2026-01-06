import SwiftUI

struct DayCell: View {
    let calendarDay: CalendarDay
    let isToday: Bool

    @State private var thumbnail: UIImage?
    @State private var isLoadingThumbnail = false
    @State private var isPressed = false

    var body: some View {
        ZStack {
            // Background with thumbnail or plain color
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .opacity(calendarDay.isInCurrentMonth ? 1.0 : 0.3)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                backgroundColor
            }

            // Gradient overlay for better text visibility
            if thumbnail != nil {
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.5), Color.clear]),
                    startPoint: .top,
                    endPoint: .center
                )
            }

            // Day number overlay
            VStack {
                HStack {
                    Text("\(calendarDay.day)")
                        .font(.system(size: 14, weight: isToday ? .bold : .semibold))
                        .foregroundColor(thumbnail != nil ? .white : textColor)
                        .shadow(radius: thumbnail != nil ? 2 : 0)
                        .padding(4)
                    Spacer()
                }
                Spacer()
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
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .animation(.easeInOut(duration: 0.3), value: thumbnail != nil)
        .onAppear {
            loadThumbnailIfNeeded()
        }
        .onChange(of: calendarDay.representativeAssetIdentifier) { oldValue, newValue in
            loadThumbnailIfNeeded()
        }
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

    private func loadThumbnailIfNeeded() {
        guard let assetIdentifier = calendarDay.representativeAssetIdentifier,
              !isLoadingThumbnail else {
            return
        }

        isLoadingThumbnail = true
        let size = CGSize(width: 150, height: 150)

        PhotoLibraryManager.shared.getThumbnail(for: assetIdentifier, size: size) { image in
            self.thumbnail = image
            self.isLoadingThumbnail = false
        }
    }
}

