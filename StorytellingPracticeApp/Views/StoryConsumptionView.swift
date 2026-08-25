import SwiftUI
import AVFoundation
import UIKit

// MARK: - TTS Player Service

class TTSPlayerService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var isSpeaking = false
    @Published var isPaused = false
    @Published var highlightedRange: Range<String.Index>? = nil

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    func speak(text: String) {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.50
        utterance.pitchMultiplier = 1.05
        synthesizer.speak(utterance)
        isSpeaking = true; isPaused = false
    }

    func pause() { synthesizer.pauseSpeaking(at: .word); isPaused = true; isSpeaking = false }
    func resume() { synthesizer.continueSpeaking(); isPaused = false; isSpeaking = true }
    func stop() { synthesizer.stopSpeaking(at: .immediate); isSpeaking = false; isPaused = false; highlightedRange = nil }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.isSpeaking = false; self.isPaused = false; self.highlightedRange = nil }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { self.highlightedRange = Range(characterRange, in: utterance.speechString) }
    }
}

// MARK: - Library Home

struct StoryConsumptionView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedStory: Story? = nil
    @State private var searchText = ""
    @State private var showSearch = false

    private var searchResults: [Story] {
        Story.sampleStories.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    /// Featured stories rotate daily so the hero feels fresh each morning.
    private var featuredStories: [Story] {
        let all = Story.sampleStories
        guard !all.isEmpty else { return [] }
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        return (0..<min(3, all.count)).map { all[(day + $0) % all.count] }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 26) {
                        if showSearch {
                            searchBar
                                .padding(.horizontal, 20)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        if !searchText.isEmpty {
                            searchResultsList
                        } else {
                            heroCarousel

                            dailyPracticeSection
                                .padding(.horizontal, 20)

                            ForEach(StoryCategory.allCases) { category in
                                categorySection(category)
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSearch.toggle()
                            if !showSearch { searchText = "" }
                        }
                    } label: {
                        Image(systemName: showSearch ? "xmark" : "magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.clayAccent)
                    }
                }
            }
            .sheet(item: $selectedStory) { story in
                StoryDetailView(story: story).environmentObject(appState)
            }
        }
    }

    // MARK: Search

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 15, weight: .semibold))
            TextField("Search stories...", text: $searchText)
                .font(.system(.body, design: .rounded).weight(.medium))
                .submitLabel(.search)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(Color.clayCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: Color.clayShadow, radius: 4, x: 0, y: 1)
    }

    @ViewBuilder
    private var searchResultsList: some View {
        if searchResults.isEmpty {
            Text("No stories found")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
        } else {
            LazyVStack(spacing: 0) {
                ForEach(Array(searchResults.enumerated()), id: \.element.id) { index, story in
                    MinimalStoryRow(story: story) { selectedStory = story }
                    if index < searchResults.count - 1 {
                        Divider().padding(.leading, 86).opacity(0.35)
                    }
                }
            }
            .background(Color.clayCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.clayShadow, radius: 8, x: 0, y: 3)
            .padding(.horizontal, 20)
        }
    }

    // MARK: Hero carousel

    private var heroCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(featuredStories) { story in
                    HeroStoryCard(story: story) { selectedStory = story }
                        .frame(width: UIScreen.main.bounds.width - 72)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 6)
        }
    }

    // MARK: Daily practice banner

    private var dailyPracticeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Daily Practice")
                .font(.system(size: 22, weight: .bold))

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                appState.selectedTab = 2
            } label: {
                HStack(spacing: 14) {
                    Text("Spark creativity\nwith a daily prompt")
                        .font(.system(size: 19, weight: .regular))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(4)

                    Spacer()

                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.clayGold.opacity(0.15))
                            .frame(width: 64, height: 64)
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Color.clayGold)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity)
                .background(Color.clayCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.clayShadow, radius: 10, x: 0, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    // MARK: Category sections

    private func categorySection(_ category: StoryCategory) -> some View {
        let stories = Story.sampleStories.filter { $0.category == category }
        return VStack(alignment: .leading, spacing: 14) {
            Text(category.displayName)
                .font(.system(size: 22, weight: .bold))
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach(stories) { story in
                        StoryTile(story: story) { selectedStory = story }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6)
            }
        }
    }
}

// MARK: - Hero Story Card

struct HeroStoryCard: View {
    let story: Story
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text("Today's Story")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(story.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.top, 4)

            artwork
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 14))

            Button(action: onStart) {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("Listen")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.clayAccent))
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(16)
        .background(Color.clayCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.clayShadow, radius: 8, x: 0, y: 3)
    }

    @ViewBuilder
    private var artwork: some View {
        if let name = story.thumbnailName, let img = UIImage(named: name) {
            Image(uiImage: img).resizable().scaledToFill()
        } else {
            ZStack {
                Circle()
                    .fill(Color.clayGold.opacity(0.16))
                    .frame(width: 130, height: 130)
                Image(systemName: story.category.icon)
                    .font(.system(size: 52, weight: .medium))
                    .foregroundColor(story.category.themeColor)
            }
        }
    }
}

