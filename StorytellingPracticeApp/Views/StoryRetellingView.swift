import SwiftUI
import os.log

private let retellingLogger = Logger(subsystem: "com.storytellingpractice.app", category: "StoryRetellingView")

struct StoryRetellingView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedStory: Story? = nil
    @State private var showStorySelection = false
    @State private var isRecording = false
    @State private var showResults = false
    @State private var currentRecording: Recording? = nil
    @State private var analysisResults: StoryMetrics? = nil
    @State private var isAnalyzing = false
    @State private var errorMessage: String? = nil

    @StateObject private var recorder = AudioRecorderService()
    @StateObject private var speechRecognizer = SpeechRecognitionService()
    @StateObject private var llmService = LLMService()
    @StateObject private var progressService = ProgressDataService()
    @State private var transcriptionResult: String = ""

    private var currentStep: Int {
        if selectedStory == nil { return 0 }
        if showResults { return 2 }
        return 1
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.clayBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // 3-step flow indicator
                    StepIndicatorView(
                        currentStep: currentStep,
                        steps: ["Choose", "Record", "Review"]
                    )
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)

                    if let story = selectedStory {
                        if !showResults {
                            if isAnalyzing {
                                Spacer()
                                AnalyzingView()
                                    .padding(.horizontal, 20)
                                Spacer()
                            } else {
                                ScrollView {
                                    VStack(spacing: 18) {
                                        SelectedStoryCard(story: story) {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                                selectedStory = nil
                                                showResults = false
                                                currentRecording = nil
                                                analysisResults = nil
                                                transcriptionResult = ""
                                            }
                                        }
                                        .padding(.horizontal, 20)

                                        RecordingView(
                                            isRecording: $isRecording,
                                            recorder: recorder,
                                            onRecordComplete: { audioURL, duration in
                                                await handleRecordingComplete(
                                                    audioURL: audioURL,
                                                    duration: duration,
                                                    story: story
                                                )
                                            },
                                            onError: { msg in errorMessage = msg }
                                        )
                                        .padding(.horizontal, 20)
                                    }
                                    .padding(.bottom, 24)
                                }
                            }
                        } else if let results = analysisResults {
                            AnalysisResultsView(
                                metrics: results,
                                recording: currentRecording,
                                transcription: transcriptionResult.isEmpty ? nil : transcriptionResult,
                                onRetry: {
                                    withAnimation {
                                        showResults = false
                                        currentRecording = nil
                                        analysisResults = nil
                                        transcriptionResult = ""
                                    }
                                }
                            )
                        }
                    } else {
                        RetellingEmptyState { showStorySelection = true }
                    }
                }
            }
            .navigationTitle("Retell")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showStorySelection) {
                StorySelectionView(selectedStory: $selectedStory)
            }
            .onAppear {
                Task {
                    _ = await recorder.requestPermission()
                    _ = await speechRecognizer.requestAuthorization()
                }
                if let story = appState.pendingRetellingStory {
                    selectedStory = story
                    appState.pendingRetellingStory = nil
                }
            }
            .onChange(of: appState.pendingRetellingStory) { story in
                guard let story else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    selectedStory = story
                    showResults = false
                    currentRecording = nil
                    analysisResults = nil
                    transcriptionResult = ""
                }
                appState.pendingRetellingStory = nil
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func handleRecordingComplete(audioURL: URL, duration: TimeInterval, story: Story) async {
        await MainActor.run { isAnalyzing = true }
        do {
            let transcript = try await speechRecognizer.transcribeAudio(from: audioURL)
            await MainActor.run { transcriptionResult = transcript }

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
                isAnalyzing = false

                let progressRecord = ProgressRecord(
                    storyId: story.id,
                    metrics: metrics,
                    duration: duration,
                    type: .storyRetelling
                )
                progressService.saveRecord(progressRecord)

                withAnimation { showResults = true }
            }
        } catch {
            retellingLogger.error("Error processing recording: \(error.localizedDescription)")
            await MainActor.run {
                isAnalyzing = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Step Indicator

struct StepIndicatorView: View {
    let currentStep: Int
    let steps: [String]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<steps.count, id: \.self) { index in
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(index <= currentStep ? Color.clayAccent : Color.claySurface)
                            .frame(width: 26, height: 26)

                        if index < currentStep {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(index <= currentStep ? .white : .secondary)
                        }
                    }

                    Text(steps[index])
                        .font(.caption)
                        .fontWeight(index == currentStep ? .semibold : .regular)
                        .foregroundColor(index <= currentStep ? Color.clayAccent : .secondary)
                }

                if index < steps.count - 1 {
                    Rectangle()
                        .fill(index < currentStep ? Color.clayAccent : Color.claySurface)
                        .frame(height: 2)
                        .padding(.horizontal, 8)
                }
            }
        }
    }
}

// MARK: - Empty State

struct RetellingEmptyState: View {
    let onChooseStory: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(Color.clayCard)
                    .frame(width: 130, height: 130)
                    .shadow(color: Color.clayShadow,      radius: 20, x: 10,  y: 10)
                    .shadow(color: Color.clayShadowLight, radius: 20, x: -10, y: -10)

