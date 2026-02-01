import Foundation

class LLMService: ObservableObject {
    private let apiKey: String? // For cloud-based LLM
    private let useLocalLLM: Bool
    
    init(apiKey: String? = nil, useLocalLLM: Bool = true) {
        self.apiKey = apiKey
        self.useLocalLLM = useLocalLLM
    }
    
    // Analyze story retelling similarity and provide metrics
    func analyzeStoryRetelling(originalStory: String, userRetelling: String) async throws -> StoryMetrics {
        // In a real app, this would call an LLM API or local model
        // For now, we'll create a mock implementation with basic analysis
        
        let similarity = calculateSimilarity(original: originalStory, retelling: userRetelling)
        let fluency = calculateFluency(text: userRetelling)
        let coherence = calculateCoherence(text: userRetelling)
        let vocabulary = calculateVocabularyScore(text: userRetelling)
        
        let overallScore = (similarity + fluency + coherence + vocabulary) / 4.0
        
        let suggestions = generateSuggestions(
            similarity: similarity,
            fluency: fluency,
            coherence: coherence,
            vocabulary: vocabulary,
            original: originalStory,
            retelling: userRetelling
        )
        
        return StoryMetrics(
            similarityScore: similarity,
            fluencyScore: fluency,
            coherenceScore: coherence,
            vocabularyScore: vocabulary,
            overallScore: overallScore,
            suggestions: suggestions
        )
    }
    
    // Generate a random storytelling prompt
    func generatePrompt(category: StoryCategory? = nil) async throws -> StoryPrompt {
        // In a real app, this would call a local LLM
        // For now, we'll use predefined prompts with some randomization
        
        let prompts = [
            "Tell a story about a person who discovers something unexpected about themselves.",
            "Describe a moment when technology changed someone's life in an unexpected way.",
            "Narrate a story about two people from different worlds who find common ground.",
            "Share a tale about someone who overcomes their greatest fear.",
            "Tell a story about a discovery that changes everything.",
            "Describe a day that starts ordinary but becomes extraordinary.",
            "Narrate a story about friendship that transcends boundaries.",
            "Share a tale about someone who finds their true calling.",
            "Tell a story about a choice that defines a person's character.",
            "Describe a moment of transformation and growth."
        ]
        
        let categoryPrompts: [StoryCategory: [String]] = [
            .technology: [
                "Tell a story about someone who creates technology that solves a real-world problem.",
                "Describe a day in a world where AI and humans work together seamlessly.",
                "Narrate a story about a breakthrough invention that changes society."
            ],
            .fashion: [
                "Tell a story about a piece of clothing that holds special meaning.",
                "Describe how fashion can express identity and culture.",
                "Narrate a story about someone who finds confidence through style."
            ],
            .fantasy: [
                "Tell a story about discovering magic in an ordinary place.",
                "Describe an encounter with a mythical creature.",
                "Narrate a tale about a quest that reveals inner strength."
            ],
            .socialInteractions: [
                "Tell a story about a conversation that changes everything.",
                "Describe how a small act of kindness creates a ripple effect.",
                "Narrate a story about building bridges between different people."
            ],
            .sports: [
                "Tell a story about overcoming obstacles through determination.",
                "Describe a moment of teamwork that leads to victory.",
                "Narrate a story about finding strength you didn't know you had."
            ]
        ]
        
        let selectedPrompts: [String]
        if let category = category, let categorySpecific = categoryPrompts[category] {
            selectedPrompts = categorySpecific
        } else {
            selectedPrompts = prompts
        }
        
        let randomPrompt = selectedPrompts.randomElement() ?? prompts[0]
        
        // In a real implementation, you would generate an image using a local image generation model
        // For now, we'll return nil for imageData
        return StoryPrompt(
            text: randomPrompt,
            imageData: nil,
            category: category
        )
    }
    
