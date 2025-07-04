import SwiftUI

enum Theme {
    // MARK: - Colors
    static let primary = Color("AccentColor")
    static let secondary = Color.gray.opacity(0.1)
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    
    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [primary.opacity(0.8), primary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundGradient = LinearGradient(
        colors: [Color(.systemBackground), Color(.systemBackground).opacity(0.95)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Shadows
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
    
    static let defaultShadow = ShadowStyle(
        color: Color.black.opacity(0.1),
        radius: 10,
        x: 0,
        y: 4
    )
    
    static let subtleShadow = ShadowStyle(
        color: Color.black.opacity(0.05),
        radius: 5,
        x: 0,
        y: 2
    )
    
    // MARK: - Animation
    static let springAnimation = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let easeAnimation = Animation.easeInOut(duration: 0.2)
    
    // MARK: - Corner Radius
    static let cornerRadius: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 12
    
    // MARK: - Padding
    static let spacing: CGFloat = 16
    static let contentPadding: CGFloat = 20
    
    // MARK: - Custom Button Style
    struct PrimaryButtonStyle: ButtonStyle {
        @Environment(\.isEnabled) private var isEnabled
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    Group {
                        if isEnabled {
                            primaryGradient
                        } else {
                            Color.gray.opacity(0.3)
                        }
                    }
                )
                .foregroundColor(.white)
                .cornerRadius(buttonCornerRadius)
                .shadow(
                    color: defaultShadow.color,
                    radius: configuration.isPressed ? 2 : defaultShadow.radius,
                    x: defaultShadow.x,
                    y: defaultShadow.y
                )
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
                .opacity(isEnabled ? 1 : 0.7)
        }
    }
    
    struct SecondaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .foregroundColor(primary)
                .cornerRadius(buttonCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: buttonCornerRadius)
                        .stroke(primary, lineWidth: 1)
                )
                .shadow(
                    color: subtleShadow.color,
                    radius: configuration.isPressed ? 2 : subtleShadow.radius,
                    x: subtleShadow.x,
                    y: subtleShadow.y
                )
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
        }
    }
    
    // MARK: - Custom Card Style
    struct CardStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(cornerRadius)
                .shadow(
                    color: subtleShadow.color,
                    radius: subtleShadow.radius,
                    x: subtleShadow.x,
                    y: subtleShadow.y
                )
        }
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        modifier(Theme.CardStyle())
    }
}

// MARK: - Custom Navigation Bar Appearance
extension Theme {
    static func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .clear
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
} 