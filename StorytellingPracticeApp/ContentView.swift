import SwiftUI

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            StoryConsumptionView()
                .tabItem {
                    Label("Stories", systemImage: "book.fill")
                }
                .tag(0)
            
            StoryRetellingView()
                .tabItem {
                    Label("Retelling", systemImage: "mic.fill")
                }
                .tag(1)
            
            FreePracticeView()
                .tabItem {
                    Label("Practice", systemImage: "sparkles")
                }
                .tag(2)
            
            ProgressTrackingView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
                .tag(3)
        }
        .tint(Color.clayAccent)
    }
}

#Preview {
    ContentView()
}