                Image(systemName: "mic.fill")
                    .font(.system(size: 52))
                    .foregroundColor(Color.clayAccent)
            }

            VStack(spacing: 10) {
                Text("Ready to Perform?")
                    .font(.system(size: 26, weight: .bold, design: .rounded))

                Text("Choose a story from the Library, then retell it in your own voice to sharpen your storytelling craft.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 36)
            }

            Button(action: onChooseStory) {
                HStack(spacing: 10) {
                    Image(systemName: "books.vertical.fill")
                    Text("Choose a Story")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 36)
                .padding(.vertical, 16)
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Selected Story Card

struct SelectedStoryCard: View {
    let story: Story
    let onChangeStory: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Now Retelling")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(story.category.themeColor)
                        .textCase(.uppercase)
                        .kerning(0.5)

                    Text(story.title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }

                Spacer()

                Button(action: onChangeStory) {
                    Text("Change")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.clayAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.clayAccent.opacity(0.10))
                        )
                }
            }

            Divider()
                .padding(.vertical, 12)

            Text(story.content)
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .lineSpacing(3)
        }
        .clayCard(cornerRadius: 22, padding: 18)
    }
}

// MARK: - Analyzing State

struct AnalyzingView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Color.clayAccent.opacity(0.28 - Double(i) * 0.07), lineWidth: 2)
                        .frame(width: CGFloat(58 + i * 22), height: CGFloat(58 + i * 22))
                        .scaleEffect(isAnimating ? 1.10 : 0.92)
                        .animation(
                            .easeInOut(duration: 1.2)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.22),
                            value: isAnimating
                        )
                }
                Image(systemName: "waveform")
                    .font(.system(size: 28))
                    .foregroundColor(Color.clayAccent)
            }
            .frame(height: 110)

            VStack(spacing: 6) {
                Text("Analyzing Performance")
                    .font(.headline)
                    .fontWeight(.bold)
                Text("Evaluating your storytelling craft…")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .clayCard(cornerRadius: 28, padding: 36)
        .onAppear { isAnimating = true }
    }
}

// MARK: - Story Selection Sheet

struct StorySelectionView: View {
    @Binding var selectedStory: Story?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.clayBackground.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(Story.sampleStories) { story in
                            Button(action: {
                                selectedStory = story
                                dismiss()
                            }) {
                                HStack(spacing: 14) {
                                    // Category dot
                                    Circle()
                                        .fill(story.category.themeColor)
                                        .frame(width: 10, height: 10)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(story.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.leading)

                                        HStack(spacing: 6) {
                                            Image(systemName: story.category.icon)
                                                .font(.system(size: 11, weight: .semibold))
                                            Text(story.category.rawValue)
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                        }
                                        .foregroundColor(story.category.themeColor)
                                    }

                                    Spacer()

                                    if story.duration > 0 {
                                        Text(readTime(story.duration))
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                    }

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary.opacity(0.5))
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(Color.clayCard)
                                        .shadow(color: Color.clayShadow,      radius: 8, x: 4,  y: 4)
                                        .shadow(color: Color.clayShadowLight, radius: 8, x: -4, y: -4)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Choose a Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(Color.clayAccent)
                }
            }
        }
    }

    private func readTime(_ duration: TimeInterval) -> String {
        let m = max(1, Int(duration) / 60)
        return "\(m) min"
    }
}

// MARK: - Recording View

