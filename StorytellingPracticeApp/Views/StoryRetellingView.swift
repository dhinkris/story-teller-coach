import SwiftUI

struct StoryRetellingView: View {
    @State private var selectedStory: Story? = nil
    @State private var showStorySelection = false
    @State private var isRecording = false
    @State private var showResults = false
    @State private var currentRecording: Recording? = nil
    @State private var analysisResults: StoryMetrics? = nil
    
    @StateObject private var recorder = AudioRecorderService()
    @StateObject private var speechRecognizer = SpeechRecognitionService()
    @StateObject private var llmService = LLMService()
    @StateObject private var progressService = ProgressDataService()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.clayBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    if let story = selectedStory {
                        // Story Preview
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Selected Story")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                Spacer()
                            }
                            
                            Text(story.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(story.content)
                                .font(.body)
                                .lineLimit(5)
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }
                        .clayCard(cornerRadius: 28, padding: 24)
                        .padding(.horizontal, 24)
                        
                        // Recording Section
                        if !showResults {
                            RecordingView(
                                isRecording: $isRecording,
                                recorder: recorder,
                                onRecordComplete: { audioURL, duration in
                                    await handleRecordingComplete(audioURL: audioURL, duration: duration, story: story)
                                }
                            )
                        } else if let results = analysisResults {
                            AnalysisResultsView(
                                metrics: results,
                                recording: currentRecording,
                                onRetry: {
                                    withAnimation {
                                        showResults = false
                                        currentRecording = nil
                                        analysisResults = nil
                                    }
                                }
                            )
                        }
                    } else {
                        // No Story Selected
                        VStack(spacing: 28) {
                            ZStack {
                                Circle()
                                    .fill(Color.clayCard)
                                    .frame(width: 140, height: 140)
                                    .shadow(color: Color.clayShadow, radius: 20, x: 10, y: 10)
                                    .shadow(color: Color.clayShadowLight, radius: 20, x: -10, y: -10)
                                
                                Image(systemName: "book.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(Color.clayAccent)
                            }
                            
                            Text("Select a Story to Retell")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Choose a story and practice retelling it in your own words")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button(action: {
                                showStorySelection = true
                            }) {
                                HStack {
                                    Image(systemName: "book.fill")
                                    Text("Choose Story")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color.clayAccent, Color.clayAccentLight],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(25)
                                .shadow(color: Color.clayShadow, radius: 15, x: 8, y: 8)
                                .shadow(color: Color.clayShadowLight, radius: 15, x: -8, y: -8)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .navigationTitle("Story Retelling")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showStorySelection) {
                StorySelectionView(selectedStory: $selectedStory)
            }
            .onAppear {
                Task {
                    _ = await recorder.requestPermission()
                    _ = await speechRecognizer.requestAuthorization()
                }
            }
        }
    }
    
    private func handleRecordingComplete(audioURL: URL, duration: TimeInterval, story: Story) async {
        do {
            let transcript = try await speechRecognizer.transcribeAudio(from: audioURL)
            let metrics = try await llmService.analyzeStoryRetelling(
                originalStory: story.content,
                userRetelling: transcript
            )
            
            let recording = Recording(
                storyId: story.id,
                transcript: transcript,
                audioURL: audioURL,
                duration: duration,
                metrics: metrics
            )
            
            await MainActor.run {
                currentRecording = recording
                analysisResults = metrics
                
                // Save progress
                let progressRecord = ProgressRecord(
                    storyId: story.id,
                    metrics: metrics,
                    duration: duration,
                    type: .storyRetelling
                )
                progressService.saveRecord(progressRecord)
                
                withAnimation {
                    showResults = true
                }
            }
        } catch {
            print("Error processing recording: \(error)")
        }
    }
}

struct StorySelectionView: View {
    @Binding var selectedStory: Story?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.clayBackground
                    .ignoresSafeArea()
                
