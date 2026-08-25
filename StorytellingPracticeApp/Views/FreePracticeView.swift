import SwiftUI
import os.log
import UIKit

private let practiceLogger = Logger(subsystem: "com.storytellingpractice.app", category: "FreePracticeView")

struct FreePracticeView: View {
    @State private var currentPrompt: StoryPrompt? = nil
    @State private var isRecording = false
    @State private var showResults = false
    @State private var currentRecording: Recording? = nil
    @State private var analysisResults: StoryMetrics? = nil
    @State private var selectedCategory: StoryCategory? = nil
    @State private var isLoadingPrompt = false
    @State private var isAnalyzing = false
    @State private var errorMessage: String? = nil

    @StateObject private var recorder = AudioRecorderService()
    @StateObject private var speechRecognizer = SpeechRecognitionService()
    @StateObject private var llmService = LLMService()
    @ObservedObject private var progressService = ProgressDataService.shared

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()

                if let prompt = currentPrompt {
                    // Prompt active
                    if isAnalyzing {
                        VStack {
                            Spacer()
                            AnalyzingView()
                                .padding(.horizontal, 20)
                            Spacer()
                        }
                    } else if !showResults {
                        ScrollView {
                            VStack(spacing: 18) {
                                ChallengeCard(prompt: prompt) {
                                    generateNewPrompt()
                                }
                                .padding(.horizontal, 20)

                                PracticeRecordingCard(
                                    isRecording: $isRecording,
                                    recorder: recorder,
                                    onRecordComplete: { audioURL, duration in
                                        await handleRecordingComplete(audioURL: audioURL, duration: duration)
                                    },
                                    onError: { msg in errorMessage = msg }
                                )
                                .padding(.horizontal, 20)
                            }
                            .padding(.vertical, 16)
                        }
                    } else if let results = analysisResults {
                        PracticeResultsView(
                            metrics: results,
                            recording: currentRecording,
                            onNewPrompt: { generateNewPrompt() },
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
                    // No prompt — setup screen
                    PracticeSetupView(
                        selectedCategory: $selectedCategory,
                        isLoadingPrompt: isLoadingPrompt,
                        onGenerate: { generateNewPrompt() }
                    )
                }
            }
            .navigationTitle("Practice")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    _ = await recorder.requestPermission()
                    _ = await speechRecognizer.requestAuthorization()
                }
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

    private func generateNewPrompt() {
        isLoadingPrompt = true
        Task {
            do {
                let prompt = try await llmService.generatePrompt(category: selectedCategory)
                await MainActor.run {
                    currentPrompt = prompt
                    isLoadingPrompt = false
                    showResults = false
                    currentRecording = nil
                    analysisResults = nil
                }
            } catch {
                practiceLogger.error("Error generating prompt: \(error.localizedDescription)")
                await MainActor.run {
                    isLoadingPrompt = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func handleRecordingComplete(audioURL: URL, duration: TimeInterval) async {
        await MainActor.run { isAnalyzing = true }
        do {
            let transcript = try await speechRecognizer.transcribeAudio(from: audioURL)
            let metrics = try await llmService.analyzePracticeRecording(
                transcript: transcript,
                duration: duration
            )

            let recording = Recording(
                promptId: currentPrompt?.id,
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
                    promptId: currentPrompt?.id,
                    metrics: metrics,
                    duration: duration,
                    type: .freePractice
                )
                progressService.saveRecord(progressRecord)

                withAnimation { showResults = true }
            }
        } catch {
            practiceLogger.error("Error processing recording: \(error.localizedDescription)")
            await MainActor.run {
                isAnalyzing = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Practice Setup Screen

struct PracticeSetupView: View {
    @Binding var selectedCategory: StoryCategory?
    let isLoadingPrompt: Bool
    let onGenerate: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 36) {
                // Hero
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.clayCard)
                            .overlay(Circle().stroke(Color.clayStroke, lineWidth: 0.8))
                            .frame(width: 120, height: 120)
                            .shadow(color: Color.clayShadow, radius: 14, x: 0, y: 6)

                        Image(systemName: "flame.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color.clayAccent)
                    }

                    Text("Creative Challenge")
                        .font(.system(size: 26, weight: .bold, design: .rounded))

                    Text("Get inspired by a prompt and craft your story in real time. Unleash your creativity.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 32)
                }

                // Category grid
                VStack(alignment: .leading, spacing: 14) {
                    Text("Category")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .kerning(0.5)
                        .padding(.horizontal, 2)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        PracticeCategoryTile(
                            title: "Any",
                            icon: "square.grid.2x2",
                            color: Color.clayAccent,
                            isSelected: selectedCategory == nil
                        ) {
                            withAnimation(.spring(response: 0.3)) { selectedCategory = nil }
                        }

                        ForEach(StoryCategory.allCases) { category in
                            PracticeCategoryTile(
                                title: category.rawValue,
                                icon: category.icon,
                                color: category.themeColor,
                                isSelected: selectedCategory == category
                            ) {
                                withAnimation(.spring(response: 0.3)) { selectedCategory = category }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)

                // Generate button
                Button(action: onGenerate) {
                    HStack(spacing: 12) {
                        if isLoadingPrompt {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "sparkles")
                            Text("Get Inspired")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 18)
                    .frame(maxWidth: .infinity)
                    .background(
                        Group {
                            if isLoadingPrompt {
                                LinearGradient(colors: [.gray, .gray.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                            } else {
                                LinearGradient(colors: [Color.clayAccent, Color.clayAccentLight], startPoint: .leading, endPoint: .trailing)
                            }
                        }
                    )
                    .cornerRadius(24)
                    .shadow(color: isLoadingPrompt ? .clear : Color.clayAccent.opacity(0.28), radius: 10, x: 0, y: 5)
                }
                .disabled(isLoadingPrompt)
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 28)
        }
    }
}

// MARK: - Practice Category Tile

struct PracticeCategoryTile: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isSelected ? .white : color)

                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 18).fill(color)
                            .shadow(color: color.opacity(0.45), radius: 10, x: 0, y: 4)
                    } else {
                        RoundedRectangle(cornerRadius: 12).fill(Color.clayCard)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.clayStroke, lineWidth: 0.8))
                            .shadow(color: Color.clayShadow, radius: 4, x: 0, y: 2)
                    }
                }
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .animation(.spring(response: 0.28), value: isSelected)
    }
}

