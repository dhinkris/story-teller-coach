import Foundation

struct ProgressRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let storyId: UUID?
    let promptId: UUID?
    let metrics: StoryMetrics
    let duration: TimeInterval
    let type: PracticeType
    
    enum PracticeType: String, Codable {
        case storyRetelling
        case freePractice
    }
    
    init(id: UUID = UUID(), date: Date = Date(), storyId: UUID? = nil, promptId: UUID? = nil, metrics: StoryMetrics, duration: TimeInterval, type: PracticeType) {
        self.id = id
        self.date = date
        self.storyId = storyId
        self.promptId = promptId
        self.metrics = metrics
        self.duration = duration
        self.type = type
    }
}

struct OverallProgress: Codable {
    var totalSessions: Int
    var averageSimilarity: Double
    var averageFluency: Double
    var averageCoherence: Double
    var averageVocabulary: Double
    var averageOverall: Double
    var totalPracticeTime: TimeInterval
    var lastPracticeDate: Date?
    
    init() {
        self.totalSessions = 0
        self.averageSimilarity = 0.0
        self.averageFluency = 0.0
        self.averageCoherence = 0.0
        self.averageVocabulary = 0.0
        self.averageOverall = 0.0
        self.totalPracticeTime = 0.0
        self.lastPracticeDate = nil
    }
    
    mutating func update(with records: [ProgressRecord]) {
        guard !records.isEmpty else {
            self = OverallProgress()
            return
        }
        
        totalSessions = records.count
        totalPracticeTime = records.reduce(0) { $0 + $1.duration }
        lastPracticeDate = records.map { $0.date }.max()
        
        averageSimilarity = records.map { $0.metrics.similarityScore }.reduce(0, +) / Double(records.count)
        averageFluency = records.map { $0.metrics.fluencyScore }.reduce(0, +) / Double(records.count)
        averageCoherence = records.map { $0.metrics.coherenceScore }.reduce(0, +) / Double(records.count)
        averageVocabulary = records.map { $0.metrics.vocabularyScore }.reduce(0, +) / Double(records.count)
        averageOverall = records.map { $0.metrics.overallScore }.reduce(0, +) / Double(records.count)
    }
}
