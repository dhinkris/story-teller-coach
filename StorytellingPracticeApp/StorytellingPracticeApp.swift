import SwiftUI

@main
struct StorytellingPracticeApp: App {
    init() {
        AudioRecorderService.cleanUpStaleRecordings()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
