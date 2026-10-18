/*
 * Main Tab View
 * 主 Tab 导航视图
 */

import SwiftUI

struct MainTabView: View {
    @ObservedObject var streamViewModel: StreamSessionViewModel
    @ObservedObject var wearablesViewModel: WearablesViewModel

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home - Feature entry
            TurboMetaHomeView(streamViewModel: streamViewModel, wearablesViewModel: wearablesViewModel)
                .tabItem {
                    Label("tab.home".localized, systemImage: "house")
                }
                .tag(0)

            // Records
            RecordsView()
                .tabItem {
                    Label("tab.records".localized, systemImage: "list.bullet.rectangle")
                }
                .tag(1)

            // Gallery
            GalleryView()
                .tabItem {
                    Label("tab.gallery".localized, systemImage: "rectangle.stack")
                }
                .tag(2)

            // Settings
            SettingsView(streamViewModel: streamViewModel)
                .tabItem {
                    Label("tab.settings".localized, systemImage: "slider.horizontal.3")
                }
                .tag(3)
        }
        .tint(Color.primary)
        .toolbarBackground(Color(red: 0.957, green: 0.953, blue: 0.933), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
