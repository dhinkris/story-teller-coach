import SwiftUI
import os.log
import UIKit

private let retellingLogger = Logger(subsystem: "com.storytellingpractice.app", category: "StoryRetellingView")

// MARK: - Main View

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
    @ObservedObject private var progressService = ProgressDataService.shared
    @State private var transcriptionResult: String = ""

    private var currentStep: Int {
        if selectedStory == nil { return 0 }
        if showResults { return 2 }
        return 1
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()

                VStack(spacing: 0) {
                    StepPillIndicator(currentStep: currentStep)
                        .frame(maxWidth: .infinity)

                    ZStack {
                        if let story = selectedStory {
                            if !showResults {
                                if isAnalyzing {
                                    VStack {
                                        Spacer()
                                        AnalyzingView().padding(.horizontal, 24)
                                        Spacer()
                                    }
                                    .transition(.opacity)
                                } else {
                                    RecordingStageView(
                                        story: story,
                                        isRecording: $isRecording,
                                        recorder: recorder,
                                        onChangeStory: { reset() },
                                        onRecordComplete: { url, dur in
                                            await handleRecordingComplete(audioURL: url, duration: dur, story: story)
                                        },
                                        onError: { msg in errorMessage = msg }
                                    )
                                    .transition(.opacity)
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
                                .transition(.opacity)
                            }
                        } else {
                            RetellingEmptyState { showStorySelection = true }
                                .transition(.opacity)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .animation(.easeInOut(duration: 0.25), value: selectedStory == nil)
                    .animation(.easeInOut(duration: 0.25), value: showResults)
                    .animation(.easeInOut(duration: 0.25), value: isAnalyzing)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Retell")
            .navigationBarTitleDisplayMode(.inline)
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

    private func reset() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedStory = nil
            showResults = false
            currentRecording = nil
            analysisResults = nil
            transcriptionResult = ""
        }
    }

    private func handleRecordingComplete(audioURL: URL, duration: TimeInterval, story: Story) async {
        await MainActor.run { isAnalyzing = true }
        do {
            let transcript = try await speechRecognizer.transcribeAudio(from: audioURL)
            await MainActor.run { transcriptionResult = transcript }

            let metrics = try await llmService.analyzeStoryRetelling(
                originalStory: story.content,
                userRetelling: transcript,
                duration: duration
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
                progressService.saveRecord(ProgressRecord(
                    storyId: story.id,
                    metrics: metrics,
                    duration: duration,
                    type: .storyRetelling
                ))
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

// MARK: - Step Pill Indicator

struct StepPillIndicator: View {
    let currentStep: Int
    private let steps = ["Choose Story", "Record", "Results"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<steps.count, id: \.self) { i in
                HStack(spacing: 7) {
                    ZStack {
                        Circle()
                            .fill(i <= currentStep ? Color.clayAccent : Color.black.opacity(0.08))
                            .frame(width: 26, height: 26)
                        if i < currentStep {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(i + 1)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(i == currentStep ? .white : .secondary.opacity(0.35))
                        }
                    }
                    if i == currentStep {
                        Text(steps[i])
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .transition(.opacity.combined(with: .scale(scale: 0.85)))
                    }
                }
                .animation(.spring(response: 0.35), value: currentStep)

                if i < steps.count - 1 {
                    Rectangle()
                        .fill(i < currentStep ? Color.clayAccent : Color.black.opacity(0.06))
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 8)
                        .animation(.spring(response: 0.35), value: currentStep)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.clayCard)
        .overlay(Rectangle().fill(Color.clayStroke).frame(height: 0.5), alignment: .bottom)
    }
}

// MARK: - Empty State

struct RetellingEmptyState: View {
    let onChooseStory: () -> Void
    @State private var ring1: CGFloat = 1
    @State private var ring2: CGFloat = 1
    @State private var ring3: CGFloat = 1

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Color.clayAccent.opacity(0.10 - Double(i) * 0.028), lineWidth: 1.5)
                        .frame(width: CGFloat(130 + i * 46), height: CGFloat(130 + i * 46))
                        .scaleEffect(i == 0 ? ring1 : i == 1 ? ring2 : ring3)
                }

                ZStack {
                    Circle()
                        .fill(Color.clayCard)
                        .overlay(Circle().stroke(Color.clayAccent.opacity(0.28), lineWidth: 1))
                        .frame(width: 110, height: 110)
                        .shadow(color: Color.clayAccent.opacity(0.22), radius: 28, x: 0, y: 12)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(LinearGradient(
                            colors: [Color.clayAccent, Color.clayAccentLight],
                            startPoint: .top, endPoint: .bottom
                        ))
                }
            }
            .frame(height: 250)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) { ring1 = 1.08 }
                withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true).delay(0.45)) { ring2 = 1.06 }
                withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true).delay(0.9)) { ring3 = 1.04 }
            }

            VStack(spacing: 12) {
                Text("Your Stage Awaits")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text("Choose a story, retell it in your own voice.\nAI will score your craft.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }

            Button(action: onChooseStory) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                    Text("Pick a Story")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 17)
                .background(LinearGradient(
                    colors: [Color.clayAccent, Color.clayAccentLight],
                    startPoint: .leading, endPoint: .trailing
                ))
                .cornerRadius(28)
                .shadow(color: Color.clayAccent.opacity(0.35), radius: 16, x: 0, y: 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Recording Stage

struct RecordingStageView: View {
    let story: Story
    @Binding var isRecording: Bool
    @ObservedObject var recorder: AudioRecorderService
    let onChangeStory: () -> Void
    let onRecordComplete: (URL, TimeInterval) async -> Void
    var onError: (String) -> Void = { _ in }

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Ambient thumbnail background
            if let name = story.thumbnailName, let img = UIImage(named: name) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .opacity(0.07)
                    .blur(radius: 24)
                    .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                // Story banner
                StoryBanner(story: story, onChangeStory: onChangeStory)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                Spacer()

                // Live waveform
                WaveformView(isActive: isRecording)
                    .frame(height: 110)
                    .padding(.horizontal, 28)

                Spacer()

                // Timer
                Text(formatTime(recorder.recordingDuration))
                    .font(.system(size: 68, weight: .thin, design: .monospaced))
                    .foregroundColor(isRecording ? Color.clayDanger : .primary.opacity(0.45))
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: isRecording)

                Text(isRecording ? "Recording your performance…" : "Tap the mic to begin")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)

                Spacer()

                // Record button with pulse rings
                ZStack {
                    if isRecording {
                        ForEach(0..<2) { i in
                            Circle()
                                .stroke(Color.clayDanger.opacity(0.12 - Double(i) * 0.04), lineWidth: 1.5)
                                .frame(width: CGFloat(116 + i * 28), height: CGFloat(116 + i * 28))
                                .scaleEffect(pulseScale)
                                .animation(
                                    .easeInOut(duration: 1.3).repeatForever(autoreverses: true).delay(Double(i) * 0.3),
                                    value: pulseScale
                                )
                        }
                    }
                    RecordButton(isRecording: isRecording) {
                        if isRecording { stopRecording() } else { startRecording() }
                    }
                }
                .frame(height: 160)
                .padding(.bottom, 36)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onChange(of: isRecording) { recording in
            pulseScale = recording ? 1.14 : 1.0
        }
    }

    private func startRecording() {
        do {
            try recorder.startRecording()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { isRecording = true }
        } catch {
            onError(error.localizedDescription)
        }
    }

    private func stopRecording() {
        guard let audioURL = recorder.stopRecording() else { return }
        let duration = recorder.recordingDuration
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation { isRecording = false }
        Task { await onRecordComplete(audioURL, duration) }
    }

    private func formatTime(_ t: TimeInterval) -> String {
        String(format: "%02d:%02d", Int(t) / 60, Int(t) % 60)
    }
}

