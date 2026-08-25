import SwiftUI

// MARK: - Warm Creative Design System

extension Color {
    // Warm cream canvas
    static let clayBackground  = Color(red: 0.980, green: 0.973, blue: 0.965)

    // Card / surface fills
    static let clayCard        = Color.white
    static let claySurface     = Color(red: 0.965, green: 0.953, blue: 0.945)

    // Primary accent — warm coral
    static let clayAccent      = Color(red: 0.988, green: 0.451, blue: 0.365)
    static let clayAccentLight = Color(red: 0.996, green: 0.588, blue: 0.514)

    // Gold — achievements, highlights (warmer)
    static let clayGold      = Color(red: 1.000, green: 0.722, blue: 0.341)
    static let clayGoldLight = Color(red: 1.000, green: 0.839, blue: 0.549)

    // Semantic
    static let claySuccess = Color(red: 0.251, green: 0.757, blue: 0.408)
    static let clayDanger  = Color(red: 0.941, green: 0.302, blue: 0.361)

    // Hairlines & shadows on a light canvas
    static let clayStroke      = Color.black.opacity(0.06)
    static let clayShadow      = Color.black.opacity(0.08)
    static let clayShadowLight = Color.clear
}

// MARK: - App Background

/// Flat, calm canvas — place inside each screen's ZStack.
struct GlassBackground: View {
    var body: some View {
        Color.clayBackground.ignoresSafeArea()
    }
}

// MARK: - Category Theme Colors

extension StoryCategory {
    var themeColor: Color {
        switch self {
        case .technology:        return Color(red: 0.404, green: 0.600, blue: 0.835)
        case .fashion:           return Color(red: 0.988, green: 0.451, blue: 0.596)
        case .fantasy:           return Color(red: 0.698, green: 0.427, blue: 0.816)
        case .socialInteractions: return Color(red: 0.988, green: 0.451, blue: 0.365)
        case .sports:            return Color(red: 1.000, green: 0.561, blue: 0.275)
        }
    }

    var themeGradient: LinearGradient {
        LinearGradient(
            colors: [themeColor, themeColor.opacity(0.70)],
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
    case 0.88...: return .claySuccess
    case 0.75..<0.88: return .clayAccent
    case 0.60..<0.75: return .clayGold
    case 0.45..<0.60: return Color(red: 0.949, green: 0.549, blue: 0.200)
    default: return .clayDanger
    }
}

// MARK: - Card Modifier

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 12
    var padding: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.clayCard)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: Color.clayShadow, radius: 8, x: 0, y: 2)
    }
}

// MARK: - Button Modifier

struct GlassButtonModifier: ViewModifier {
    var isSelected: Bool = false
    var cornerRadius: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.clayAccent)
                            .shadow(color: Color.clayAccent.opacity(0.25), radius: 8, x: 0, y: 3)
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.clayCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: cornerRadius)
                                    .stroke(Color.clayStroke, lineWidth: 0.8)
                            )
                            .shadow(color: Color.clayShadow, radius: 4, x: 0, y: 2)
                    }
                }
            )
    }
}

// MARK: - Surface Modifier

struct GlassSurfaceModifier: ViewModifier {
    var cornerRadius: CGFloat = 10

    func body(content: Content) -> some View {
        content
            .background(Color.claySurface)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.clayStroke, lineWidth: 0.6)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - View Extensions

extension View {
    func clayCard(cornerRadius: CGFloat = 28, padding: CGFloat = 20) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, padding: padding))
    }

    func clayButton(isSelected: Bool = false, cornerRadius: CGFloat = 24) -> some View {
        modifier(GlassButtonModifier(isSelected: isSelected, cornerRadius: cornerRadius))
    }

    func claySurface(cornerRadius: CGFloat = 16) -> some View {
        modifier(GlassSurfaceModifier(cornerRadius: cornerRadius))
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
