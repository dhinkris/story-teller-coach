import SwiftUI

struct StoryConsumptionView: View {
    @State private var selectedCategory: StoryCategory? = nil
    @State private var selectedStory: Story? = nil
    @State private var showStoryDetail = false
    
    private var filteredStories: [Story] {
        if let category = selectedCategory {
            return Story.sampleStories.filter { $0.category == category }
        }
        return Story.sampleStories
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Claymorphism background
                Color.clayBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            CategoryFilterButton(
                                title: "All",
                                icon: "square.grid.2x2",
                                isSelected: selectedCategory == nil
                            ) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    selectedCategory = nil
                                }
                            }
                            
                            ForEach(StoryCategory.allCases) { category in
                                CategoryFilterButton(
                                    title: category.rawValue,
                                    icon: category.icon,
                                    isSelected: selectedCategory == category
                                ) {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        selectedCategory = category
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.vertical, 20)
                    
                    // Stories List
                    if filteredStories.isEmpty {
                        VStack(spacing: 24) {
                            ZStack {
                                Circle()
                                    .fill(Color.clayCard)
                                    .frame(width: 120, height: 120)
                                    .shadow(color: Color.clayShadow, radius: 15, x: 8, y: 8)
                                    .shadow(color: Color.clayShadowLight, radius: 15, x: -8, y: -8)
                                
                                Image(systemName: "book.closed")
                                    .font(.system(size: 50))
                                    .foregroundColor(Color.clayAccent)
                            }
                            
                            Text("No stories found")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 20) {
                                ForEach(filteredStories) { story in
                                    StoryCard(story: story) {
                                        selectedStory = story
                                        showStoryDetail = true
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 20)
                        }
                    }
                }
            }
            .navigationTitle("Stories")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedStory) { story in
                StoryDetailView(story: story)
            }
        }
    }
}

struct CategoryFilterButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .clayButton(isSelected: isSelected, cornerRadius: 25)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
    }
}

struct StoryCard: View {
    let story: Story
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: story.category.icon)
                            .font(.system(size: 12, weight: .semibold))
                        Text(story.category.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(Color.clayAccent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.clayAccent.opacity(0.15))
                    )
                    
                    Spacer()
                    
                    if story.duration > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                            Text(formatDuration(story.duration))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                Text(story.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(story.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
            }
            .clayCard(cornerRadius: 28, padding: 24)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct StoryDetailView: View {
    let story: Story
    @Environment(\.dismiss) var dismiss
    @StateObject private var audioPlayer = AudioPlayerService()
    @State private var isReadingMode = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.clayBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Category and Duration
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: story.category.icon)
                                    .font(.system(size: 12, weight: .semibold))
                                Text(story.category.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(Color.clayAccent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.clayAccent.opacity(0.15))
                            )
                            
                            Spacer()
                            
                            if story.duration > 0 {
                                HStack(spacing: 6) {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 10))
                                    Text(formatDuration(story.duration))
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.secondary)
                            }
                        }
                        
                        // Title
                        Text(story.title)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        // Mode Toggle
                        Picker("Mode", selection: $isReadingMode) {
                            Text("Read").tag(true)
                            Text("Listen").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .tint(Color.clayAccent)
                        
                        // Content
                        if isReadingMode {
                            Text(story.content)
                                .font(.body)
                                .lineSpacing(8)
                                .padding(.top, 8)
                                .foregroundColor(.primary)
                        } else {
                            AudioPlayerView(audioPlayer: audioPlayer, story: story)
                                .padding(.top, 8)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        audioPlayer.stop()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color.clayAccent)
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct AudioPlayerView: View {
    @ObservedObject var audioPlayer: AudioPlayerService
    let story: Story
    
    var body: some View {
        VStack(spacing: 24) {
            if audioPlayer.duration > 0 {
                // Playback Controls
                Button(action: {
                    if audioPlayer.isPlaying {
                        audioPlayer.pause()
                    } else {
                        audioPlayer.play()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.clayCard)
                            .frame(width: 90, height: 90)
                            .shadow(color: Color.clayShadow, radius: 20, x: 10, y: 10)
                            .shadow(color: Color.clayShadowLight, radius: 20, x: -10, y: -10)
                        
                        Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color.clayAccent)
                    }
                }
                
                // Progress
                VStack(spacing: 12) {
                    Slider(
                        value: Binding(
                            get: { audioPlayer.currentTime },
                            set: { audioPlayer.seek(to: $0) }
                        ),
                        in: 0...audioPlayer.duration
                    )
                    .tint(Color.clayAccent)
                    
                    HStack {
                        Text(formatTime(audioPlayer.currentTime))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatTime(audioPlayer.duration))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "speaker.slash.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("Audio not available for this story")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .clayCard(cornerRadius: 28, padding: 28)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    StoryConsumptionView()
}
