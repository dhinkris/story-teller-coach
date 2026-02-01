import SwiftUI

struct FreePracticeView: View {
    @State private var currentPrompt: StoryPrompt? = nil
    @State private var isRecording = false
    @State private var showResults = false
    @State private var currentRecording: Recording? = nil
    @State private var analysisResults: StoryMetrics? = nil
    @State private var selectedCategory: StoryCategory? = nil
    @State private var isLoadingPrompt = false
    
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
                    if let prompt = currentPrompt {
                        // Prompt Display
                        VStack(alignment: .leading, spacing: 20) {
                            if let image = prompt.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 200)
                                    .cornerRadius(24)
                                    .shadow(color: Color.clayShadow, radius: 15, x: 8, y: 8)
                                    .shadow(color: Color.clayShadowLight, radius: 15, x: -8, y: -8)
                            }
                            
                            HStack {
                                Text("Your Prompt")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                Spacer()
                            }
                            
                            Text(prompt.text)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .lineSpacing(6)
                                .clayCard(cornerRadius: 24, padding: 24)
                        }
                        .padding(.horizontal, 24)
                        
                        // Recording Section
                        if !showResults {
                            RecordingView(
                                isRecording: $isRecording,
                                recorder: recorder,
                                onRecordComplete: { audioURL, duration in
                                    await handleRecordingComplete(audioURL: audioURL, duration: duration)
                                }
                            )
                        } else if let results = analysisResults {
                            PracticeResultsView(
                                metrics: results,
                                recording: currentRecording,
                                onNewPrompt: {
                                    generateNewPrompt()
                                },
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
                        // No Prompt
                        VStack(spacing: 32) {
                            ZStack {
                                Circle()
                                    .fill(Color.clayCard)
                                    .frame(width: 160, height: 160)
                                    .shadow(color: Color.clayShadow, radius: 20, x: 10, y: 10)
                                    .shadow(color: Color.clayShadowLight, radius: 20, x: -10, y: -10)
                                
                                Image(systemName: "sparkles")
                                    .font(.system(size: 70))
                                    .foregroundColor(Color.clayAccent)
                            }
                            
                            VStack(spacing: 12) {
                                Text("Ready to Practice?")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                
                                Text("Generate a random storytelling prompt and practice your skills")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            
                            // Category Selection
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Choose a category (optional)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        CategoryButton(
                                            title: "Any",
                                            isSelected: selectedCategory == nil
                                        ) {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                                selectedCategory = nil
                                            }
                                        }
                                        
                                        ForEach(StoryCategory.allCases) { category in
                                            CategoryButton(
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
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            Button(action: {
                                generateNewPrompt()
                            }) {
                                HStack(spacing: 12) {
                                    if isLoadingPrompt {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "sparkles")
                                        Text("Generate Prompt")
                                    }
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 18)
                                .background(
                                    Group {
                                        if isLoadingPrompt {
                                            LinearGradient(
                                                colors: [.gray, .gray.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        } else {
                                            LinearGradient(
                                                colors: [Color.clayAccent, Color.clayAccentLight],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        }
                                    }
                                )
                                .cornerRadius(25)
                                .shadow(color: isLoadingPrompt ? .clear : Color.clayShadow, radius: 15, x: 8, y: 8)
                                .shadow(color: isLoadingPrompt ? .clear : Color.clayShadowLight, radius: 15, x: -8, y: -8)
                            }
                            .disabled(isLoadingPrompt)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .navigationTitle("Free Practice")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    _ = await recorder.requestPermission()
                    _ = await speechRecognizer.requestAuthorization()
                }
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
                print("Error generating prompt: \(error)")
                await MainActor.run {
                    isLoadingPrompt = false
                }
            }
        }
    }
    
    private func handleRecordingComplete(audioURL: URL, duration: TimeInterval) async {
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
                
                // Save progress
                let progressRecord = ProgressRecord(
                    promptId: currentPrompt?.id,
                    metrics: metrics,
                    duration: duration,
                    type: .freePractice
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

struct CategoryButton: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
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

struct PracticeResultsView: View {
    let metrics: StoryMetrics
    let recording: Recording?
    let onNewPrompt: () -> Void
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
                    
                    PracticeMetricRow(title: "Story Structure", score: metrics.similarityScore, percentage: metrics.similarityPercentage, icon: "square.stack")
                    PracticeMetricRow(title: "Fluency", score: metrics.fluencyScore, percentage: metrics.fluencyPercentage, icon: "waveform")
                    PracticeMetricRow(title: "Coherence", score: metrics.coherenceScore, percentage: metrics.coherencePercentage, icon: "link")
                    PracticeMetricRow(title: "Vocabulary", score: metrics.vocabularyScore, percentage: metrics.vocabularyPercentage, icon: "textformat")
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
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: onRetry) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Try Again")
                        }
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .clayButton(isSelected: false, cornerRadius: 25)
                    }
                    
                    Button(action: onNewPrompt) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("New Prompt")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
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

struct PracticeMetricRow: View {
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
    FreePracticeView()
}
