import SwiftUI
import AVFoundation

// MARK: - TTS Player Service

class TTSPlayerService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var isSpeaking = false
    @Published var isPaused = false

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(text: String) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.50
        utterance.pitchMultiplier = 1.05
        synthesizer.speak(utterance)
        isSpeaking = true
        isPaused = false
    }

    func pause() {
        synthesizer.pauseSpeaking(at: .word)
        isPaused = true
        isSpeaking = false
    }

    func resume() {
        synthesizer.continueSpeaking()
        isPaused = false
        isSpeaking = true
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        isPaused = false
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false; self.isPaused = false }
    }
}

struct StoryConsumptionView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCategory: StoryCategory? = nil
    @State private var selectedStory: Story? = nil

    private var filteredStories: [Story] {
        if let category = selectedCategory {
            return Story.sampleStories.filter { $0.category == category }
        }
        return Story.sampleStories
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.clayBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Category filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            CategoryFilterChip(
                                title: "All",
                                icon: "square.grid.2x2",
                                color: Color.clayAccent,
                                isSelected: selectedCategory == nil
                            ) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    selectedCategory = nil
                                }
                            }

                            ForEach(StoryCategory.allCases) { category in
                                CategoryFilterChip(
                                    title: category.rawValue,
                                    icon: category.icon,
                                    color: category.themeColor,
                                    isSelected: selectedCategory == category
                                ) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        selectedCategory = category
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 4)
                    }
                    .padding(.vertical, 14)

                    // Stories list
                    if filteredStories.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredStories) { story in
                                    StoryCard(story: story) {
                                        selectedStory = story
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                            .padding(.bottom, 28)
                        }
                    }
                }
            }
            .navigationTitle("Library")
            .sheet(item: $selectedStory) { story in
                StoryDetailView(story: story)
                    .environmentObject(appState)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.clayCard)
                    .frame(width: 110, height: 110)
                    .shadow(color: Color.clayShadow,      radius: 15, x: 8,  y: 8)
                    .shadow(color: Color.clayShadowLight, radius: 15, x: -8, y: -8)
                Image(systemName: "books.vertical")
                    .font(.system(size: 44))
                    .foregroundColor(Color.clayAccent)
            }
            Text("No stories in this category")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Category Filter Chip

struct CategoryFilterChip: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(isSelected ? color : Color.clayCard)
                    .shadow(
                        color: isSelected ? color.opacity(0.30) : Color.clayShadow,
                        radius: isSelected ? 8 : 6,
                        x: 0, y: isSelected ? 4 : 3
                    )
                    .shadow(
                        color: isSelected ? .clear : Color.clayShadowLight,
                        radius: 6, x: -3, y: -3
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .animation(.spring(response: 0.28), value: isSelected)
    }
}

// MARK: - Story Card

struct StoryCard: View {
    let story: Story
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Thumbnail image or gradient fallback
                ZStack(alignment: .bottomLeading) {
                    if let name = story.thumbnailName,
                       let uiImage = UIImage(named: name) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 160)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(story.category.themeGradient)
                            .frame(height: 160)
                    }
                    // Gradient scrim for legibility
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.55)],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 160)

                    HStack(spacing: 6) {
                        Image(systemName: story.category.icon)
                            .font(.system(size: 11, weight: .bold))
                        Text(story.category.rawValue.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .kerning(0.8)
                        Spacer()
                        if story.duration > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "timer")
                                    .font(.system(size: 10))
                                Text(readTime(story.duration))
                                    .font(.system(size: 10, weight: .semibold))
                            }
                        }
                    }
                    .foregroundColor(.white.opacity(0.92))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }

                // Body
                VStack(alignment: .leading, spacing: 10) {
                    Text(story.title)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    Text(story.content)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .lineSpacing(3)

                    HStack(spacing: 5) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 11))
                        Text("Tap to read & practice")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(story.category.themeColor)
                }
                .padding(18)
                .background(Color.clayCard)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: Color.clayShadow,      radius: 12, x: 5,  y: 5)
            .shadow(color: Color.clayShadowLight, radius: 12, x: -5, y: -5)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func readTime(_ duration: TimeInterval) -> String {
        let minutes = max(1, Int(duration) / 60)
        return "\(minutes) min read"
    }
}

// MARK: - Story Detail

