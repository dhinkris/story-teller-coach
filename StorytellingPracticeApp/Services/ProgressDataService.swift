import Foundation

class ProgressDataService: ObservableObject {
    @Published var records: [ProgressRecord] = []
    @Published var overallProgress: OverallProgress = OverallProgress()
    
    private let recordsKey = "ProgressRecords"
    private let overallProgressKey = "OverallProgress"
    
    init() {
        loadData()
    }
    
    func saveRecord(_ record: ProgressRecord) {
        records.append(record)
        updateOverallProgress()
        saveData()
    }
    
    func deleteRecord(_ record: ProgressRecord) {
        records.removeAll { $0.id == record.id }
        updateOverallProgress()
        saveData()
    }
    
    func clearAllRecords() {
        records.removeAll()
        overallProgress = OverallProgress()
        saveData()
    }
    
    private func updateOverallProgress() {
        overallProgress.update(with: records)
    }
    
    private func saveData() {
        // Save records
        if let encoded = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(encoded, forKey: recordsKey)
        }
        
        // Save overall progress
        if let encoded = try? JSONEncoder().encode(overallProgress) {
            UserDefaults.standard.set(encoded, forKey: overallProgressKey)
        }
    }
    
    private func loadData() {
        // Load records
        if let data = UserDefaults.standard.data(forKey: recordsKey),
           let decoded = try? JSONDecoder().decode([ProgressRecord].self, from: data) {
            records = decoded
        }
        
        // Load overall progress
        if let data = UserDefaults.standard.data(forKey: overallProgressKey),
           let decoded = try? JSONDecoder().decode(OverallProgress.self, from: data) {
            overallProgress = decoded
        } else {
            updateOverallProgress()
        }
    }
    
    // Get records for a specific time period
    func getRecords(for period: TimePeriod) -> [ProgressRecord] {
        let calendar = Calendar.current
        let now = Date()
        
        switch period {
        case .all:
            return records
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return records.filter { $0.date >= weekAgo }
        case .month:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return records.filter { $0.date >= monthAgo }
        case .year:
            let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return records.filter { $0.date >= yearAgo }
        }
    }
    
    enum TimePeriod {
        case all
        case week
        case month
        case year
    }
}