// MARK: - Story Banner

struct StoryBanner: View {
    let story: Story
    let onChangeStory: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if let name = story.thumbnailName, let img = UIImage(named: name) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 46, height: 46)
                    .clipShape(RoundedRectangle(cornerRadius: 11))
            } else {
                RoundedRectangle(cornerRadius: 11)
                    .fill(story.category.themeGradient)
                    .frame(width: 46, height: 46)
                    .overlay(
                        Image(systemName: story.category.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("RETELLING")
                    .font(.system(size: 9, weight: .bold))
                    .kerning(1.1)
                    .foregroundColor(story.category.themeColor)

                Text(story.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Button(action: onChangeStory) {
                Text("Change")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.clayAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.clayAccent.opacity(0.10)))
            }
        }
        .padding(12)
        .background(Color.clayCard)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.clayStroke, lineWidth: 0.8))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.clayShadow, radius: 6, x: 0, y: 2)
    }
}

// MARK: - Live Waveform

struct WaveformView: View {
    let isActive: Bool
    private let barCount = 38

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05, paused: !isActive)) { tl in
            HStack(alignment: .center, spacing: 2.5) {
                ForEach(0..<barCount, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(
                            colors: [Color.clayAccentLight, Color.clayAccent],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .frame(width: 3.5, height: barHeight(index: i, date: tl.date))
                        .animation(.easeOut(duration: 0.35), value: isActive)
                }
            }
            .opacity(isActive ? 1.0 : 0.22)
            .animation(.easeInOut(duration: 0.5), value: isActive)
        }
    }

    private func barHeight(index: Int, date: Date) -> CGFloat {
        guard isActive else { return 4 }
        let t = date.timeIntervalSinceReferenceDate
        let i = Double(index)
        let n = Double(barCount)
        let envelope = sin(i / n * .pi) // taller in the middle
        let wave1 = sin(t * 4.5 + i * 0.52) * 0.38
        let wave2 = sin(t * 7.3 + i * 0.79) * 0.27
        let wave3 = sin(t * 2.1 + i * 0.31) * 0.20
        let normalized = (wave1 + wave2 + wave3 + envelope * 0.15 + 1.0) / 2.0
        return max(4, CGFloat(normalized) * 94)
    }
}

