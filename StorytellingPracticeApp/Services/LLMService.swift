import Foundation
import NaturalLanguage
import os.log

private let logger = Logger(subsystem: "com.storytellingpractice.app", category: "LLMService")

class LLMService: ObservableObject {
    /// True when the last analysis was powered by Ollama; false when rule-based NLP was used.
    @Published var lastAnalysisWasAI = false

    private let ollama = LlamaService()

    // MARK: - Public API

    /// Analyse a story retelling. Tries Ollama first; falls back to local NLP.
    func analyzeStoryRetelling(originalStory: String, userRetelling: String) async throws -> StoryMetrics {
        do {
            let metrics = try await aiRetellingAnalysis(original: originalStory, retelling: userRetelling)
            await MainActor.run { lastAnalysisWasAI = true }
            logger.info("Retelling analysis: AI (\(metrics.overallPercentage)%)")
            return metrics
        } catch {
            logger.warning("Ollama unavailable, using NLP fallback: \(error.localizedDescription)")
            await MainActor.run { lastAnalysisWasAI = false }
            return nlpRetellingAnalysis(original: originalStory, retelling: userRetelling)
        }
    }

    /// Analyse a free-practice recording. Tries Ollama first; falls back to local NLP.
    func analyzePracticeRecording(transcript: String, duration: TimeInterval) async throws -> StoryMetrics {
        do {
            let metrics = try await aiPracticeAnalysis(transcript: transcript)
            await MainActor.run { lastAnalysisWasAI = true }
            logger.info("Practice analysis: AI (\(metrics.overallPercentage)%)")
            return metrics
        } catch {
            logger.warning("Ollama unavailable, using NLP fallback: \(error.localizedDescription)")
            await MainActor.run { lastAnalysisWasAI = false }
            return nlpPracticeAnalysis(transcript: transcript, duration: duration)
        }
    }