// MARK: - Story Tile (carousel item)

struct StoryTile: View {
    let story: Story
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.clayCard)
                    if let name = story.thumbnailName, let img = UIImage(named: name) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        ZStack {
                            Circle()
                                .fill(story.category.themeColor.opacity(0.12))
                                .frame(width: 84, height: 84)
                            Image(systemName: story.category.icon)
                                .font(.system(size: 34, weight: .medium))
                                .foregroundColor(story.category.themeColor)
                        }
                    }
                }
                .frame(width: 150, height: 150)
                .shadow(color: Color.clayShadow, radius: 8, x: 0, y: 3)

                Text(story.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text("Story • \(max(1, Int(story.duration) / 60)) min")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(width: 150, alignment: .leading)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Minimal Story Row

struct MinimalStoryRow: View {
    let story: Story
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Group {
                    if let name = story.thumbnailName, let img = UIImage(named: name) {
                        Image(uiImage: img).resizable().scaledToFill()
                    } else {
                        Rectangle().fill(story.category.themeGradient)
                            .overlay(
                                Image(systemName: story.category.icon)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                    }
                }
                .frame(width: 54, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 3) {
                    Text(story.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Text(story.category.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if story.duration > 0 {
                            Text("·").font(.caption).foregroundColor(.secondary.opacity(0.5))
                            Text("\(max(1, Int(story.duration) / 60)) min")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.35))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
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
    @State private var isBookmarked = false

    private let heroHeight: CGFloat = UIScreen.main.bounds.height * 0.44

    var body: some View {
        ZStack {
            GlassBackground()

            GeometryReader { geo in
                VStack(spacing: 0) {
                    // Hero image (fixed top)
                    ZStack(alignment: .bottom) {
                        heroImage
                            .frame(height: heroHeight)
                            .clipped()

                        // Bottom gradient fade into card
                        LinearGradient(
                            colors: [.clear, Color.clayCard],
                            startPoint: .top, endPoint: .bottom
                        )
                        .frame(height: heroHeight * 0.45)

                        // Centered play/pause button
                        playButton
                            .padding(.bottom, 24)
                    }
                    .frame(height: heroHeight)

                    // Scrollable content card
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 0) {
                                storyInfoHeader
                                    .padding(.horizontal, 24)
                                    .padding(.top, 22)

                                Divider()
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 18)

                                summarySection
                                    .padding(.horizontal, 24)

                                relatedStoriesSection
                                    .padding(.top, 24)

                                retellCTA
                                    .padding(.horizontal, 24)
                                    .padding(.top, 20)
                                    .padding(.bottom, 40)
                            }
                        }
                        .onChange(of: currentParagraphIndex) { newIndex in
                            guard newIndex >= 0 else { return }
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo("para_\(newIndex)", anchor: .center)
                            }
                        }
                    }
                    .background(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 28,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 28
                        )
                        .fill(Color.clayCard)
                        .ignoresSafeArea()
                    )
                }
                .ignoresSafeArea(edges: .top)
            }

            // Overlay nav buttons on hero
            VStack {
                HStack {
                    circleButton(icon: "chevron.left") { dismiss() }
                    Spacer()
                    circleButton(icon: isBookmarked ? "bookmark.fill" : "bookmark") {
                        isBookmarked.toggle()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)
                Spacer()
            }
        }
        .onAppear {
            if let url = story.audioURL, (try? player.loadAudio(from: url)) != nil {
                audioLoaded = true
            }
        }
        .onDisappear { player.stop(); tts.stop() }
    }

    // MARK: - Hero

    @ViewBuilder
    private var heroImage: some View {
        if let name = story.thumbnailName, let img = UIImage(named: name) {
            Image(uiImage: img).resizable().scaledToFill()
        } else {
            Rectangle().fill(story.category.themeGradient)
        }
    }

    private var playButton: some View {
        Button(action: togglePlayback) {
            ZStack {
                Circle()
                    .fill(Color.clayAccent)
                    .frame(width: 64, height: 64)
                    .shadow(color: Color.clayAccent.opacity(0.55), radius: 18, x: 0, y: 6)
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .offset(x: isPlaying ? 0 : 2)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Info Header

    private var storyInfoHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(story.title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    HStack(spacing: 6) {
                        Text(story.category.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if story.duration > 0 {
                            Text("·")
                                .foregroundColor(.secondary)
                            HStack(spacing: 3) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                Text(formatDuration(story.duration))
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
                Spacer()
                // Star rating
                VStack(alignment: .trailing, spacing: 3) {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color.clayGold)
                        Text("4.5")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    Text("(100+)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Audio progress bar (when playing)
            if audioLoaded && player.duration > 0 {
                VStack(spacing: 4) {
                    Slider(
                        value: Binding(get: { player.currentTime }, set: { player.seek(to: $0) }),
                        in: 0...player.duration
                    )
                    .tint(Color.clayAccent)
                    HStack {
                        Text(formatTime(player.currentTime))
                        Spacer()
                        Text(formatTime(player.duration))
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Summary

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(.primary)

            ForEach(Array(paragraphs.enumerated()), id: \.offset) { index, paragraph in
                let isActive = index == currentParagraphIndex
                Text(paragraph)
                    .font(.system(.body, design: .serif))
                    .lineSpacing(8)
                    .foregroundColor(
                        (isPlaying || tts.isPaused)
                            ? (isActive ? .primary : .primary.opacity(0.35))
                            : .secondary
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(isActive ? 12 : 0)
                    .background(
                        Group {
                            if isActive {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.clayAccent.opacity(0.12))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.clayAccent.opacity(0.28), lineWidth: 0.8))
                            }
                        }
                    )
                    .animation(.easeInOut(duration: 0.35), value: isActive)
                    .id("para_\(index)")
            }
        }
    }

    // MARK: - Related Stories

    private var relatedStoriesSection: some View {
        let related = Story.sampleStories
            .filter { $0.category == story.category && $0.id != story.id }
            .prefix(4)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Topic Stories")
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(.primary)
                .padding(.horizontal, 24)

            ForEach(Array(related)) { s in
                RelatedStoryRow(story: s)
                    .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Retell CTA

    private var retellCTA: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            appState.pendingRetellingStory = story
            appState.selectedTab = 1
            dismiss()
        }) {
            HStack(spacing: 10) {
                Image(systemName: "waveform")
                Text("Perform Now")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.vertical, 17)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.clayAccent, Color.clayAccentLight],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .cornerRadius(24)
            .shadow(color: Color.clayAccent.opacity(0.30), radius: 10, x: 0, y: 5)
        }
    }

    // MARK: - Helpers

    private func circleButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.92))
                    .frame(width: 42, height: 42)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 3)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func togglePlayback() {
        if audioLoaded {
            if player.isPlaying { player.pause() } else { player.play() }
        } else {
            if tts.isSpeaking { tts.pause() }
            else if tts.isPaused { tts.resume() }
            else { tts.speak(text: story.content) }
        }
    }

    private var isPlaying: Bool { audioLoaded ? player.isPlaying : tts.isSpeaking }

    private var paragraphs: [String] {
        story.content
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var currentParagraphIndex: Int {
        guard isPlaying || tts.isPaused else { return -1 }
        if audioLoaded, player.duration > 0 {
            let progress = player.currentTime / player.duration
            return min(Int(Double(paragraphs.count) * progress), paragraphs.count - 1)
        } else if let range = tts.highlightedRange {
            let content = story.content
            let offset = content.distance(from: content.startIndex, to: range.lowerBound)
            var cumulative = 0
            for (index, para) in paragraphs.enumerated() {
                cumulative += para.count + 2
                if offset < cumulative { return index }
            }
            return paragraphs.count - 1
        }
        return -1
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60; let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }

    private func formatDuration(_ d: TimeInterval) -> String {
        let m = Int(d) / 60; let s = Int(d) % 60
        return s > 0 ? "\(m)min \(s)sec" : "\(m) min"
    }
}

// MARK: - Related Story Row

struct RelatedStoryRow: View {
    let story: Story

    var body: some View {
        HStack(spacing: 14) {
            Group {
                if let name = story.thumbnailName, let img = UIImage(named: name) {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    Rectangle().fill(story.category.themeGradient)
                }
            }
            .frame(width: 70, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 5) {
                Text(story.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                Text(story.content.prefix(60) + "…")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                if story.duration > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                        Text(relatedDuration(story.duration))
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(Color.claySurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.clayStroke, lineWidth: 0.8))
    }

    private func relatedDuration(_ d: TimeInterval) -> String {
        let m = Int(d) / 60; let s = Int(d) % 60
        return s > 0 ? "\(m)min \(s)sec" : "\(m) min"
    }
}

// MARK: - StoryCategory display name

extension StoryCategory {
    var displayName: String {
        switch self {
        case .technology: return "Technology"
        case .fashion: return "Fashion"
        case .fantasy: return "Fantasy"
        case .socialInteractions: return "Social"
        case .sports: return "Sports"
        }
    }
}

#Preview {
    StoryConsumptionView()
        .environmentObject(AppState())
}
