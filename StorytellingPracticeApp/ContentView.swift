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
    }
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            StoryConsumptionView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical.fill")
                }
                .tag(0)

            StoryRetellingView()
                .tabItem {
                    Label("Retell", systemImage: "mic.fill")
                }
                .tag(1)

            FreePracticeView()
                .tabItem {
                    Label("Practice", systemImage: "bolt.fill")
                }
                .tag(2)

            ProgressTrackingView()
                .tabItem {
                    Label("Journey", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(3)
        }
        .tint(Color.clayAccent)
    }
}

#Preview {
    ContentView()
}
