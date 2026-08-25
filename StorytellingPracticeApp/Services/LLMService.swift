import Foundation
import NaturalLanguage
import os.log

private let logger = Logger(subsystem: "com.storytellingpractice.app", category: "LLMService")

class LLMService: ObservableObject {
    // MARK: - Public API
    // All analysis is local (on-device) using Apple's NaturalLanguage framework

    func analyzeStoryRetelling(
        originalStory: String,
        userRetelling: String,
        duration: TimeInterval = 0
    ) async throws -> StoryMetrics {
        logger.info("Retelling analysis: local NLP processing")
        return nlpRetellingAnalysis(original: originalStory, retelling: userRetelling, duration: duration)
    }

    func analyzePracticeRecording(transcript: String, duration: TimeInterval) async throws -> StoryMetrics {
        logger.info("Practice analysis: local NLP processing")
        return nlpPracticeAnalysis(transcript: transcript, duration: duration)
    }

    func generatePrompt(category: StoryCategory? = nil) async throws -> StoryPrompt {
        logger.info("Prompt generation: local database")
        return StoryPrompt(text: fallbackPrompt(for: category), imageData: nil, category: category)
    }

    // MARK: - Local NLP Analysis

    private func clamped(_ v: Double) -> Double { max(0.0, min(1.0, v)) }

    private func weightedOverall(
        _ a: Double, _ b: Double, _ c: Double, _ d: Double,
        weights: (Double, Double, Double, Double)
    ) -> Double {
        a * weights.0 + b * weights.1 + c * weights.2 + d * weights.3
    }

    // MARK: - NLP Fallback (Research-Based)

    private func nlpRetellingAnalysis(original: String, retelling: String, duration: TimeInterval) -> StoryMetrics {
        let sim  = storyFidelityScore(original: original, retelling: retelling)
        let flu  = deliveryScore(text: retelling, duration: duration)
        let coh  = narrativeFlowScore(text: retelling)
        let voc  = expressionScore(text: retelling)
        let all  = weightedOverall(sim, flu, coh, voc, weights: (0.30, 0.25, 0.25, 0.20))

        var bd = MetricBreakdown()
        bd.wordsPerMinute   = duration > 0 ? Double(wordCount(retelling)) / (duration / 60) : nil
        bd.disfluencyRate   = disfluencyRate(text: retelling)
        bd.sentenceVariety  = sentenceVarietyScore(text: retelling)
        bd.conceptCoverage  = conceptCoverage(original: original, retelling: retelling)
        bd.entityCoverage   = entityCoverage(original: original, retelling: retelling)
        bd.msttr            = msttr(text: retelling)
        bd.sophisticationScore = sophistication(text: retelling)
        bd.descriptiveDensity  = descriptiveDensity(text: retelling)
        bd.temporalScore    = temporalScore(text: retelling)
        bd.causalScore      = causalScore(text: retelling)
        bd.lexicalChain     = lexicalChainScore(text: retelling)

        return StoryMetrics(
            similarityScore: sim, fluencyScore: flu, coherenceScore: coh,
            vocabularyScore: voc, overallScore: clamped(all),
            suggestions: retellingFallbackSuggestions(sim, flu, coh, voc, bd, original, retelling),
            breakdown: bd
        )
    }