                List {
                    ForEach(Story.sampleStories) { story in
                        Button(action: {
                            selectedStory = story
                            dismiss()
                        }) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(story.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    HStack(spacing: 8) {
                                        Image(systemName: story.category.icon)
                                            .font(.system(size: 12, weight: .semibold))
                                        Text(story.category.rawValue)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(Color.clayAccent)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
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
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .navigationTitle("Select Story")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(Color.clayAccent)
                    }
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d min", minutes, seconds)
    }
}

struct RecordingView: View {
    @Binding var isRecording: Bool
    @ObservedObject var recorder: AudioRecorderService
    let onRecordComplete: (URL, TimeInterval) async -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            // Recording Timer
            VStack(spacing: 12) {
                Text(formatTime(recorder.recordingDuration))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(isRecording ? Color.red.opacity(0.8) : Color.clayAccent)
                
                if isRecording {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                            .opacity(recorder.isRecording ? 1.0 : 0.3)
                            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: recorder.isRecording)
                        
                        Text("Recording")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.red.opacity(0.8))
                    }
                }
            }
            
            // Recording Button
            Button(action: {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.clayCard)
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.clayShadow, radius: 25, x: 12, y: 12)
                        .shadow(color: Color.clayShadowLight, radius: 25, x: -12, y: -12)
                    
                    Circle()
                        .fill(isRecording ? Color.red.opacity(0.2) : Color.clayAccent.opacity(0.2))
                        .frame(width: 90, height: 90)
                    
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(isRecording ? .red : Color.clayAccent)
                }
            }
            .scaleEffect(isRecording ? 1.05 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isRecording)
            
            Text(isRecording ? "Tap to stop recording" : "Tap to start recording")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .clayCard(cornerRadius: 32, padding: 36)
        .padding(.horizontal, 24)
    }
    
    private func startRecording() {
        do {
            try recorder.startRecording()
            withAnimation {
                isRecording = true
            }
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    private func stopRecording() {
        guard let audioURL = recorder.stopRecording() else { return }
        let duration = recorder.recordingDuration
        withAnimation {
            isRecording = false
        }
        
        Task {
            await onRecordComplete(audioURL, duration)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct AnalysisResultsView: View {
    let metrics: StoryMetrics
    let recording: Recording?
    let onRetry: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Overall Score
                VStack(spacing: 16) {
                    Text("Overall Score")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    ZStack {
                        Circle()
                            .fill(Color.clayCard)
                            .frame(width: 160, height: 160)
                            .shadow(color: Color.clayShadow, radius: 20, x: 10, y: 10)
                            .shadow(color: Color.clayShadowLight, radius: 20, x: -10, y: -10)
                        
                        Circle()
                            .stroke(scoreColor(metrics.overallScore).opacity(0.3), lineWidth: 8)
                            .frame(width: 150, height: 150)
                        
                        Text("\(metrics.overallPercentage)%")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundColor(scoreColor(metrics.overallScore))
                    }
                }
                .padding(32)
                
                // Individual Metrics
                VStack(spacing: 20) {
                    Text("Detailed Metrics")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    MetricRow(title: "Similarity", score: metrics.similarityScore, percentage: metrics.similarityPercentage, icon: "target")
                    MetricRow(title: "Fluency", score: metrics.fluencyScore, percentage: metrics.fluencyPercentage, icon: "waveform")
                    MetricRow(title: "Coherence", score: metrics.coherenceScore, percentage: metrics.coherencePercentage, icon: "link")
                    MetricRow(title: "Vocabulary", score: metrics.vocabularyScore, percentage: metrics.vocabularyPercentage, icon: "textformat")
                }
                .clayCard(cornerRadius: 28, padding: 24)
                
                // Suggestions
                if !metrics.suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(Color.yellow.opacity(0.8))
                            Text("Suggestions for Improvement")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        
                        ForEach(Array(metrics.suggestions.enumerated()), id: \.offset) { index, suggestion in
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.clayAccent.opacity(0.2))
                                        .frame(width: 28, height: 28)
                                    
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color.clayAccent)
                                }
                                
                                Text(suggestion)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .clayCard(cornerRadius: 28, padding: 24)
                }
                
                // Retry Button
                Button(action: onRetry) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Another Story")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 18)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [Color.clayAccent, Color.clayAccentLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: Color.clayShadow, radius: 15, x: 8, y: 8)
                    .shadow(color: Color.clayShadowLight, radius: 15, x: -8, y: -8)
                }
            }
            .padding(24)
        }
    }
    
    private func scoreColor(_ score: Double) -> Color {
        if score >= 0.8 {
            return .green
        } else if score >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

struct MetricRow: View {
    let title: String
    let score: Double
    let percentage: Int
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.clayAccent)
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                Spacer()
                Text("\(percentage)%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor(score))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 10)
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(scoreColor(score))
                        .frame(width: geometry.size.width * score, height: 10)
                }
            }
            .frame(height: 10)
        }
    }
    
    private func scoreColor(_ score: Double) -> Color {
        if score >= 0.8 {
            return .green
        } else if score >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

#Preview {
    StoryRetellingView()
}
