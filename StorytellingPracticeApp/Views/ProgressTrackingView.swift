import SwiftUI

struct ProgressTrackingView: View {
    @ObservedObject private var progressService = ProgressDataService.shared
    @State private var selectedPeriod: ProgressDataService.TimePeriod = .all
    @State private var showClearConfirmation = false

    private var filteredRecords: [ProgressRecord] {
        progressService.getRecords(for: selectedPeriod)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Period selector at top
                        PeriodSelector(selectedPeriod: $selectedPeriod)

                        // Overall stats
                        OverallProgressCard(progress: progressService.overallProgress)

                        // Skill radar
                        if !progressService.records.isEmpty {
                            RadarChartCard(progress: progressService.overallProgress)
                        }

                        // Progress over time
                        if filteredRecords.count > 1 {
                            ProgressLineChart(records: filteredRecords)
                        }

                        // Session history
                        HistorySection(
                            records: filteredRecords,
                            onDelete: { record in progressService.deleteRecord(record) }
                        )

                        // Clear all
                        if !progressService.records.isEmpty {
                            Button(action: { showClearConfirmation = true }) {
                                HStack(spacing: 7) {
                                    Image(systemName: "trash")
                                    Text("Clear All Progress")
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.clayDanger)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.clayCard)
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.clayDanger.opacity(0.35), lineWidth: 0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Journey")
            .navigationBarTitleDisplayMode(.large)
            .alert("Clear All Progress", isPresented: $showClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    progressService.clearAllRecords()
                }
            } message: {
                Text("This will permanently delete all your session history and scores.")
            }
        }
    }
}

// MARK: - Period Selector

struct PeriodSelector: View {
    @Binding var selectedPeriod: ProgressDataService.TimePeriod

    var body: some View {
        HStack(spacing: 8) {
            periodButton("All",   period: .all)
            periodButton("Week",  period: .week)
            periodButton("Month", period: .month)
            periodButton("Year",  period: .year)
        }
    }

    @ViewBuilder
    private func periodButton(_ label: String, period: ProgressDataService.TimePeriod) -> some View {
        let isSelected = selectedPeriod == period
        Button(action: {
            withAnimation(.spring(response: 0.28)) { selectedPeriod = period }
        }) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .clayButton(isSelected: isSelected, cornerRadius: 20)
        }
    }
}

// MARK: - Overall Progress Card

struct OverallProgressCard: View {
    let progress: OverallProgress

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text("Overview")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                if progress.totalSessions > 0 {
                    Text(performanceLabel(for: progress.averageOverall))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(performanceColor(for: progress.averageOverall))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(performanceColor(for: progress.averageOverall).opacity(0.12))
                        )
                }
            }

            HStack(spacing: 12) {
                StatBox(
                    title: "Sessions",
                    value: "\(progress.totalSessions)",
                    icon: "calendar",
                    color: Color.clayAccent
                )
                StatBox(
                    title: "Avg Score",
                    value: "\(Int(progress.averageOverall * 100))%",
                    icon: "star.fill",
                    color: Color.clayGold
                )
                StatBox(
                    title: "Practice",
                    value: formatTime(progress.totalPracticeTime),
                    icon: "clock.fill",
                    color: Color.claySuccess
                )
            }

            if let lastDate = progress.lastPracticeDate {
                HStack(spacing: 7) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("Last session: \(formatDate(lastDate))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                HStack(spacing: 7) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(Color.clayAccent)
                    Text("Complete your first session to start tracking")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .clayCard(cornerRadius: 28, padding: 22)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.claySurface)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(color.opacity(0.30), lineWidth: 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Radar Chart Card

struct RadarChartCard: View {
    let progress: OverallProgress

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text("Skills Radar")
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
                labels: ["Fidelity", "Delivery", "Flow", "Expression", "Overall"],
                maxValue: 1.0
            )
            .frame(height: 280)
        }
        .clayCard(cornerRadius: 28, padding: 22)
    }
}

// MARK: - Progress Line Chart

