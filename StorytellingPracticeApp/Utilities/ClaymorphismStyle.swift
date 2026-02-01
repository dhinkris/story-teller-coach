import SwiftUI

// MARK: - Claymorphism Design System

extension Color {
    static let clayBackground = Color(red: 0.95, green: 0.95, blue: 0.97)
    static let clayCard = Color.white
    static let clayAccent = Color(red: 0.4, green: 0.6, blue: 0.9)
    static let clayAccentLight = Color(red: 0.5, green: 0.7, blue: 0.95)
    static let clayShadow = Color.black.opacity(0.08)
    static let clayShadowLight = Color.white.opacity(0.9)
}

struct ClayCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 30
    var padding: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.clayCard)
                    .shadow(color: Color.clayShadow, radius: 20, x: 8, y: 8)
                    .shadow(color: Color.clayShadowLight, radius: 20, x: -8, y: -8)
            )
    }
}

struct ClayButtonModifier: ViewModifier {
    var isSelected: Bool = false
    var cornerRadius: CGFloat = 25
    
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
                            .shadow(color: Color.clayShadow, radius: 15, x: 6, y: 6)
                            .shadow(color: Color.clayShadowLight, radius: 15, x: -6, y: -6)
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.clayCard)
                            .shadow(color: Color.clayShadow, radius: 10, x: 5, y: 5)
                            .shadow(color: Color.clayShadowLight, radius: 10, x: -5, y: -5)
                    }
                }
            )
    }
}

extension View {
    func clayCard(cornerRadius: CGFloat = 30, padding: CGFloat = 20) -> some View {
        modifier(ClayCardModifier(cornerRadius: cornerRadius, padding: padding))
    }
    
    func clayButton(isSelected: Bool = false, cornerRadius: CGFloat = 25) -> some View {
        modifier(ClayButtonModifier(isSelected: isSelected, cornerRadius: cornerRadius))
    }
}
