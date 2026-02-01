import SwiftUI

struct RadarChartView: View {
    let values: [Double]
    let labels: [String]
    let maxValue: Double
    
    private let numberOfAxes: Int
    
    init(values: [Double], labels: [String], maxValue: Double = 1.0) {
        self.values = values
        self.labels = labels
        self.maxValue = maxValue
        self.numberOfAxes = values.count
    }
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = size * 0.35
            
            ZStack {
                BackgroundCircles(center: center, radius: radius)
                AxesLines(center: center, radius: radius, numberOfAxes: numberOfAxes)
                DataPolygon(center: center, radius: radius, values: values, maxValue: maxValue, numberOfAxes: numberOfAxes)
                DataPoints(center: center, radius: radius, values: values, maxValue: maxValue, numberOfAxes: numberOfAxes)
                Labels(center: center, radius: radius, labels: labels, numberOfAxes: numberOfAxes)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct BackgroundCircles: View {
    let center: CGPoint
    let radius: CGFloat
    
    var body: some View {
        ForEach(0..<5) { level in
            let levelRadius = radius * CGFloat(level + 1) / 5.0
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                .frame(width: levelRadius * 2, height: levelRadius * 2)
                .position(center)
        }
    }
}

struct AxesLines: View {
    let center: CGPoint
    let radius: CGFloat
    let numberOfAxes: Int
    
    var body: some View {
        ForEach(0..<numberOfAxes, id: \.self) { index in
            let angle = calculateAngle(for: index)
            let endPoint = calculateEndPoint(angle: angle, radius: radius, center: center)
            
            Path { path in
                path.move(to: center)
                path.addLine(to: endPoint)
            }
            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        }
    }
    
    private func calculateAngle(for index: Int) -> Double {
        Double(index) * 2 * .pi / Double(numberOfAxes) - .pi / 2
    }
    
    private func calculateEndPoint(angle: Double, radius: CGFloat, center: CGPoint) -> CGPoint {
        let endX = center.x + radius * CGFloat(cos(angle))
        let endY = center.y + radius * CGFloat(sin(angle))
        return CGPoint(x: endX, y: endY)
    }
}

struct DataPolygon: View {
    let center: CGPoint
    let radius: CGFloat
    let values: [Double]
    let maxValue: Double
    let numberOfAxes: Int
    
    var body: some View {
        if !values.isEmpty {
            let path = createPolygonPath()
            let strokePath = createPolygonPath()
            
            path
                .fill(Color.clayAccent.opacity(0.3))
                .overlay(
                    strokePath
                        .stroke(Color.clayAccent, lineWidth: 2)
                )
        }
    }
    
    private func createPolygonPath() -> Path {
        var path = Path()
        
        for (index, value) in values.enumerated() {
            let point = calculateDataPoint(index: index, value: value)
            
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
    
    private func calculateDataPoint(index: Int, value: Double) -> CGPoint {
        let angle = Double(index) * 2 * .pi / Double(numberOfAxes) - .pi / 2
        let normalizedValue = min(value / maxValue, 1.0)
        let pointRadius = radius * CGFloat(normalizedValue)
        let x = center.x + pointRadius * CGFloat(cos(angle))
        let y = center.y + pointRadius * CGFloat(sin(angle))
        return CGPoint(x: x, y: y)
    }
}

struct DataPoints: View {
    let center: CGPoint
    let radius: CGFloat
    let values: [Double]
    let maxValue: Double
    let numberOfAxes: Int
    
    var body: some View {
        ForEach(0..<numberOfAxes, id: \.self) { index in
            let point = calculateDataPoint(index: index, value: values[index])
            
            Circle()
                .fill(Color.clayAccent)
                .frame(width: 8, height: 8)
                .position(point)
        }
    }
    
    private func calculateDataPoint(index: Int, value: Double) -> CGPoint {
        let angle = Double(index) * 2 * .pi / Double(numberOfAxes) - .pi / 2
        let normalizedValue = min(value / maxValue, 1.0)
        let pointRadius = radius * CGFloat(normalizedValue)
        let x = center.x + pointRadius * CGFloat(cos(angle))
        let y = center.y + pointRadius * CGFloat(sin(angle))
        return CGPoint(x: x, y: y)
    }
}

struct Labels: View {
    let center: CGPoint
    let radius: CGFloat
    let labels: [String]
    let numberOfAxes: Int
    
    var body: some View {
        ForEach(0..<numberOfAxes, id: \.self) { index in
            let position = calculateLabelPosition(index: index)
            
            Text(labels[index])
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .position(position)
        }
    }
    
    private func calculateLabelPosition(index: Int) -> CGPoint {
        let angle = Double(index) * 2 * .pi / Double(numberOfAxes) - .pi / 2
        let labelRadius = radius * 1.15
        let x = center.x + labelRadius * CGFloat(cos(angle))
        let y = center.y + labelRadius * CGFloat(sin(angle))
        return CGPoint(x: x, y: y)
    }
}

#Preview {
    RadarChartView(
        values: [0.8, 0.7, 0.9, 0.75, 0.85],
        labels: ["Similarity", "Fluency", "Coherence", "Vocabulary", "Overall"]
    )
    .padding()
}
