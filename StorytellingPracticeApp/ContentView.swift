import SwiftUI

// MARK: - Shared App State

class AppState: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var pendingRetellingStory: Story? = nil
}

struct ContentView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        MainTabView()
            .environmentObject(appState)
            .preferredColorScheme(.light)
    }
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    init() {
        // Modern minimalist tab bar
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.05)

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 10, weight: .bold)]
        itemAppearance.selected.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 10, weight: .bold)]

        appearance.stackedLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        // Center icons
        let tabBar = UITabBar.appearance()
        tabBar.itemPositioning = .centered
    }

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            StoryConsumptionView()
                .tabItem { Label("Stories",  systemImage: "sparkles") }
                .tag(0)

            StoryRetellingView()
                .tabItem { Label("Perform",   systemImage: "waveform") }
                .tag(1)

            FreePracticeView()
                .tabItem { Label("Explore", systemImage: "flame.fill") }
                .tag(2)

            ProgressTrackingView()
                .tabItem { Label("Growth",  systemImage: "chart.bar.fill") }
                .tag(3)
        }
        .tint(Color.clayAccent)
    }
}

#Preview {
    ContentView()
}