// MARK: - Record Button

struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(
                        isRecording ? Color.clayDanger.opacity(0.3) : Color.clayAccent.opacity(0.22),
                        lineWidth: 1.5
                    )
                    .frame(width: 108, height: 108)

                Circle()
                    .fill(Color.clayCard)
                    .overlay(Circle().stroke(
                        isRecording ? Color.clayDanger.opacity(0.55) : Color.clayAccent.opacity(0.38),
                        lineWidth: 1
                    ))
                    .frame(width: 88, height: 88)
                    .shadow(
                        color: isRecording ? Color.clayDanger.opacity(0.32) : Color.clayAccent.opacity(0.28),
                        radius: 22, x: 0, y: 10
                    )

                if isRecording {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color.clayDanger)
                        .frame(width: 30, height: 30)
                } else {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(LinearGradient(
                            colors: [Color.clayAccent, Color.clayAccentLight],
                            startPoint: .top, endPoint: .bottom
                        ))
                }
            }
        }
        .scaleEffect(isRecording ? 1.07 : 1.0)
        .animation(.spring(response: 0.38, dampingFraction: 0.62), value: isRecording)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Analyzing

struct AnalyzingView: View {
    @State private var outerRotation: Double = 0
    @State private var innerRotation: Double = 0

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                ForEach(0..<6) { i in
                    Circle()
                        .fill(Color.clayAccent.opacity(0.55 - Double(i) * 0.06))
                        .frame(width: 7, height: 7)
                        .offset(y: -54)
                        .rotationEffect(.degrees(outerRotation + Double(i) * 60))
                }
                ForEach(0..<4) { i in
                    Circle()
                        .fill(Color.clayAccentLight.opacity(0.4))
                        .frame(width: 5, height: 5)
                        .offset(y: -34)
                        .rotationEffect(.degrees(innerRotation + Double(i) * 90))
                }

                ZStack {
                    Circle()
                        .fill(Color.claySurface)
                        .overlay(Circle().stroke(Color.clayAccent.opacity(0.28), lineWidth: 1))
                        .frame(width: 62, height: 62)
                    Image(systemName: "waveform.and.mic")
                        .font(.system(size: 22))
                        .foregroundColor(Color.clayAccent)
                }
            }
            .frame(width: 120, height: 120)

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
        .onAppear {
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) { outerRotation = 360 }
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) { innerRotation = -360 }
        }
    }
}

// MARK: - Story Selection

