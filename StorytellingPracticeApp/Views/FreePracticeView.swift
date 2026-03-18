import SwiftUI
import os.log

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
    @StateObject private var progressService = ProgressDataService()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.clayBackground.ignoresSafeArea()

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

                                RecordingView(
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
                            .frame(width: 120, height: 120)
                            .shadow(color: Color.clayShadow,      radius: 20, x: 10,  y: 10)
                            .shadow(color: Color.clayShadowLight, radius: 20, x: -10, y: -10)

                        Image(systemName: "bolt.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color.clayAccent)
                    }

                    Text("Open Practice")
                        .font(.system(size: 26, weight: .bold, design: .rounded))

                    Text("Get a random prompt and tell the best story you can. No script, no rules — just you and the moment.")
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
                            Image(systemName: "bolt.fill")
                            Text("Generate Challenge")
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
                RoundedRectangle(cornerRadius: 18)
                    .fill(isSelected ? color : Color.clayCard)
                    .shadow(color: isSelected ? color.opacity(0.28) : Color.clayShadow, radius: isSelected ? 8 : 6, x: 0, y: isSelected ? 4 : 3)
                    .shadow(color: isSelected ? .clear : Color.clayShadowLight, radius: 6, x: -3, y: -3)
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
            .padding(20)
            .background(Color.clayCard)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: Color.clayShadow,      radius: 12, x: 5,  y: 5)
        .shadow(color: Color.clayShadowLight, radius: 12, x: -5, y: -5)
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

                // Craft metrics
                VStack(spacing: 18) {
                    HStack {
                        Text("Craft Breakdown")
                            .font(.headline)
                            .fontWeight(.bold)
                        Spacer()
                    }

                    MetricRow(title: "Narrative Arc",  score: metrics.similarityScore, percentage: metrics.similarityPercentage, icon: "arrow.triangle.branch")
                    MetricRow(title: "Delivery",        score: metrics.fluencyScore,    percentage: metrics.fluencyPercentage,    icon: "waveform")
                    MetricRow(title: "Story Flow",      score: metrics.coherenceScore,  percentage: metrics.coherencePercentage,  icon: "arrow.triangle.turn.up.right.diamond")
                    MetricRow(title: "Word Choice",     score: metrics.vocabularyScore, percentage: metrics.vocabularyPercentage, icon: "textformat.abc")
                }
                .clayCard(cornerRadius: 28, padding: 22)

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