    // Analyze free practice recording
    func analyzePracticeRecording(transcript: String, duration: TimeInterval) async throws -> StoryMetrics {
        let fluency = calculateFluency(text: transcript)
        let coherence = calculateCoherence(text: transcript)
        let vocabulary = calculateVocabularyScore(text: transcript)
        
        // For practice prompts, we don't have an original to compare against
        // So similarity is based on how well-structured the story is
        let similarity = (fluency + coherence + vocabulary) / 3.0
        
        let overallScore = (similarity + fluency + coherence + vocabulary) / 4.0
        
        let suggestions = generatePracticeSuggestions(
            fluency: fluency,
            coherence: coherence,
            vocabulary: vocabulary,
            transcript: transcript,
            duration: duration
        )
        
        return StoryMetrics(
            similarityScore: similarity,
            fluencyScore: fluency,
            coherenceScore: coherence,
            vocabularyScore: vocabulary,
            overallScore: overallScore,
            suggestions: suggestions
        )
    }
    
    // MARK: - Helper Methods
    
    private func calculateSimilarity(original: String, retelling: String) -> Double {
        // Simple word overlap calculation
        let originalWords = Set(original.lowercased().components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty })
        let retellingWords = Set(retelling.lowercased().components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty })
        
        let intersection = originalWords.intersection(retellingWords)
        let union = originalWords.union(retellingWords)
        
        guard !union.isEmpty else { return 0.0 }
        return Double(intersection.count) / Double(union.count)
    }
    
    private func calculateFluency(text: String) -> Double {
        // Based on sentence length variation and flow
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard !sentences.isEmpty else { return 0.0 }
        
        let avgLength = sentences.map { $0.count }.reduce(0, +) / sentences.count
        let variance = sentences.map { pow(Double($0.count - avgLength), 2) }.reduce(0, +) / Double(sentences.count)
        
        // Lower variance = more fluent (but some variation is good)
        let fluency = 1.0 - min(variance / 100.0, 1.0)
        return max(0.0, min(1.0, fluency))
    }
    
    private func calculateCoherence(text: String) -> Double {
        // Simple coherence based on transition words and sentence connections
        let transitionWords = ["however", "therefore", "meanwhile", "furthermore", "consequently", "additionally", "moreover", "nevertheless", "thus", "hence"]
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let transitionCount = words.filter { transitionWords.contains($0) }.count
        
        let coherence = min(Double(transitionCount) / 10.0, 1.0)
        return max(0.3, coherence) // Minimum baseline
    }
    
    private func calculateVocabularyScore(text: String) -> Double {
        // Based on word diversity
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let uniqueWords = Set(words)
        
        guard !words.isEmpty else { return 0.0 }
        return Double(uniqueWords.count) / Double(words.count)
    }
    
    private func generateSuggestions(similarity: Double, fluency: Double, coherence: Double, vocabulary: Double, original: String, retelling: String) -> [String] {
        var suggestions: [String] = []
        
        if similarity < 0.6 {
            suggestions.append("Try to include more key details and themes from the original story.")
        }
        
        if fluency < 0.6 {
            suggestions.append("Work on varying your sentence length to create better flow.")
        }
        
        if coherence < 0.6 {
            suggestions.append("Use transition words to better connect your ideas and create a smoother narrative.")
        }
        
        if vocabulary < 0.5 {
            suggestions.append("Try using more diverse vocabulary to make your story more engaging.")
        }
        
        if retelling.count < Int(Double(original.count) * 0.5) {
            suggestions.append("Your retelling is quite brief. Try to expand on the details and add more context.")
        }
        
        if suggestions.isEmpty {
            suggestions.append("Great job! Your retelling captures the essence of the story well. Keep practicing to refine your skills.")
        }
        
        return suggestions
    }
    
    private func generatePracticeSuggestions(fluency: Double, coherence: Double, vocabulary: Double, transcript: String, duration: TimeInterval) -> [String] {
        var suggestions: [String] = []
        
        if duration < 30 {
            suggestions.append("Try to speak for a bit longer to develop your story more fully.")
        }
        
        if fluency < 0.6 {
            suggestions.append("Work on speaking more smoothly and reducing pauses.")
        }
        
        if coherence < 0.6 {
            suggestions.append("Use connecting words and phrases to link your ideas together.")
        }
        
        if vocabulary < 0.5 {
            suggestions.append("Experiment with different words to make your story more vivid and engaging.")
        }
        
        let wordCount = transcript.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        if wordCount < 50 {
            suggestions.append("Try to expand your story with more details and descriptions.")
        }
        
        if suggestions.isEmpty {
            suggestions.append("Excellent storytelling! You're doing great. Keep practicing to continue improving.")
        }
        
        return suggestions
    }
}