struct StorySelectionView: View {
    @Binding var selectedStory: Story?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Story.sampleStories) { story in
                            Button(action: { selectedStory = story; dismiss() }) {
                                HStack(spacing: 14) {
                                    if let name = story.thumbnailName, let img = UIImage(named: name) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 56, height: 56)
                                            .clipShape(RoundedRectangle(cornerRadius: 13))
                                    } else {
                                        RoundedRectangle(cornerRadius: 13)
                                            .fill(story.category.themeGradient)
                                            .frame(width: 56, height: 56)
                                            .overlay(
                                                Image(systemName: story.category.icon)
                                                    .font(.system(size: 20, weight: .semibold))
                                                    .foregroundColor(.white)
                                            )
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(story.title)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                            .multilineTextAlignment(.leading)

                                        HStack(spacing: 6) {
                                            Image(systemName: story.category.icon)
                                                .font(.system(size: 10, weight: .semibold))
                                            Text(story.category.rawValue)
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                        }
                                        .foregroundColor(story.category.themeColor)
                                    }

                                    Spacer()

                                    if story.duration > 0 {
                                        Text("\(max(1, Int(story.duration) / 60)) min")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.secondary)
                                    }

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.secondary.opacity(0.45))
                                }
                                .padding(14)
                                .background(Color.clayCard)
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.clayStroke, lineWidth: 0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .shadow(color: Color.clayShadow, radius: 8, x: 0, y: 3)
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
}

// MARK: - Analysis Results

struct AnalysisResultsView: View {
    let metrics: StoryMetrics
    let recording: Recording?
    let transcription: String?
    let onRetry: () -> Void
    @State private var animateScore = false

    init(metrics: StoryMetrics, recording: Recording? = nil, transcription: String? = nil, onRetry: @escaping () -> Void) {
        self.metrics = metrics
        self.recording = recording
        self.transcription = transcription
        self.onRetry = onRetry
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                scoreHero
                arcGrid
                if let recording { RecordingPlaybackCard(audioURL: recording.audioURL) }
                if let bd = metrics.breakdown { DiagnosticsCard(breakdown: bd, isPractice: false) }
                if let t = transcription, !t.isEmpty { transcriptionCard(t) }
                if !metrics.suggestions.isEmpty { coachNotes }
                actionButtons
            }
            .padding(20)
            .padding(.bottom, 8)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.15)) { animateScore = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        }
    }

    // MARK: Score hero

    private var scoreHero: some View {
        VStack(spacing: 18) {
            ZStack {
                // Track ring
                Circle()
                    .stroke(Color.black.opacity(0.06), style: StrokeStyle(lineWidth: 14, lineCap: .round))

                // Animated score arc
                Circle()
                    .trim(from: 0, to: animateScore ? metrics.overallScore : 0)
                    .stroke(
                        AngularGradient(
                            colors: [
                                performanceColor(for: metrics.overallScore),
                                performanceColor(for: metrics.overallScore).opacity(0.45)
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 1.3).delay(0.25), value: animateScore)

                VStack(spacing: 4) {
                    Text("\(metrics.overallPercentage)%")
                        .font(.system(size: 54, weight: .bold, design: .rounded))
                        .foregroundColor(performanceColor(for: metrics.overallScore))

                    Text(performanceLabel(for: metrics.overallScore))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .kerning(0.8)
                }
            }
            .frame(width: 168, height: 168)

            Text("Overall Performance")
                .font(.headline)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .clayCard(cornerRadius: 28, padding: 28)
    }

    // MARK: Arc gauge grid

    private var arcGrid: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Craft Breakdown")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ArcGauge(title: "Story Fidelity",   score: metrics.similarityScore,  icon: "target",                                     delay: 0.3)
                ArcGauge(title: "Delivery",          score: metrics.fluencyScore,      icon: "waveform",                                   delay: 0.45)
                ArcGauge(title: "Narrative Flow",    score: metrics.coherenceScore,    icon: "arrow.triangle.turn.up.right.diamond",       delay: 0.6)
                ArcGauge(title: "Expression",        score: metrics.vocabularyScore,   icon: "textformat.abc",                             delay: 0.75)
            }
        }
        .clayCard(cornerRadius: 28, padding: 22)
    }

    // MARK: Transcription

    private func transcriptionCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "quote.opening")
                    .foregroundColor(Color.clayAccent)
                Text("Your Words")
                    .font(.headline)
                    .fontWeight(.bold)
            }

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color.claySurface)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.clayStroke, lineWidth: 0.6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .lineLimit(8)
        }
        .clayCard(cornerRadius: 28, padding: 22)
    }

    // MARK: Coach notes

    private var coachNotes: some View {
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
                            .fill(Color.clayAccent.opacity(0.18))
                            .overlay(Circle().stroke(Color.clayAccent.opacity(0.28), lineWidth: 0.6))
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 4)
            }
        }
        .clayCard(cornerRadius: 28, padding: 22)
    }

    // MARK: Actions

    private var actionButtons: some View {
        Button(action: onRetry) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.clockwise")
                Text("Record Again")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.vertical, 17)
            .frame(maxWidth: .infinity)
            .background(LinearGradient(
                colors: [Color.clayAccent, Color.clayAccentLight],
                startPoint: .leading, endPoint: .trailing
            ))
            .cornerRadius(24)
            .shadow(color: Color.clayAccent.opacity(0.28), radius: 10, x: 0, y: 5)
        }
    }
}

