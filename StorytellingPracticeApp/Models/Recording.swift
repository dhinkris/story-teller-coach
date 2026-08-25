import Foundation

struct Recording: Identifiable, Codable {
    let id: UUID
    let storyId: UUID?
    let promptId: UUID?
    let transcript: String
    let audioURL: URL
    let duration: TimeInterval
    let createdAt: Date
    let metrics: StoryMetrics?
    
    init(id: UUID = UUID(), storyId: UUID? = nil, promptId: UUID? = nil, transcript: String, audioURL: URL, duration: TimeInterval, createdAt: Date = Date(), metrics: StoryMetrics? = nil) {
        self.id = id
        self.storyId = storyId
        self.promptId = promptId
        self.transcript = transcript
        self.audioURL = audioURL
        self.duration = duration
        self.createdAt = createdAt
        self.metrics = metrics
    }
}

/// Diagnostic sub-scores surfaced per metric. Optional — nil means not yet computed.
struct MetricBreakdown: Codable {
    // Delivery / Fluency
    var wordsPerMinute: Double?      // actual WPM (ideal: 130–160)
    var disfluencyRate: Double?      // filler-word fraction (lower = better)
    var sentenceVariety: Double?     // sentence-length std-dev score

    // Story Fidelity
    var conceptCoverage: Double?     // fraction of key concepts preserved
    var entityCoverage: Double?      // fraction of named entities preserved

    // Narrative Flow
    var temporalScore: Double?       // time-marker density score
    var causalScore: Double?         // causal connective score
    var lexicalChain: Double?        // adjacent-sentence content-word continuity

    // Expression
    var msttr: Double?               // mean segmental type-token ratio
    var sophisticationScore: Double? // lexical sophistication (non-common words)
    var descriptiveDensity: Double?  // adjective + adverb ratio

    // Narrative Arc (free practice)
    var hasSetup: Bool?
    var hasConflict: Bool?
    var hasResolution: Bool?
}

struct StoryMetrics: Codable {
    let similarityScore: Double   // Story Fidelity / Narrative Arc  (0–1)
    let fluencyScore: Double      // Delivery                         (0–1)
    let coherenceScore: Double    // Narrative Flow                   (0–1)
    let vocabularyScore: Double   // Expression / Word Choice         (0–1)
    let overallScore: Double      // Weighted composite               (0–1)
    let suggestions: [String]
    var breakdown: MetricBreakdown?   // optional diagnostic sub-scores

    var overallPercentage:    Int { Int(overallScore    * 100) }
    var similarityPercentage: Int { Int(similarityScore * 100) }
    var fluencyPercentage:    Int { Int(fluencyScore    * 100) }
    var coherencePercentage:  Int { Int(coherenceScore  * 100) }
    var vocabularyPercentage: Int { Int(vocabularyScore * 100) }
}