struct StoryDetailView: View {
    let story: Story
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    @StateObject private var player = AudioPlayerService()
    @StateObject private var tts = TTSPlayerService()
    @State private var audioLoaded = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.clayBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Hero header
                        ZStack(alignment: .bottomLeading) {
                            if let name = story.thumbnailName,
                               let uiImage = UIImage(named: name) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 240)
                                    .clipped()
                            } else {
                                Rectangle()
                                    .fill(story.category.themeGradient)
                                    .frame(height: 240)
                            }
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.72)],
                                startPoint: .center, endPoint: .bottom
                            )
                            .frame(height: 240)

                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 7) {
                                    Image(systemName: story.category.icon)
                                        .font(.system(size: 12, weight: .bold))
                                    Text(story.category.rawValue.uppercased())
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .kerning(1.0)
                                    Spacer()
                                    if story.duration > 0 {
                                        HStack(spacing: 5) {
                                            Image(systemName: "timer")
                                                .font(.system(size: 12))
                                            Text(readTime(story.duration))
                                                .font(.caption)
                                                .fontWeight(.medium)
                                        }
                                    }
                                }
                                .foregroundColor(.white.opacity(0.85))

                                Text(story.title)
                                    .font(.system(size: 26, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .padding(24)
                        }

                        // Story text
                        Text(story.content)
                            .font(.system(.body, design: .serif))
                            .lineSpacing(9)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                            .padding(.bottom, 12)

                        // Retell CTA
                        Button(action: {
                            appState.pendingRetellingStory = story
                            appState.selectedTab = 1
                            dismiss()
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "mic.fill")
                                Text("Retell This Story")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 17)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    colors: [Color.clayAccent, Color.clayAccentLight],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(24)
                            .shadow(color: Color.clayAccent.opacity(0.28), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100) // room for the floating player
                    }
                }

                // Floating audio player bar
                floatingPlayer
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color.clayAccent)
                }
            }
        }
    }

    private func readTime(_ duration: TimeInterval) -> String {
        let minutes = max(1, Int(duration) / 60)
        return "\(minutes) min read"
    }
}

// MARK: - Audio Player View

struct AudioPlayerView: View {
    let story: Story

    @StateObject private var player = AudioPlayerService()
    @StateObject private var tts = TTSPlayerService()   // fallback when no bundled audio
    @State private var loaded = false

    var body: some View {
        VStack(spacing: 20) {
            if loaded {
                bundledPlayerView
            } else {
                fallbackPlayerView
            }
        }
        .frame(maxWidth: .infinity)
        .clayCard(cornerRadius: 24, padding: 24)
        .onAppear {
            if let url = story.audioURL, (try? player.loadAudio(from: url)) != nil {
                loaded = true
            }
        }
        .onDisappear {
            player.stop()
            tts.stop()
        }
    }

    // MARK: - Bundled MP3 player

    private var bundledPlayerView: some View {
        VStack(spacing: 20) {
            HStack(spacing: 28) {
                Button(action: {
                    if player.isPlaying { player.pause() } else { player.play() }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.clayCard)
                            .frame(width: 90, height: 90)
                            .shadow(color: Color.clayShadow,      radius: 20, x: 10,  y: 10)
                            .shadow(color: Color.clayShadowLight, radius: 20, x: -10, y: -10)
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color.clayAccent)
                    }
                }

                if player.isPlaying || player.currentTime > 0 {
                    Button(action: { player.stop() }) {
                        ZStack {
                            Circle()
                                .fill(Color.claySurface)
                                .frame(width: 52, height: 52)
                                .shadow(color: Color.clayShadow, radius: 8, x: 4, y: 4)
                                .shadow(color: Color.clayShadowLight, radius: 8, x: -4, y: -4)
                            Image(systemName: "stop.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            if player.duration > 0 {
                VStack(spacing: 6) {
                    Slider(
                        value: Binding(
                            get: { player.currentTime },
                            set: { player.seek(to: $0) }
                        ),
                        in: 0...player.duration
                    )
                    .tint(story.category.themeColor)

                    HStack {
                        Text(formatTime(player.currentTime))
                        Spacer()
                        Text(formatTime(player.duration))
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "waveform")
                    .font(.system(size: 13))
                    .foregroundColor(Color.clayAccent.opacity(0.7))
                Text(player.isPlaying ? "Listening…" : "Tap to listen")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - System TTS fallback

    private var fallbackPlayerView: some View {
        VStack(spacing: 20) {
            HStack(spacing: 28) {
                Button(action: {
                    if tts.isSpeaking {
                        tts.pause()
                    } else if tts.isPaused {
                        tts.resume()
                    } else {
                        tts.speak(text: story.content)
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.clayCard)
                            .frame(width: 90, height: 90)
                            .shadow(color: Color.clayShadow,      radius: 20, x: 10,  y: 10)
                            .shadow(color: Color.clayShadowLight, radius: 20, x: -10, y: -10)
                        Image(systemName: tts.isSpeaking ? "pause.fill" : "play.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color.clayAccent)
                    }
                }

                if tts.isSpeaking || tts.isPaused {
                    Button(action: { tts.stop() }) {
                        ZStack {
                            Circle()
                                .fill(Color.claySurface)
                                .frame(width: 52, height: 52)
                                .shadow(color: Color.clayShadow, radius: 8, x: 4, y: 4)
                                .shadow(color: Color.clayShadowLight, radius: 8, x: -4, y: -4)
                            Image(systemName: "stop.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Text(tts.isSpeaking ? "Listening…" : tts.isPaused ? "Paused" : "Tap to listen")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Helpers

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}

#Preview {
    StoryConsumptionView()
}