    private func nlpPracticeAnalysis(transcript: String, duration: TimeInterval) -> StoryMetrics {
        let arc  = narrativeArcScore(text: transcript)
        let flu  = deliveryScore(text: transcript, duration: duration)
        let coh  = narrativeFlowScore(text: transcript)
        let voc  = expressionScore(text: transcript)
        let all  = weightedOverall(arc, flu, coh, voc, weights: (0.30, 0.25, 0.25, 0.20))

        var bd = MetricBreakdown()
        bd.wordsPerMinute   = duration > 0 ? Double(wordCount(transcript)) / (duration / 60) : nil
        bd.disfluencyRate   = disfluencyRate(text: transcript)
        bd.sentenceVariety  = sentenceVarietyScore(text: transcript)
        bd.msttr            = msttr(text: transcript)
        bd.sophisticationScore = sophistication(text: transcript)
        bd.descriptiveDensity  = descriptiveDensity(text: transcript)
        bd.temporalScore    = temporalScore(text: transcript)
        bd.causalScore      = causalScore(text: transcript)
        bd.lexicalChain     = lexicalChainScore(text: transcript)
        let (setup, conflict, resolution) = narrativeTriad(text: transcript)
        bd.hasSetup      = setup
        bd.hasConflict   = conflict
        bd.hasResolution = resolution

        return StoryMetrics(
            similarityScore: arc, fluencyScore: flu, coherenceScore: coh,
            vocabularyScore: voc, overallScore: clamped(all),
            suggestions: practiceFallbackSuggestions(arc, flu, coh, voc, bd, transcript, duration),
            breakdown: bd
        )
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Metric 1: Story Fidelity (Retelling Similarity)
    //
    // Research basis: Story Grammar (Stein & Glenn 1979), Prop analysis
    // Measures whether key characters, events, and themes were preserved.
    // Three components: concept coverage, named-entity coverage, length ratio.
    // ─────────────────────────────────────────────────────────────────

    private func storyFidelityScore(original: String, retelling: String) -> Double {
        let cc = conceptCoverage(original: original, retelling: retelling)
        let ec = entityCoverage(original: original, retelling: retelling)
        let lr = lengthRatioScore(original: original, retelling: retelling)
        return clamped(cc * 0.55 + ec * 0.25 + lr * 0.20)
    }

    /// % of important content words from original preserved in retelling.
    private func conceptCoverage(original: String, retelling: String) -> Double {
        let origKeys  = keyContentWords(original)
        let retelKeys = keyContentWords(retelling)
        guard !origKeys.isEmpty else { return 0.5 }
        let overlap = origKeys.intersection(retelKeys)
        return Double(overlap.count) / Double(origKeys.count)
    }

    /// % of named entities (proper nouns) from original preserved in retelling.
    private func entityCoverage(original: String, retelling: String) -> Double {
        let origEnt  = namedEntities(in: original)
        let retelEnt = namedEntities(in: retelling)
        guard !origEnt.isEmpty else { return 0.7 }   // no entities → neutral
        return Double(origEnt.intersection(retelEnt).count) / Double(origEnt.count)
    }

    /// Length ratio score — retelling should be 40–110% of original length.
    private func lengthRatioScore(original: String, retelling: String) -> Double {
        let origWC  = max(1, wordCount(original))
        let retelWC = wordCount(retelling)
        let ratio   = Double(retelWC) / Double(origWC)
        switch ratio {
        case ..<0.15: return 0.1
        case 0.15..<0.30: return 0.1 + (ratio - 0.15) / 0.15 * 0.25
        case 0.30..<0.50: return 0.35 + (ratio - 0.30) / 0.20 * 0.35
        case 0.50..<1.10: return 0.70 + (ratio - 0.50) / 0.60 * 0.30
        case 1.10..<1.50: return max(0.60, 1.00 - (ratio - 1.10) * 0.5)
        default:          return 0.50   // very long retelling
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Metric 2: Delivery (Fluency)
    //
    // Research basis: SALT disfluency measures, WPM norms for storytelling
    // (Clark & Clark 1977: conversational 120–180 WPM; storytelling 130–160)
    // Three components: speaking pace, filler-word rate, sentence variety.
    // ─────────────────────────────────────────────────────────────────

    private func deliveryScore(text: String, duration: TimeInterval) -> Double {
        let paceScore   = paceRating(text: text, duration: duration)
        let disfluScore = 1.0 - min(1.0, disfluencyRate(text: text) / 0.12) // 12% → floor
        let varietyScore = sentenceVarietyScore(text: text)
        let weightedPace = duration > 5 ? 0.40 : 0.00
        let base = disfluScore * 0.45 + varietyScore * 0.20
        return clamped(paceScore * weightedPace + base / (1.0 - weightedPace + 0.001) * (1.0 - weightedPace))
    }

    /// WPM vs. ideal storytelling pace of 130–160 WPM. Returns 0–1.
    private func paceRating(text: String, duration: TimeInterval) -> Double {
        guard duration > 5 else { return 0.65 }   // unknown → neutral-good
        let wpm = Double(wordCount(text)) / (duration / 60.0)
        switch wpm {
        case 130...160: return 1.00
        case 110..<130: return 0.70 + (wpm - 110) / 20.0 * 0.30
        case 160..<185: return 0.70 + (185 - wpm) / 25.0 * 0.30
        case  80..<110: return 0.30 + (wpm -  80) / 30.0 * 0.40
        case 185..<220: return 0.30 + (220 - wpm) / 35.0 * 0.40
        case ..<80:     return max(0.10, wpm / 80.0 * 0.30)
        default:        return 0.15   // ≥ 220 WPM — too fast
        }
    }

    /// Fraction of words that are common disfluencies / fillers.
    private func disfluencyRate(text: String) -> Double {
        let fillers: Set<String> = [
            "um", "uh", "er", "ah", "like", "basically", "literally",
            "actually", "honestly", "right", "okay", "so", "well",
            "i mean", "you know", "sort of", "kind of", "i guess"
        ]
        let words = tokenize(text)
        guard !words.isEmpty else { return 0 }
        let count = words.filter { fillers.contains($0.lowercased()) }.count
        return Double(count) / Double(words.count)
    }

    /// Sentence length std-dev — natural variation (3–9 words) scores well.
    private func sentenceVarietyScore(text: String) -> Double {
        let lengths = sentences(text).map { wordCount($0) }.filter { $0 > 0 }
        guard lengths.count >= 2 else { return 0.50 }
        let avg = Double(lengths.reduce(0, +)) / Double(lengths.count)
        let stdDev = sqrt(lengths.map { pow(Double($0) - avg, 2) }.reduce(0, +) / Double(lengths.count))
        switch stdDev {
        case 3...9: return 1.00
        case 1..<3: return 0.50 + (stdDev - 1) / 2.0 * 0.50
        case 9..<15: return 0.60 + (15 - stdDev) / 6.0 * 0.40
        case ..<1:  return 0.30   // robot-uniform
        default:    return 0.40   // wildly erratic
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Metric 3: Narrative Flow (Coherence)
    //
    // Research basis: Halliday & Hasan (1976) cohesion, Trabasso & van den Broek
    // causal networks. Three components:
    //   - Temporal markers: signal story progression
    //   - Causal connectives: signal cause-effect reasoning
    //   - Lexical chain continuity: adjacent sentences share content words
    // ─────────────────────────────────────────────────────────────────

    private func narrativeFlowScore(text: String) -> Double {
        let temp   = temporalScore(text: text)
        let causal = causalScore(text: text)
        let chain  = lexicalChainScore(text: text)
        return clamped(temp * 0.30 + causal * 0.30 + chain * 0.40)
    }

    /// Density of temporal sequence markers → story progression signals.
    private func temporalScore(text: String) -> Double {
        let markers: Set<String> = [
            "first", "then", "next", "after", "before", "finally", "later",
            "suddenly", "meanwhile", "eventually", "soon", "immediately",
            "when", "while", "once", "previously", "afterward", "initially",
            "subsequently", "at last", "in the end", "just then"
        ]
        let words = tokenize(text)
        guard !words.isEmpty else { return 0.20 }
        let density = Double(words.filter { markers.contains($0) }.count) / Double(words.count)
        // Ideal: 1.5–4% of words are temporal markers
        switch density {
        case 0.015...0.04: return 1.00
        case 0.005..<0.015: return 0.40 + (density - 0.005) / 0.010 * 0.60
        case 0.04..<0.07:  return 0.70 + (0.07 - density) / 0.03 * 0.30
        case ..<0.005:     return max(0.10, density / 0.005 * 0.40)
        default:           return 0.50   // overloaded with markers
        }
    }

    /// Density of causal / logical connectives → reasoning chain quality.
    private func causalScore(text: String) -> Double {
        let connectives = [
            "because", "therefore", "so", "thus", "since", "hence", "consequently",
            "as a result", "which caused", "led to", "due to", "resulting in",
            "this meant", "that made", "so that", "in order to", "which meant"
        ]
        let lower = text.lowercased()
        let hits = connectives.reduce(0) { count, c in
            count + lower.components(separatedBy: c).count - 1
        }
        let sentenceCount = max(1, sentences(text).count)
        let density = Double(hits) / Double(sentenceCount)
        // Ideal: 0.25–0.80 causal markers per sentence
        switch density {
        case 0.25...0.80: return 0.70 + min(density / 0.80, 1.0) * 0.30
        case 0.10..<0.25: return 0.40 + (density - 0.10) / 0.15 * 0.30
        case 0.80..<1.50: return max(0.50, 1.00 - (density - 0.80) * 0.50)
        case ..<0.10:     return max(0.15, density / 0.10 * 0.40)
        default:          return 0.40
        }
    }

    /// % of consecutive sentence pairs that share ≥1 content word (lexical cohesion).
    private func lexicalChainScore(text: String) -> Double {
        let sents = sentences(text)
        guard sents.count >= 2 else { return 0.50 }
        let sentWords = sents.map { keyContentWords($0) }
        var linked = 0
        for i in 1..<sentWords.count {
            if !sentWords[i].intersection(sentWords[i - 1]).isEmpty { linked += 1 }
        }
        let ratio = Double(linked) / Double(sentWords.count - 1)
        // Good storytelling: 40–80% of sentence pairs share a thread
        switch ratio {
        case 0.40...0.80: return 0.70 + (ratio - 0.40) / 0.40 * 0.30
        case 0.20..<0.40: return 0.40 + (ratio - 0.20) / 0.20 * 0.30
        case 0.80..<1.00: return max(0.60, 1.00 - (ratio - 0.80) * 1.50) // too repetitive
        case ..<0.20:     return max(0.10, ratio / 0.20 * 0.40)
        default:          return 0.70
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Metric 4: Expression (Vocabulary)
    //
    // Research basis: Jarvis (2002) MSTTR, Laufer & Nation (1995) lexical
    // frequency profiles, NLTagger POS-based descriptive density.
    // Three components: MSTTR, lexical sophistication, descriptive density.
    // ─────────────────────────────────────────────────────────────────

    private func expressionScore(text: String) -> Double {
        let msttrVal = msttr(text: text)
        let sophVal  = sophistication(text: text)
        let descVal  = descriptiveDensity(text: text)
        return clamped(msttrVal * 0.40 + sophVal * 0.35 + descVal * 0.25)
    }

    /// Mean Segmental TTR — averages TTR across non-overlapping 30-word windows.
    /// More stable than simple TTR and not penalised by longer texts.
    private func msttr(text: String) -> Double {
        let words = tokenize(text).filter { $0.count > 1 }
        guard words.count >= 10 else { return max(0.10, Double(Set(words).count) / Double(max(words.count, 1))) }
        let windowSize = 30
        var ttrs: [Double] = []
        var i = 0
        while i + windowSize <= words.count {
            let window = Array(words[i..<i + windowSize])
            ttrs.append(Double(Set(window).count) / Double(window.count))
            i += windowSize
        }
        if ttrs.isEmpty { ttrs.append(Double(Set(words).count) / Double(words.count)) }
        let avgTTR = ttrs.reduce(0, +) / Double(ttrs.count)
        // MSTTR typical range: 0.55 (repetitive) – 0.90 (very varied)
        return clamped((avgTTR - 0.40) / 0.50)
    }

    /// % of content words that are NOT in the 500 most common English words.
    private func sophistication(text: String) -> Double {
        let content = tokenize(text).filter { $0.count > 2 && !stopWords.contains($0) }
        guard !content.isEmpty else { return 0.20 }
        let sophisticated = content.filter { !ultraCommon500.contains($0) }
        let ratio = Double(sophisticated.count) / Double(content.count)
        // Ideal: 30–60% of content words are non-ultra-common
        switch ratio {
        case 0.30...0.60: return 0.70 + (ratio - 0.30) / 0.30 * 0.30
        case 0.15..<0.30: return 0.40 + (ratio - 0.15) / 0.15 * 0.30
        case 0.60..<0.80: return max(0.60, 1.00 - (ratio - 0.60) * 1.0)
        case ..<0.15:     return max(0.10, ratio / 0.15 * 0.40)
        default:          return 0.50   // > 0.80 — possibly incoherent/jargon
        }
    }

    /// Ratio of adjectives + adverbs to total content words (descriptive richness).
    private func descriptiveDensity(text: String) -> Double {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        var descriptive = 0
        var total = 0
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, _ in
            guard let tag else { return true }
            switch tag {
            case .adjective, .adverb: descriptive += 1; total += 1
            case .noun, .verb:        total += 1
            default: break
            }
            return true
        }
        guard total > 0 else { return 0.30 }
        let ratio = Double(descriptive) / Double(total)
        // Ideal descriptive ratio: 15–30%
        switch ratio {
        case 0.15...0.30: return 0.80 + (ratio - 0.15) / 0.15 * 0.20
        case 0.08..<0.15: return 0.50 + (ratio - 0.08) / 0.07 * 0.30
        case 0.30..<0.45: return max(0.60, 0.80 - (ratio - 0.30) * 1.5)
        case ..<0.08:     return max(0.15, ratio / 0.08 * 0.50)
        default:          return 0.50
        }
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Metric 5: Narrative Arc (Free Practice)
    //
    // Research basis: Labov & Waletzky (1967) narrative structure,
    // Applebee (1978) story forms. Three-act framework: Setup → Conflict → Resolution.
    // ─────────────────────────────────────────────────────────────────

    private func narrativeArcScore(text: String) -> Double {
        let sents = sentences(text)
        guard !sents.isEmpty else { return 0.10 }

        let third = max(1, sents.count / 3)
        let setupSents  = Array(sents.prefix(third))
        let middleSents = Array(sents.dropFirst(third).prefix(third))
        let endSents    = Array(sents.suffix(third))

        let (setup, conflict, resolution) = narrativeTriad(
            setup: setupSents, middle: middleSents, end: endSents
        )

        let setupScore:      Double = setup      ? 1.0 : 0.20
        let conflictScore:   Double = conflict   ? 1.0 : 0.15
        let resolutionScore: Double = resolution ? 1.0 : 0.20

        // Character presence (consistent pronoun/proper-noun references)
        let charScore = characterPresence(text: text)

        // Length adequacy
        let wc = wordCount(text)
        let lengthScore: Double = switch wc {
        case ..<20:       Double(wc) / 20.0 * 0.20
        case 20..<60:     0.20 + Double(wc - 20) / 40.0 * 0.40
        case 60..<120:    0.60 + Double(wc - 60) / 60.0 * 0.25
        default:          0.85 + min(Double(wc - 120) / 200.0 * 0.15, 0.15)
        }

        return clamped(
            setupScore      * 0.25 +
            conflictScore   * 0.28 +
            resolutionScore * 0.22 +
            charScore       * 0.15 +
            lengthScore     * 0.10
        )
    }

    private func narrativeTriad(text: String) -> (setup: Bool, conflict: Bool, resolution: Bool) {
        let sents = sentences(text)
        let third = max(1, sents.count / 3)
        return narrativeTriad(
            setup:  Array(sents.prefix(third)),
            middle: Array(sents.dropFirst(third).prefix(third)),
            end:    Array(sents.suffix(third))
        )
    }

    private func narrativeTriad(
        setup: [String], middle: [String], end: [String]
    ) -> (Bool, Bool, Bool) {
        let setupMarkers:    [String] = ["once", "one day", "there was", "it was", "long ago",
                                         "started", "began", "met", "lived", "found", "had always"]
        let conflictMarkers: [String] = ["but", "however", "suddenly", "problem", "challenge",
                                          "difficult", "struggle", "unexpected", "wrong", "failed",
                                          "crisis", "trouble", "couldn't", "impossible", "obstacle"]
        let resMarkers:      [String] = ["finally", "in the end", "ultimately", "resolved", "learned",
                                          "realized", "decided", "overcame", "achieved", "succeeded",
                                          "understood", "changed", "transformed", "found peace"]
        func contains(_ sents: [String], _ markers: [String]) -> Bool {
            let joined = sents.joined(separator: " ").lowercased()
            return markers.contains { joined.contains($0) }
        }
        return (contains(setup, setupMarkers), contains(middle, conflictMarkers), contains(end, resMarkers))
    }

    /// Presence of consistent character references (proper nouns or he/she/they chains).
    private func characterPresence(text: String) -> Double {
        let sents = sentences(text)
        guard !sents.isEmpty else { return 0.20 }
        let pronouns: Set<String> = ["he", "she", "they", "him", "her", "them", "his", "hers", "their"]
        let sentWithChars = sents.filter { s in
            let words = Set(tokenize(s))
            return !words.intersection(pronouns).isEmpty || namedEntities(in: s).count > 0
        }
        let ratio = Double(sentWithChars.count) / Double(sents.count)
        return clamped(0.20 + ratio * 0.80)
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - NLP Helpers
    // ─────────────────────────────────────────────────────────────────

    private func tokenize(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }
    }

    private func wordCount(_ text: String) -> Int {
        tokenize(text).count
    }

    private func sentences(_ text: String) -> [String] {
        var result: [String] = []
        text.enumerateSubstrings(in: text.startIndex..., options: [.bySentences, .localized]) { sub, _, _, _ in
            if let s = sub?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty { result.append(s) }
        }
        return result.isEmpty ? [text] : result
    }

    /// Content words: length > 3, not in stop-word list.
    private func keyContentWords(_ text: String) -> Set<String> {
        Set(tokenize(text).filter { $0.count > 3 && !stopWords.contains($0) })
    }

    /// Named entities via NLTagger (.name tags — detects people, places, organisations).
    private func namedEntities(in text: String) -> Set<String> {
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        var entities = Set<String>()
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .joinNames]
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, range in
            if tag != nil {
                entities.insert(String(text[range]).lowercased())
            }
            return true
        }
        return entities
    }

    // MARK: - Fallback Suggestions (Coaching Tips)

    private func retellingFallbackSuggestions(
        _ sim: Double, _ flu: Double, _ coh: Double, _ voc: Double,
        _ bd: MetricBreakdown, _ original: String, _ retelling: String
    ) -> [String] {
        var tips: [String] = []

        // Story Fidelity tips
        if sim < 0.50 {
            if let cc = bd.conceptCoverage, cc < 0.40 {
                tips.append("Story Fidelity: You captured fewer than 40% of the story's key ideas. Try re-reading the original to identify the 3–5 most important events before retelling.")
            } else if let ec = bd.entityCoverage, ec < 0.50 {
                tips.append("Story Fidelity: Several characters or places from the original were missing. Introducing them early helps your listener orient themselves.")
            } else {
                tips.append("Story Fidelity: Focus on preserving the key turning points — the moment everything changed — even if you use your own words.")
            }
        } else if sim < 0.70 {
            tips.append("Story Fidelity: Good coverage overall. Try adding a key detail or character motivation you may have glossed over.")
        }

        // Delivery tips
        if flu < 0.55 {
            if let wpm = bd.wordsPerMinute {
                if wpm < 100 {
                    tips.append("Delivery: Your pace was slow (~\(Int(wpm)) WPM). A natural storytelling pace is 130–160 WPM — try recording again with slightly more energy.")
                } else if wpm > 185 {
                    tips.append("Delivery: You spoke quickly (~\(Int(wpm)) WPM). Slow down slightly and pause after important moments to let them land.")
                }
            }
            if let dr = bd.disfluencyRate, dr > 0.06 {
                let pct = Int(dr * 100)
                tips.append("Delivery: About \(pct)% of your words were fillers (\"um\", \"like\", \"you know\"). Practise pausing silently instead — a pause sounds more confident than a filler.")
            }
        }

        // Narrative Flow tips
        if coh < 0.55 {
            if let chain = bd.lexicalChain, chain < 0.35 {
                tips.append("Narrative Flow: Your sentences feel disconnected. Try linking each sentence to the previous one — repeat a key word or use a pronoun to carry the thread forward.")
            } else if let temp = bd.temporalScore, temp < 0.40 {
                tips.append("Narrative Flow: Add time markers like \"first\", \"then\", \"suddenly\", and \"finally\" to guide your listener through the story's timeline.")
            } else {
                tips.append("Narrative Flow: Strengthen cause-and-effect links — tell us not just *what* happened, but *why* it happened and *what it caused*.")
            }
        }

        // Expression tips
        if voc < 0.55 {
            if let m = bd.msttr, m < 0.45 {
                tips.append("Expression: You repeated many of the same words. Challenge yourself to find one vivid synonym for each repeated noun or verb.")
            } else if let desc = bd.descriptiveDensity, desc < 0.10 {
                tips.append("Expression: Your retelling is mostly plot — add at least one sensory detail (what it looked like, sounded like, or felt like) to make scenes come alive.")
            }
        }

        if tips.isEmpty {
            tips.append("Strong retelling! Your version preserved the story well. Next challenge: retell it in under 90 seconds without losing the key plot points.")
        }
        return Array(tips.prefix(4))
    }

    private func practiceFallbackSuggestions(
        _ arc: Double, _ flu: Double, _ coh: Double, _ voc: Double,
        _ bd: MetricBreakdown, _ transcript: String, _ duration: TimeInterval
    ) -> [String] {
        var tips: [String] = []

        // Narrative Arc tips
        if arc < 0.55 {
            let (setup, conflict, resolution) = (bd.hasSetup ?? false, bd.hasConflict ?? false, bd.hasResolution ?? false)
            if !setup {
                tips.append("Narrative Arc: Start with a clear setup — introduce your character and their world in the first two sentences before anything happens.")
            } else if !conflict {
                tips.append("Narrative Arc: Every story needs a complication. Use \"but suddenly…\" or \"then something went wrong…\" to introduce tension.")
            } else if !resolution {
                tips.append("Narrative Arc: Your story ended without a clear resolution. Land it with what your character learned, decided, or changed.")
            }
        }

        // Delivery tips
        if flu < 0.55 {
            if let wpm = bd.wordsPerMinute, wpm > 0 {
                if wpm > 185 { tips.append("Delivery: You spoke at ~\(Int(wpm)) WPM — try slowing down and emphasising key words for more impact.") }
                else if wpm < 100 { tips.append("Delivery: Your pace felt slow (~\(Int(wpm)) WPM). A brisker rhythm of 130–160 WPM will keep listeners engaged.") }
            }
            if let dr = bd.disfluencyRate, dr > 0.06 {
                tips.append("Delivery: Replace filler words with intentional pauses. A one-second pause before a big reveal creates suspense rather than uncertainty.")
            }
        }

        // Flow tips
        if coh < 0.55 {
            tips.append("Story Flow: Use transitional phrases (\"this led to…\", \"as a result…\", \"meanwhile…\") to make each scene feel like a logical consequence of the last.")
        }

        // Word Choice tips
        if voc < 0.55 {
            if let desc = bd.descriptiveDensity, desc < 0.12 {
                tips.append("Word Choice: Paint a picture — pick one moment and describe it with a specific colour, sound, or texture your audience can feel.")
            } else {
                tips.append("Word Choice: Swap generic verbs (\"went\", \"said\", \"got\") for precise ones (\"sprinted\", \"whispered\", \"clutched\") to add energy.")
            }
        }

        let wc = wordCount(transcript)
        if wc < 40 { tips.append("Your story was very brief (\(wc) words). Aim for at least 150 words to fully develop your setup, conflict, and resolution.") }

        if tips.isEmpty {
            tips.append("Excellent storytelling! You delivered a clear arc with vivid language. Try adding an unexpected twist next time to surprise your listener.")
        }
        return Array(tips.prefix(4))
    }

    // ─────────────────────────────────────────────────────────────────
    // MARK: - Word Lists
    // ─────────────────────────────────────────────────────────────────

    private let stopWords: Set<String> = [
        "the","a","an","and","or","but","in","on","at","to","for","of","with",
        "is","was","are","were","be","been","have","has","had","do","did","does",
        "this","that","these","those","it","he","she","they","we","i","you",
        "his","her","their","its","my","your","our","from","by","as","so","then",
        "than","when","what","which","who","will","would","could","should",
        "may","might","can","not","no","up","out","into","about","over","just"
    ]

    /// ~500 most frequent English words (subset used for sophistication scoring).
    private let ultraCommon500: Set<String> = [
        "the","of","to","and","a","in","is","it","you","that","he","was","for",
        "on","are","with","as","his","they","be","at","one","have","this","from",
        "or","had","by","hot","but","some","what","there","we","can","out","other",
        "were","all","your","when","up","use","word","how","said","an","each",
        "she","which","do","their","time","if","will","way","about","many","then",
        "them","would","write","like","so","these","her","long","make","thing",
        "see","him","two","has","look","more","day","could","go","come","did",
        "my","sound","no","most","number","who","over","know","water","than",
        "call","first","people","may","down","side","been","now","find","any",
        "new","work","part","take","get","place","made","live","where","after",
        "back","little","only","round","man","year","came","show","every","good",
        "me","give","our","under","name","very","through","just","form","much",
        "great","think","say","help","low","line","before","turn","cause","same",
        "mean","differ","move","right","boy","old","too","does","tell","sentence",
        "set","three","want","air","well","also","play","small","put","home",
        "read","hand","port","large","spell","add","even","land","here","must",
        "big","high","such","follow","act","why","ask","men","change","went",
        "light","kind","off","need","house","picture","try","again","animal","point",
        "mother","world","near","build","self","earth","father","any","sure","need",
        "keep","never","got","still","own","start","study","should","learn","plant",
        "cover","food","sun","four","head","above","below","kind","field","might",
        "stand","sea","face","left","real","life","few","north","open","seem",
        "together","next","white","children","begin","got","walk","example","ease",
        "paper","group","always","music","those","both","mark","book","letter",
        "until","mile","river","car","feet","care","second","enough","plain","girl",
        "usual","young","ready","above","ever","red","list","though","feel","talk",
        "bird","soon","body","dog","family","direct","pose","song","measure","product",
        "black","short","numeral","class","wind","question","happen","complete","ship",
        "area","half","rock","order","fire","south","problem","piece","told","knew",
        "pass","farm","top","whole","king","size","heard","best","hour","better",
        "true","during","hundred","hold","already","late","always","thought","city",
        "love","cross","room","whole","unit","power","town","fine","drive","stood",
        "contain","front","teach","final","gave","green","quick","develop","sleep",
        "warm","free","minute","strong","special","mind","behind","clear","tail",
        "produce","fact","street","gold","rule","force","island","beautiful","race",
        "fall","past","round","valley","money","miss","done","store","happen","once",
        "base","hear","horse","cut","sure","watch","color","note","nothing","rest",
        "carefully","scientists","inside","wheels","stay","green","known","island"
    ]

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