struct ProgressLineChart: View {
    let records: [ProgressRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Score Trend")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text("\(records.count) sessions")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
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
                        .stroke(Color.black.opacity(0.07), lineWidth: 1)

                        Text("\(Int(maxScore - (maxScore - minScore) * CGFloat(level) / 4.0))%")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .position(x: 18, y: y)
                    }

                    if records.count > 1 {
                        // Area fill
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: height))
                            for (index, record) in records.enumerated() {
                                let x = width * CGFloat(index) / CGFloat(records.count - 1)
                                let score = CGFloat(record.metrics.overallScore * 100)
                                let y = height * (1 - (score - minScore) / (maxScore - minScore))
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                            path.addLine(to: CGPoint(x: width, y: height))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [Color.clayAccent.opacity(0.25), Color.clayAccent.opacity(0.04)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        // Line
                        Path { path in
                            for (index, record) in records.enumerated() {
                                let x = width * CGFloat(index) / CGFloat(records.count - 1)
                                let score = CGFloat(record.metrics.overallScore * 100)
                                let y = height * (1 - (score - minScore) / (maxScore - minScore))
                                index == 0 ? path.move(to: CGPoint(x: x, y: y)) : path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        .stroke(Color.clayAccent, style: StrokeStyle(lineWidth: 2.5, lineJoin: .round))

                        // Data points
                        ForEach(Array(records.enumerated()), id: \.element.id) { index, record in
                            let x = width * CGFloat(index) / CGFloat(records.count - 1)
                            let score = CGFloat(record.metrics.overallScore * 100)
                            let y = height * (1 - (score - minScore) / (maxScore - minScore))

                            ZStack {
                                Circle()
                                    .fill(Color.clayCard)
                                    .overlay(Circle().stroke(Color.clayStroke, lineWidth: 0.6))
                                    .frame(width: 10, height: 10)
                                Circle()
                                    .fill(Color.clayAccent)
                                    .frame(width: 6, height: 6)
                            }
                            .position(x: x, y: y)
                        }
                    }
                }
            }
            .frame(height: 180)
        }
        .clayCard(cornerRadius: 28, padding: 22)
    }
}

// MARK: - History Section

struct HistorySection: View {
    let records: [ProgressRecord]
    let onDelete: (ProgressRecord) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Session History")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                if !records.isEmpty {
                    Text("\(records.count) sessions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if records.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 38))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("No sessions yet")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text("Complete a retelling or practice session to start your journey.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
            } else {
                ForEach(records.sorted(by: { $0.date > $1.date })) { record in
                    HistoryRow(record: record, onDelete: { onDelete(record) })
                }
            }
        }
        .clayCard(cornerRadius: 28, padding: 22)
    }
}

struct HistoryRow: View {
    let record: ProgressRecord
    let onDelete: () -> Void

    private var sessionIcon: String {
        record.type == .storyRetelling ? "book.fill" : "bolt.fill"
    }

    private var sessionLabel: String {
        record.type == .storyRetelling ? "Story Retelling" : "Open Practice"
    }

    var body: some View {
        HStack(spacing: 14) {
            // Session type icon
            ZStack {
                Circle()
                    .fill(Color.clayAccent.opacity(0.10))
                    .overlay(Circle().stroke(Color.clayAccent.opacity(0.30), lineWidth: 0.7))
                    .frame(width: 38, height: 38)
                Image(systemName: sessionIcon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.clayAccent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(sessionLabel)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(formatDate(record.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(Int(record.metrics.overallScore * 100))%")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(performanceColor(for: record.metrics.overallScore))

                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 9))
                    Text(formatDuration(record.duration))
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(.secondary)
            }

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundColor(Color.clayDanger.opacity(0.6))
            }
            .padding(.leading, 4)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Color.claySurface)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.clayStroke, lineWidth: 0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let m = Int(duration) / 60
        let s = Int(duration) % 60
        return String(format: "%d:%02d", m, s)
    }
}

#Preview {
    ProgressTrackingView()
}