// MARK: - Recording Playback

struct RecordingPlaybackCard: View {
    let audioURL: URL
    @StateObject private var player = AudioPlayerService()
    @State private var loadFailed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "headphones")
                    .foregroundColor(Color.clayAccent)
                Text("Listen Back")
                    .font(.headline)
                    .fontWeight(.bold)
            }

            if loadFailed {
                Text("This recording is no longer available.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                HStack(spacing: 14) {
                    Button(action: togglePlayback) {
                        ZStack {
                            Circle()
                                .fill(Color.clayAccent)
                                .frame(width: 46, height: 46)
                                .shadow(color: Color.clayAccent.opacity(0.35), radius: 8, x: 0, y: 4)
                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: player.isPlaying ? 0 : 1.5)
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())

                    VStack(spacing: 4) {
                        Slider(
                            value: Binding(get: { player.currentTime }, set: { player.seek(to: $0) }),
                            in: 0...max(player.duration, 0.01)
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
                }
            }
        }
        .clayCard(cornerRadius: 28, padding: 22)
        .onAppear {
            do { try player.loadAudio(from: audioURL) } catch { loadFailed = true }
        }
        .onDisappear { player.stop() }
    }

    private func togglePlayback() {
        if player.isPlaying { player.pause() } else { player.play() }
    }

    private func formatTime(_ t: TimeInterval) -> String {
        String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
    }
}

// MARK: - Arc Gauge

struct ArcGauge: View {
    let title: String
    let score: Double
    let icon: String
    var delay: Double = 0.3
    @State private var animated = false

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Track
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(Color.black.opacity(0.06), style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(135))

                // Fill arc
                Circle()
                    .trim(from: 0, to: animated ? 0.75 * score : 0)
                    .stroke(
                        LinearGradient(
                            colors: [performanceColor(for: score), performanceColor(for: score).opacity(0.55)],
                            startPoint: .leading, endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 9, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))
                    .animation(.easeOut(duration: 1.0).delay(delay), value: animated)

                VStack(spacing: 3) {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(performanceColor(for: score))
                    Text("\(Int(score * 100))%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
            }
            .frame(width: 88, height: 88)

            Text(title)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.claySurface)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.clayStroke, lineWidth: 0.7))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .onAppear { animated = true }
    }
}

// MARK: - Diagnostics

enum DiagStatus { case good, ok, bad }

struct DiagRow: View {
    let icon: String
    let label: String
    let value: String
    let hint: String
    let status: DiagStatus

    private var statusColor: Color {
        switch status {
        case .good: return Color.claySuccess
        case .ok:   return Color.clayGold
        case .bad:  return Color.clayDanger
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Text(hint)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(statusColor)
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
        }
        .padding(.vertical, 4)
    }
}

