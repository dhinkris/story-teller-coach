import SwiftUI

// MARK: - Premium Design System

extension Color {
    // Background layers — warm editorial tone
    static let clayBackground = Color(red: 0.97, green: 0.96, blue: 0.94)
    static let claySurface    = Color(red: 0.92, green: 0.91, blue: 0.89)
    static let clayCard       = Color.white

    // Primary accent — deep authoritative indigo
    static let clayAccent      = Color(red: 0.22, green: 0.32, blue: 0.72)
    static let clayAccentLight = Color(red: 0.40, green: 0.54, blue: 0.90)

    // Warm gold — achievements, highlights, streaks
    static let clayGold      = Color(red: 0.95, green: 0.64, blue: 0.18)
    static let clayGoldLight = Color(red: 1.00, green: 0.84, blue: 0.50)

    // Semantic
    static let claySuccess = Color(red: 0.16, green: 0.65, blue: 0.42)
    static let clayDanger  = Color(red: 0.85, green: 0.25, blue: 0.25)

    // Shadows
    static let clayShadow      = Color.black.opacity(0.07)
    static let clayShadowLight = Color.white.opacity(0.92)
}

// MARK: - Category Theme Colors

extension StoryCategory {
    var themeColor: Color {
        switch self {
        case .technology:        return Color(red: 0.18, green: 0.42, blue: 0.88)
        case .fashion:           return Color(red: 0.82, green: 0.34, blue: 0.60)
        case .fantasy:           return Color(red: 0.50, green: 0.28, blue: 0.84)
        case .socialInteractions: return Color(red: 0.12, green: 0.62, blue: 0.50)
        case .sports:            return Color(red: 0.92, green: 0.40, blue: 0.18)
        }
    }

    var themeGradient: LinearGradient {
        LinearGradient(
            colors: [themeColor, themeColor.opacity(0.75)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Performance Score Helpers

func performanceLabel(for score: Double) -> String {
    switch score {
    case 0.88...: return "Masterful"
    case 0.75..<0.88: return "Polished"
    case 0.60..<0.75: return "Compelling"
    case 0.45..<0.60: return "Developing"
    default: return "Keep Going"
    }
}

func performanceColor(for score: Double) -> Color {
    switch score {
    case 0.88...: return Color(red: 0.16, green: 0.65, blue: 0.42)
    case 0.75..<0.88: return Color(red: 0.22, green: 0.32, blue: 0.72)
    case 0.60..<0.75: return Color(red: 0.95, green: 0.64, blue: 0.18)
    case 0.45..<0.60: return Color(red: 0.90, green: 0.46, blue: 0.20)
    default: return Color(red: 0.85, green: 0.25, blue: 0.25)
    }
}

// MARK: - View Modifiers

struct ClayCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 28
    var padding: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.clayCard)
                    .shadow(color: Color.clayShadow,      radius: 16, x: 6,  y: 6)
                    .shadow(color: Color.clayShadowLight, radius: 16, x: -6, y: -6)
            )
    }
}

struct ClayButtonModifier: ViewModifier {
    var isSelected: Bool = false
    var cornerRadius: CGFloat = 24

    func body(content: Content) -> some View {
        content
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [Color.clayAccent, Color.clayAccentLight],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.clayAccent.opacity(0.30), radius: 10, x: 0, y: 5)
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.clayCard)
                            .shadow(color: Color.clayShadow,      radius: 8, x: 4,  y: 4)
                            .shadow(color: Color.clayShadowLight, radius: 8, x: -4, y: -4)
                    }
                }
            )
    }
}

struct ClaySurfaceModifier: ViewModifier {
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.claySurface)
            )
    }
}

extension View {
    func clayCard(cornerRadius: CGFloat = 28, padding: CGFloat = 20) -> some View {
        modifier(ClayCardModifier(cornerRadius: cornerRadius, padding: padding))
    }

    func clayButton(isSelected: Bool = false, cornerRadius: CGFloat = 24) -> some View {
        modifier(ClayButtonModifier(isSelected: isSelected, cornerRadius: cornerRadius))
    }

    func claySurface(cornerRadius: CGFloat = 16) -> some View {
        modifier(ClaySurfaceModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Shared Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}
