//
//  MainTabView.swift
//  DailyVideos
//
//  Created by Claude on 1/7/26.
//

import SwiftUI

/// Main tab view containing Calendar and Video Generation tabs
struct MainTabView: View {
    var body: some View {
        TabView {
            // Calendar Tab
            ContentView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            // Video Generation Tab
            VideoGenerationView()
                .tabItem {
                    Label("Generate", systemImage: "film.stack")
                }
        }
    }
}

#Preview {
    MainTabView()
}