    /// Generate a storytelling prompt via Ollama, falling back to curated prompts.
    func generatePrompt(category: StoryCategory? = nil) async throws -> StoryPrompt {
        do {
            let text = try await ollama.generateStoryPrompt(category: category?.rawValue)
            let cleaned = text
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\"", with: "")
            return StoryPrompt(
                text: cleaned.isEmpty ? fallbackPrompt(for: category) : cleaned,
                imageData: nil,
                category: category
            )
        } catch {
            logger.warning("Prompt generation failed, using fallback: \(error.localizedDescription)")
            return StoryPrompt(text: fallbackPrompt(for: category), imageData: nil, category: category)
        }
    }

    // MARK: - Ollama / AI Analysis

    private struct RetellingAnalysis: Codable {
        let similarity: Double
        let fluency: Double
        let coherence: Double
        let vocabulary: Double
        let suggestions: [String]
    }

    private struct PracticeAnalysis: Codable {
        let narrativeArc: Double
        let fluency: Double
        let coherence: Double
        let vocabulary: Double
        let suggestions: [String]
    }

    private func aiRetellingAnalysis(original: String, retelling: String) async throws -> StoryMetrics {
        let prompt = """
        You are a storytelling coach. Score this retelling and return ONLY valid JSON — no other text, no markdown.

        ORIGINAL STORY:
        \(original.prefix(800))

        USER'S RETELLING:
        \(retelling)

        Return this exact JSON (scores 0.0–1.0, be honest and specific):
        {
          "similarity": 0.0,
          "fluency": 0.0,
          "coherence": 0.0,
          "vocabulary": 0.0,
          "suggestions": ["tip 1", "tip 2", "tip 3"]
        }

        Scoring criteria:
        - similarity: how well key characters, events, and themes were preserved
        - fluency: natural rhythm, sentence variety, smooth delivery
        - coherence: logical flow, good transitions, clear narrative structure
        - vocabulary: word richness, precision, and variety
        - suggestions: 2–4 specific, actionable coaching tips referencing the actual retelling

        Return ONLY the JSON object.
        """

        let raw = try await ollama.analyzeText(prompt: prompt)
        guard let analysis = extractJSON(RetellingAnalysis.self, from: raw) else {
            throw LLMError.parseError("Could not parse retelling JSON from: \(raw.prefix(200))")
        }

        let overall = (analysis.similarity + analysis.fluency + analysis.coherence + analysis.vocabulary) / 4.0
        return StoryMetrics(
            similarityScore: clamped(analysis.similarity),
            fluencyScore:    clamped(analysis.fluency),
            coherenceScore:  clamped(analysis.coherence),
            vocabularyScore: clamped(analysis.vocabulary),
            overallScore:    clamped(overall),
            suggestions:     analysis.suggestions.filter { !$0.isEmpty }
        )
    }

    private func aiPracticeAnalysis(transcript: String) async throws -> StoryMetrics {
        let prompt = """
        You are a storytelling coach. Evaluate this improvised story and return ONLY valid JSON — no other text, no markdown.

        TRANSCRIPT:
        \(transcript)

        Return this exact JSON (scores 0.0–1.0):
        {
          "narrativeArc": 0.0,
          "fluency": 0.0,
          "coherence": 0.0,
          "vocabulary": 0.0,
          "suggestions": ["tip 1", "tip 2", "tip 3"]
        }

        Scoring criteria:
        - narrativeArc: clear structure — setup, tension, resolution
        - fluency: natural rhythm, sentence variety, smooth delivery
        - coherence: ideas connect logically, good transitions
        - vocabulary: word richness, precision, and variety
        - suggestions: 2–4 specific, actionable coaching tips

        Return ONLY the JSON object.
        """

        let raw = try await ollama.analyzeText(prompt: prompt)
        guard let analysis = extractJSON(PracticeAnalysis.self, from: raw) else {
            throw LLMError.parseError("Could not parse practice JSON from: \(raw.prefix(200))")
        }

        let overall = (analysis.narrativeArc + analysis.fluency + analysis.coherence + analysis.vocabulary) / 4.0
        return StoryMetrics(
            similarityScore: clamped(analysis.narrativeArc),
            fluencyScore:    clamped(analysis.fluency),
            coherenceScore:  clamped(analysis.coherence),
            vocabularyScore: clamped(analysis.vocabulary),
            overallScore:    clamped(overall),
            suggestions:     analysis.suggestions.filter { !$0.isEmpty }
        )
    }

    // MARK: - JSON Extraction

    private func extractJSON<T: Decodable>(_ type: T.Type, from raw: String) -> T? {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        // Strip markdown code fences
        for fence in ["```json", "```JSON", "```"] {
            if text.hasPrefix(fence) {
                text = String(text.dropFirst(fence.count))
                if text.hasSuffix("```") { text = String(text.dropLast(3)) }
                text = text.trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }
        // Find outermost JSON object
        guard let start = text.firstIndex(of: "{"),
              let end   = text.lastIndex(of: "}") else { return nil }
        guard let data = String(text[start...end]).data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func clamped(_ v: Double) -> Double { max(0.0, min(1.0, v)) }

    // MARK: - NLP Fallback Analysis

    private func nlpRetellingAnalysis(original: String, retelling: String) -> StoryMetrics {
        let sim  = nlpSimilarity(original: original, retelling: retelling)
        let flu  = nlpFluency(text: retelling)
        let coh  = nlpCoherence(text: retelling)
        let voc  = nlpVocabulary(text: retelling)
        let all  = (sim + flu + coh + voc) / 4.0
        return StoryMetrics(
            similarityScore: sim, fluencyScore: flu, coherenceScore: coh,
            vocabularyScore: voc, overallScore: all,
            suggestions: retellingFallbackSuggestions(sim, flu, coh, voc, original, retelling)
        )
    }

    private func nlpPracticeAnalysis(transcript: String, duration: TimeInterval) -> StoryMetrics {
        let flu = nlpFluency(text: transcript)
        let coh = nlpCoherence(text: transcript)
        let voc = nlpVocabulary(text: transcript)
        let arc = (flu + coh + voc) / 3.0
        let all = (arc + flu + coh + voc) / 4.0
        return StoryMetrics(
            similarityScore: arc, fluencyScore: flu, coherenceScore: coh,
            vocabularyScore: voc, overallScore: all,
            suggestions: practiceFallbackSuggestions(flu, coh, voc, transcript, duration)
        )
    }

    // MARK: - NLP Metrics

    private func nlpSimilarity(original: String, retelling: String) -> Double {
        let a = Set(original.lowercased().components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty })
        let b = Set(retelling.lowercased().components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty })
        let union = a.union(b)
        guard !union.isEmpty else { return 0.0 }
        return Double(a.intersection(b).count) / Double(union.count)
    }

    private func nlpFluency(text: String) -> Double {
        let tagger = NLTagger(tagSchemes: [.tokenType])
        tagger.string = text
        var lengths: [Int] = []
        var current = 0
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .tokenType) { tag, range in
            if tag == .word { current += 1 }
            if range.upperBound < text.endIndex {
                let c = text[range.upperBound]
                if c == "." || c == "!" || c == "?" { if current > 0 { lengths.append(current); current = 0 } }
            }
            return true
        }
        if current > 0 { lengths.append(current) }
        guard !lengths.isEmpty else { return 0.0 }
        let avg = Double(lengths.reduce(0, +)) / Double(lengths.count)
        let variance = lengths.map { pow(Double($0) - avg, 2) }.reduce(0, +) / Double(lengths.count)
        return max(0.0, min(1.0, 1.0 - min(variance / 100.0, 1.0)))
    }

    private func nlpCoherence(text: String) -> Double {
        let t = ["however","therefore","meanwhile","furthermore","consequently","additionally","moreover",
                 "nevertheless","thus","hence","because","although","despite","while","since",
                 "after","before","during","finally","initially","subsequently","simultaneously"]
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard !words.isEmpty else { return 0.3 }
        return max(0.3, min(Double(words.filter { t.contains($0) }.count) * 50.0 / Double(words.count), 1.0))
    }

    private func nlpVocabulary(text: String) -> Double {
        let words = text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { $0.count > 2 }
        guard !words.isEmpty else { return 0.0 }
        return min(Double(Set(words).count) / Double(words.count) + 0.1, 1.0)
    }

    // MARK: - Fallback Suggestions

    private func retellingFallbackSuggestions(_ sim: Double, _ flu: Double, _ coh: Double,
                                               _ voc: Double, _ original: String, _ retelling: String) -> [String] {
        var s: [String] = []
        if sim < 0.6 { s.append("Include more key details, characters, and themes from the original.") }
        if flu < 0.6 { s.append("Vary your sentence length to create a more natural rhythm.") }
        if coh < 0.6 { s.append("Use transition words (however, therefore, finally) to link your ideas.") }
        if voc < 0.5 { s.append("Use more descriptive vocabulary to make the story richer and more vivid.") }
        if retelling.count < Int(Double(original.count) * 0.5) {
            s.append("Your retelling is brief — try to expand on key scenes and characters.")
        }
        if s.isEmpty { s.append("Great retelling! Your delivery captures the essence of the story well.") }
        return s
    }

    private func practiceFallbackSuggestions(_ flu: Double, _ coh: Double, _ voc: Double,
                                              _ transcript: String, _ duration: TimeInterval) -> [String] {
        var s: [String] = []
        if duration < 30 { s.append("Try speaking for at least 30–60 seconds to fully develop your story.") }
        if flu  < 0.6  { s.append("Work on smooth, varied sentence structure to improve delivery.") }
        if coh  < 0.6  { s.append("Use connecting phrases to guide your listener through the narrative.") }
        if voc  < 0.5  { s.append("Experiment with descriptive language to paint a vivid picture.") }
        let wc = transcript.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        if wc < 50 { s.append("Expand your story with sensory details, character motivation, or a twist.") }
        if s.isEmpty { s.append("Strong storytelling! Keep exploring different genres and narrative styles.") }
        return s
    }

    // MARK: - Fallback Prompts

    private func fallbackPrompt(for category: StoryCategory?) -> String {
        let generic = [
            "Tell a story about a person who discovers something unexpected about themselves.",
            "Describe a moment when a small decision changed everything.",
            "Narrate a story about two strangers who find common ground.",
            "Share a tale about someone who overcomes their greatest fear.",
            "Describe a day that starts ordinary but becomes extraordinary.",
            "Tell a story about a choice that reveals someone's true character.",
            "Narrate a story about friendship that transcends all boundaries.",
            "Describe a moment of transformation that nobody saw coming."
        ]
        let byCategory: [StoryCategory: [String]] = [
            .technology: [
                "Tell a story about someone who creates technology that solves a real-world problem.",
                "Describe a day in a world where AI and humans collaborate seamlessly.",
                "Narrate a story about a digital discovery that changes a life overnight."
            ],
            .fashion: [
                "Tell a story about a piece of clothing passed down through three generations.",
                "Describe how one outfit gave someone the confidence to change their life.",
                "Narrate a story about a designer who breaks every rule — and wins."
            ],
            .fantasy: [
                "Tell a story about discovering magic hidden inside an everyday object.",
                "Describe a meeting with a creature that only appears at dusk.",
                "Narrate a quest where the greatest obstacle is the hero's own doubt."
            ],
            .socialInteractions: [
                "Tell a story about a conversation that changed two people forever.",
                "Describe how a small act of kindness started an unexpected chain of events.",
                "Narrate a story about breaking down a wall that had stood for years."
            ],
            .sports: [
                "Tell a story about an athlete who finds strength they never knew they had.",
                "Describe a moment where teamwork turned certain defeat into victory.",
                "Narrate a comeback that started with the hardest decision of all."
            ]
        ]
        return (category.flatMap { byCategory[$0] } ?? generic).randomElement() ?? generic[0]
    }
}

// MARK: - Errors

enum LLMError: LocalizedError {
    case parseError(String)
    var errorDescription: String? {
        if case .parseError(let msg) = self { return "Analysis error: \(msg)" }
        return nil
    }
}
