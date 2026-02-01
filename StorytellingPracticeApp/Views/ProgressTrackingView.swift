import SwiftUI

struct ProgressTrackingView: View {
    @StateObject private var progressService = ProgressDataService()
    @State private var selectedPeriod: ProgressDataService.TimePeriod = .all
    @State private var showClearConfirmation = false
    
    private var filteredRecords: [ProgressRecord] {
        progressService.getRecords(for: selectedPeriod)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.clayBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Overall Progress Card
                        OverallProgressCard(progress: progressService.overallProgress)
                        
                        // Radar Chart
                        if !progressService.records.isEmpty {
                            RadarChartCard(progress: progressService.overallProgress)
                        }
                        
                        // Progress Chart
                        if !filteredRecords.isEmpty {
                            ProgressLineChart(records: filteredRecords)
                        }
                        
                        // History Section
                        HistorySection(
                            records: filteredRecords,
                            onDelete: { record in
                                progressService.deleteRecord(record)
                            }
                        )
                        
                        // Period Selector
                        PeriodSelector(selectedPeriod: $selectedPeriod)
                        
                        // Clear All Button
                        if !progressService.records.isEmpty {
                            Button(action: {
                                showClearConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Clear All Progress")
                                }
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.red.opacity(0.1))
                                )
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .alert("Clear All Progress", isPresented: $showClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    progressService.clearAllRecords()
                }
            } message: {
                Text("Are you sure you want to delete all progress data? This action cannot be undone.")
            }
        }
    }
}

struct OverallProgressCard: View {
    let progress: OverallProgress
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Overall Progress")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            HStack(spacing: 20) {
                StatBox(
                    title: "Sessions",
                    value: "\(progress.totalSessions)",
                    icon: "calendar"
                )
                
                StatBox(
                    title: "Avg Score",
                    value: "\(Int(progress.averageOverall * 100))%",
                    icon: "star.fill"
                )
                
                StatBox(
                    title: "Practice Time",
                    value: formatTime(progress.totalPracticeTime),
                    icon: "clock.fill"
                )
            }
            
            if let lastDate = progress.lastPracticeDate {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.secondary)
                    Text("Last practice: \(formatDate(lastDate))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .clayCard(cornerRadius: 28, padding: 24)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color.clayAccent)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.clayAccent.opacity(0.1))
        )
    }
}

struct RadarChartCard: View {
    let progress: OverallProgress
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Skills Overview")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            RadarChartView(
                values: [
                    progress.averageSimilarity,
                    progress.averageFluency,
                    progress.averageCoherence,
                    progress.averageVocabulary,
                    progress.averageOverall
                ],
                labels: [
                    "Similarity",
                    "Fluency",
                    "Coherence",
                    "Vocabulary",
                    "Overall"
                ],
                maxValue: 1.0
            )
            .frame(height: 300)
        }
        .clayCard(cornerRadius: 28, padding: 24)
    }
}

struct ProgressLineChart: View {
    let records: [ProgressRecord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Progress Over Time")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let maxScore: CGFloat = 100
                let minScore: CGFloat = 0
                
                ZStack {
                    // Grid lines
                    ForEach(0..<5) { level in
                        let y = height * CGFloat(level) / 4.0
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: width, y: y))
                        }
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    }
                    
                    // Y-axis labels
                    ForEach(0..<5) { level in
                        let y = height * CGFloat(level) / 4.0
                        let value = maxScore - (maxScore - minScore) * CGFloat(level) / 4.0
                        Text("\(Int(value))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .position(x: 30, y: y)
                    }
                    
                    if records.count > 1 {
                        // Line path
                        Path { path in
                            for (index, record) in records.enumerated() {
                                let x = width * CGFloat(index) / CGFloat(records.count - 1)
                                let score = CGFloat(record.metrics.overallScore * 100)
                                let normalizedScore = (score - minScore) / (maxScore - minScore)
                                let y = height * (1 - normalizedScore)
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Color.clayAccent, lineWidth: 3)
                        
                        // Area under curve
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: height))
                            
                            for (index, record) in records.enumerated() {
                                let x = width * CGFloat(index) / CGFloat(records.count - 1)
                                let score = CGFloat(record.metrics.overallScore * 100)
                                let normalizedScore = (score - minScore) / (maxScore - minScore)
                                let y = height * (1 - normalizedScore)
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                            
                            path.addLine(to: CGPoint(x: width, y: height))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [Color.clayAccent.opacity(0.3), Color.clayAccent.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        // Data points
                        ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                            let x = width * CGFloat(index) / CGFloat(records.count - 1)
                            let score = CGFloat(record.metrics.overallScore * 100)
                            let normalizedScore = (score - minScore) / (maxScore - minScore)
                            let y = height * (1 - normalizedScore)
                            
                            Circle()
                                .fill(Color.clayAccent)
                                .frame(width: 8, height: 8)
                                .position(x: x, y: y)
                        }
                    }
                }
            }
            .frame(height: 200)
        }
        .clayCard(cornerRadius: 28, padding: 24)
    }
}

struct HistorySection: View {
    let records: [ProgressRecord]
    let onDelete: (ProgressRecord) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("History")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text("\(records.count) sessions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if records.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("No records yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(records.sorted(by: { $0.date > $1.date })) { record in
                    HistoryRow(record: record, onDelete: { onDelete(record) })
                }
            }
        }
        .clayCard(cornerRadius: 28, padding: 24)
    }
}

struct HistoryRow: View {
    let record: ProgressRecord
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Date
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(record.date))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(record.type == .storyRetelling ? "Story Retelling" : "Free Practice")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Score
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(record.metrics.overallScore * 100))%")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor(record.metrics.overallScore))
                
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 8))
                    Text(formatDuration(record.duration))
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.red.opacity(0.7))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.clayAccent.opacity(0.05))
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
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

struct PeriodSelector: View {
    @Binding var selectedPeriod: ProgressDataService.TimePeriod
    
    var body: some View {
        HStack(spacing: 12) {
            PeriodButton(title: "All", period: .all, selected: selectedPeriod == .all) {
                selectedPeriod = .all
            }
            PeriodButton(title: "Week", period: .week, selected: selectedPeriod == .week) {
                selectedPeriod = .week
            }
            PeriodButton(title: "Month", period: .month, selected: selectedPeriod == .month) {
                selectedPeriod = .month
            }
            PeriodButton(title: "Year", period: .year, selected: selectedPeriod == .year) {
                selectedPeriod = .year
            }
        }
    }
}

struct PeriodButton: View {
    let title: String
    let period: ProgressDataService.TimePeriod
    let selected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(selected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .clayButton(isSelected: selected, cornerRadius: 20)
        }
    }
}

#Preview {
    ProgressTrackingView()
}