// MARK: - Challenge Card (Prompt Display)

struct ChallengeCard: View {
    let prompt: StoryPrompt
    let onNewPrompt: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 7) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text("Your Challenge")
                        .font(.system(size: 11, weight: .bold))
                        .kerning(0.6)
                }
                .foregroundColor(.white.opacity(0.88))
                .textCase(.uppercase)

                Spacer()

                Button(action: onNewPrompt) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                        Text("New")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white.opacity(0.88))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.18))
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)
            .background(
                LinearGradient(
                    colors: [Color.clayAccent, Color.clayAccentLight],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Prompt text
            VStack(alignment: .leading, spacing: 10) {
                if let image = prompt.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Text(prompt.text)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                if let category = prompt.category {
                    HStack(spacing: 5) {
                        Image(systemName: category.icon)
                            .font(.system(size: 11))
                        Text(category.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(category.themeColor)
                    .padding(.top, 4)
                }
            }
            .padding(18)
            .background(Color.clayCard)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.clayStroke, lineWidth: 0.8))
        .shadow(color: Color.clayShadow, radius: 8, x: 0, y: 3)
    }
}

// MARK: - Practice Recording Card

struct PracticeRecordingCard: View {
    @Binding var isRecording: Bool
    @ObservedObject var recorder: AudioRecorderService
    let onRecordComplete: (URL, TimeInterval) async -> Void
    var onError: (String) -> Void = { _ in }

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 24) {
            // Waveform
            WaveformView(isActive: isRecording)
                .frame(height: 80)

            // Timer
            Text(formatTime(recorder.recordingDuration))
                .font(.system(size: 52, weight: .thin, design: .monospaced))
                .foregroundColor(isRecording ? Color.clayDanger : .primary.opacity(0.45))
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.2), value: isRecording)

            Text(isRecording ? "Recording your performance…" : "Tap to start your performance")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Record button + pulse rings
            ZStack {
                if isRecording {
                    ForEach(0..<2) { i in
                        Circle()
                            .stroke(Color.clayDanger.opacity(0.12 - Double(i) * 0.04), lineWidth: 1.5)
                            .frame(width: CGFloat(108 + i * 26), height: CGFloat(108 + i * 26))
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
            .frame(height: 140)
        }
        .clayCard(cornerRadius: 28, padding: 28)
        .onChange(of: isRecording) { recording in
            pulseScale = recording ? 1.14 : 1.0
        }
    }

    private func startRecording() {
        do {
            try recorder.startRecording()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { isRecording = true }
        } catch { onError(error.localizedDescription) }
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

// MARK: - Practice Results

struct PracticeResultsView: View {
    let metrics: StoryMetrics
    let recording: Recording?
    let onNewPrompt: () -> Void
    let onRetry: () -> Void

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
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        }
                    }
                }

                // Score circle
                ZStack {
                    Circle()
                        .fill(Color.clayCard)
                        .overlay(Circle().stroke(Color.clayStroke, lineWidth: 0.8))
                        .frame(width: 148, height: 148)
                        .shadow(color: Color.clayShadow, radius: 14, x: 0, y: 6)

                    Circle()
                        .stroke(performanceColor(for: metrics.overallScore).opacity(0.60), lineWidth: 7)
                        .frame(width: 136, height: 136)

                    Text("\(metrics.overallPercentage)%")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(performanceColor(for: metrics.overallScore))
                }

                if let recording {
                    RecordingPlaybackCard(audioURL: recording.audioURL)
                }

                // Craft metrics
                VStack(spacing: 16) {
                    HStack {
                        Text("Craft Breakdown")
                            .font(.headline)
                            .fontWeight(.bold)
                        Spacer()
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ArcGauge(title: "Narrative Arc", score: metrics.similarityScore, icon: "arrow.triangle.branch",                       delay: 0.3)
                        ArcGauge(title: "Delivery",       score: metrics.fluencyScore,    icon: "waveform",                                    delay: 0.45)
                        ArcGauge(title: "Story Flow",     score: metrics.coherenceScore,  icon: "arrow.triangle.turn.up.right.diamond",        delay: 0.6)
                        ArcGauge(title: "Word Choice",    score: metrics.vocabularyScore, icon: "textformat.abc",                              delay: 0.75)
                    }
                }
                .clayCard(cornerRadius: 28, padding: 22)

                if let bd = metrics.breakdown { DiagnosticsCard(breakdown: bd, isPractice: true) }

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

                // Action buttons
                HStack(spacing: 12) {
                    Button(action: onRetry) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Try Again")
                        }
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .clayButton(isSelected: false, cornerRadius: 24)
                    }

                    Button(action: onNewPrompt) {
                        HStack {
                            Image(systemName: "bolt.fill")
                            Text("New Challenge")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [Color.clayAccent, Color.clayAccentLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(24)
                        .shadow(color: Color.clayAccent.opacity(0.28), radius: 8, x: 0, y: 4)
                    }
                }
            }
            .padding(20)
        }
    }
}

#Preview {
    FreePracticeView()
}
