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

struct StoryMetrics: Codable {
    let similarityScore: Double // 0.0 to 1.0
    let fluencyScore: Double // 0.0 to 1.0
    let coherenceScore: Double // 0.0 to 1.0
    let vocabularyScore: Double // 0.0 to 1.0
    let overallScore: Double // 0.0 to 1.0
    let suggestions: [String]
    
    var overallPercentage: Int {
        Int(overallScore * 100)
    }
    
    var similarityPercentage: Int {
        Int(similarityScore * 100)
    }
    
    var fluencyPercentage: Int {
        Int(fluencyScore * 100)
    }
    
    var coherencePercentage: Int {
        Int(coherenceScore * 100)
    }
    
    var vocabularyPercentage: Int {
        Int(vocabularyScore * 100)
    }
}
