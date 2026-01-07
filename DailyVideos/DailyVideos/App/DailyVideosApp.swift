//
//  DailyVideosApp.swift
//  DailyVideos
//
//  Created by Ethan Gill on 1/6/26.
//

import SwiftUI
import SwiftData

@main
struct DailyVideosApp: App {
    // SwiftData model container
    let modelContainer: ModelContainer

    init() {
        do {
            // Configure SwiftData model container with both models
            modelContainer = try ModelContainer(for: PreferredMedia.self, PinnedMedia.self)

            // Inject model context into managers
            PreferencesManager.shared.setModelContext(modelContainer.mainContext)
            PinnedMediaManager.shared.setModelContext(modelContainer.mainContext)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(modelContainer)
    }
}