struct RecordingView: View {
    @Binding var isRecording: Bool
    @ObservedObject var recorder: AudioRecorderService
    let onRecordComplete: (URL, TimeInterval) async -> Void
    var onError: (String) -> Void = { _ in }

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 28) {
            // Timer
            VStack(spacing: 8) {
                Text(formatTime(recorder.recordingDuration))
                    .font(.system(size: 54, weight: .bold, design: .monospaced))
                    .foregroundColor(isRecording ? Color.clayDanger : Color.clayAccent)

                if isRecording {
                    HStack(spacing: 7) {
                        Circle()
                            .fill(Color.clayDanger)
                            .frame(width: 8, height: 8)
                            .opacity(recorder.isRecording ? 1.0 : 0.3)
                            .animation(
                                .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                                value: recorder.isRecording
                            )
                        Text("Recording")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.clayDanger)
                    }
                } else {
                    Text("Your performance")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }

            // Mic button with pulse
            ZStack {
                if isRecording {
                    ForEach(0..<2) { i in
                        Circle()
                            .stroke(Color.clayDanger.opacity(0.15 - Double(i) * 0.05), lineWidth: 2)
                            .frame(width: CGFloat(110 + i * 24), height: CGFloat(110 + i * 24))
                            .scaleEffect(pulseScale)
                            .animation(
                                .easeInOut(duration: 1.0).repeatForever(autoreverses: true).delay(Double(i) * 0.25),
                                value: pulseScale
                            )
                    }
                }

                Button(action: {
                    if isRecording { stopRecording() } else { startRecording() }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.clayCard)
                            .frame(width: 96, height: 96)
                            .shadow(color: Color.clayShadow,      radius: 24, x: 12,  y: 12)
                            .shadow(color: Color.clayShadowLight, radius: 24, x: -12, y: -12)

                        Circle()
                            .fill(isRecording ? Color.clayDanger.opacity(0.15) : Color.clayAccent.opacity(0.12))
                            .frame(width: 84, height: 84)

                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(isRecording ? Color.clayDanger : Color.clayAccent)
                    }
                }
                .scaleEffect(isRecording ? 1.05 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isRecording)
            }
            .frame(height: 160)

            Text(isRecording ? "Tap to finish your performance" : "Tap to begin your performance")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .clayCard(cornerRadius: 32, padding: 32)
        .onChange(of: isRecording) { recording in
            pulseScale = recording ? 1.12 : 1.0
        }
    }

    private func startRecording() {
        do {
            try recorder.startRecording()
            withAnimation { isRecording = true }
        } catch {
            retellingLogger.error("Failed to start recording: \(error.localizedDescription)")
            onError(error.localizedDescription)
        }
    }

    private func stopRecording() {
        guard let audioURL = recorder.stopRecording() else { return }
        let duration = recorder.recordingDuration
        withAnimation { isRecording = false }
        Task { await onRecordComplete(audioURL, duration) }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let m = Int(time) / 60
        let s = Int(time) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Analysis Results

struct AnalysisResultsView: View {
    let metrics: StoryMetrics
    let recording: Recording?
    let transcription: String?
    let onRetry: () -> Void

    init(metrics: StoryMetrics, recording: Recording?, transcription: String? = nil, onRetry: @escaping () -> Void) {
        self.metrics = metrics
        self.recording = recording
        self.transcription = transcription
        self.onRetry = onRetry
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Performance banner
                VStack(spacing: 4) {
                    Text(performanceLabel(for: metrics.overallScore))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(performanceColor(for: metrics.overallScore))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(performanceColor(for: metrics.overallScore).opacity(0.12))
                        )

                    Text("Performance Rating")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)

                // Score circle
                ZStack {
                    Circle()
                        .fill(Color.clayCard)
                        .frame(width: 148, height: 148)
                        .shadow(color: Color.clayShadow,      radius: 20, x: 10,  y: 10)
                        .shadow(color: Color.clayShadowLight, radius: 20, x: -10, y: -10)

                    Circle()
                        .stroke(performanceColor(for: metrics.overallScore).opacity(0.25), lineWidth: 7)
                        .frame(width: 136, height: 136)

                    Text("\(metrics.overallPercentage)%")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(performanceColor(for: metrics.overallScore))
                }

                // Craft metrics (storytelling terminology)
                VStack(spacing: 18) {
                    HStack {
                        Text("Craft Breakdown")
                            .font(.headline)
                            .fontWeight(.bold)
                        Spacer()
                    }

                    MetricRow(title: "Story Fidelity",   score: metrics.similarityScore,  percentage: metrics.similarityPercentage,  icon: "target")
                    MetricRow(title: "Delivery",          score: metrics.fluencyScore,      percentage: metrics.fluencyPercentage,      icon: "waveform")
                    MetricRow(title: "Narrative Flow",    score: metrics.coherenceScore,    percentage: metrics.coherencePercentage,    icon: "arrow.triangle.turn.up.right.diamond")
                    MetricRow(title: "Expression",        score: metrics.vocabularyScore,   percentage: metrics.vocabularyPercentage,   icon: "textformat.abc")
                }
                .clayCard(cornerRadius: 28, padding: 22)

                // Transcription
                if let transcription = transcription, !transcription.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "quote.opening")
                                .foregroundColor(Color.clayAccent)
                            Text("Your Words")
                                .font(.headline)
                                .fontWeight(.bold)
                        }

                        Text(transcription)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.clayAccent.opacity(0.05))
                            )
                            .lineLimit(6)
                    }
                    .clayCard(cornerRadius: 28, padding: 22)
                }

                // Suggestions
                if !metrics.suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(Color.clayGold)
                            Text("Coach's Notes")
                                .font(.headline)
                                .fontWeight(.bold)
                        }

                        ForEach(Array(metrics.suggestions.enumerated()), id: \.offset) { index, suggestion in
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.clayAccent.opacity(0.12))
                                        .frame(width: 26, height: 26)
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color.clayAccent)
                                }
                                Text(suggestion)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .lineSpacing(2)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .clayCard(cornerRadius: 28, padding: 22)
                }

                // Retry button
                Button(action: onRetry) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Another Story")
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
            }
            .padding(20)
        }
    }
}

// MARK: - Metric Row

struct MetricRow: View {
    let title: String
    let score: Double
    let percentage: Int
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 7) {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.clayAccent)
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                Spacer()
                Text("\(percentage)%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(performanceColor(for: score))
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.claySurface)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [performanceColor(for: score), performanceColor(for: score).opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * score, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    StoryRetellingView()
}