struct DiagnosticsCard: View {
    let breakdown: MetricBreakdown
    let isPractice: Bool
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { withAnimation(.spring(response: 0.35)) { expanded.toggle() } }) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis")
                        .foregroundColor(Color.clayAccent)
                    Text("Performance Diagnostics")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())

            if expanded {
                VStack(spacing: 0) {
                    Divider().padding(.vertical, 14)
                    deliveryRows
                    Divider().padding(.vertical, 14)
                    if isPractice { arcRows } else { fidelityRows }
                    Divider().padding(.vertical, 14)
                    flowRows
                    Divider().padding(.vertical, 14)
                    expressionRows
                }
                .transition(.opacity)
            }
        }
        .clayCard(cornerRadius: 28, padding: 22)
    }

    @ViewBuilder private var deliveryRows: some View {
        sectionLabel("Delivery")
        if let wpm = breakdown.wordsPerMinute {
            DiagRow(icon: "speedometer", label: "Speaking Pace",
                    value: String(format: "%.0f WPM", wpm), hint: "ideal: 130–160 WPM",
                    status: wpm >= 130 && wpm <= 160 ? .good : wpm >= 100 && wpm <= 200 ? .ok : .bad)
        }
        if let rate = breakdown.disfluencyRate {
            DiagRow(icon: "exclamationmark.bubble", label: "Filler Words",
                    value: String(format: "%.1f%%", rate * 100), hint: "ideal: under 2%",
                    status: rate < 0.02 ? .good : rate < 0.05 ? .ok : .bad)
        }
        if let sv = breakdown.sentenceVariety {
            DiagRow(icon: "text.alignleft", label: "Sentence Variety",
                    value: String(format: "%.0f%%", sv * 100), hint: "higher is better",
                    status: sv >= 0.65 ? .good : sv >= 0.35 ? .ok : .bad)
        }
    }

    @ViewBuilder private var fidelityRows: some View {
        sectionLabel("Story Fidelity")
        if let cc = breakdown.conceptCoverage {
            DiagRow(icon: "doc.text.magnifyingglass", label: "Concept Coverage",
                    value: String(format: "%.0f%%", cc * 100), hint: "key story ideas",
                    status: cc >= 0.70 ? .good : cc >= 0.45 ? .ok : .bad)
        }
        if let ec = breakdown.entityCoverage {
            DiagRow(icon: "person.2", label: "Character Coverage",
                    value: String(format: "%.0f%%", ec * 100), hint: "named entities",
                    status: ec >= 0.65 ? .good : ec >= 0.40 ? .ok : .bad)
        }
    }

    @ViewBuilder private var arcRows: some View {
        sectionLabel("Narrative Arc")
        if let setup = breakdown.hasSetup {
            DiagRow(icon: "1.circle", label: "Setup",
                    value: setup ? "Present" : "Missing", hint: "opening context",
                    status: setup ? .good : .bad)
        }
        if let conflict = breakdown.hasConflict {
            DiagRow(icon: "2.circle", label: "Conflict",
                    value: conflict ? "Present" : "Missing", hint: "central tension",
                    status: conflict ? .good : .bad)
        }
        if let resolution = breakdown.hasResolution {
            DiagRow(icon: "3.circle", label: "Resolution",
                    value: resolution ? "Present" : "Missing", hint: "story conclusion",
                    status: resolution ? .good : .bad)
        }
    }

    @ViewBuilder private var flowRows: some View {
        sectionLabel("Narrative Flow")
        if let ts = breakdown.temporalScore {
            DiagRow(icon: "clock.arrow.circlepath", label: "Time Markers",
                    value: String(format: "%.0f%%", ts * 100), hint: "then / before / after…",
                    status: ts >= 0.70 ? .good : ts >= 0.40 ? .ok : .bad)
        }
        if let cs = breakdown.causalScore {
            DiagRow(icon: "arrow.triangle.branch", label: "Causal Links",
                    value: String(format: "%.0f%%", cs * 100), hint: "because / so / therefore…",
                    status: cs >= 0.70 ? .good : cs >= 0.40 ? .ok : .bad)
        }
        if let lc = breakdown.lexicalChain {
            DiagRow(icon: "link", label: "Sentence Cohesion",
                    value: String(format: "%.0f%%", lc * 100), hint: "connected ideas",
                    status: lc >= 0.65 ? .good : lc >= 0.40 ? .ok : .bad)
        }
    }

    @ViewBuilder private var expressionRows: some View {
        sectionLabel(isPractice ? "Word Choice" : "Expression")
        if let m = breakdown.msttr {
            DiagRow(icon: "textformat", label: "Vocabulary Richness",
                    value: String(format: "%.2f MSTTR", m), hint: "ideal: > 0.72",
                    status: m >= 0.72 ? .good : m >= 0.55 ? .ok : .bad)
        }
        if let s = breakdown.sophisticationScore {
            DiagRow(icon: "graduationcap", label: "Word Sophistication",
                    value: String(format: "%.0f%%", s * 100), hint: "non-common words",
                    status: s >= 0.20 ? .good : s >= 0.10 ? .ok : .bad)
        }
        if let d = breakdown.descriptiveDensity {
            DiagRow(icon: "paintbrush", label: "Descriptive Detail",
                    value: String(format: "%.0f%%", d * 100), hint: "ideal: 15–30%",
                    status: d >= 0.10 && d <= 0.40 ? .good : d >= 0.06 ? .ok : .bad)
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .kerning(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 6)
    }
}

#Preview {
    StoryRetellingView()
        .environmentObject(AppState())
}
