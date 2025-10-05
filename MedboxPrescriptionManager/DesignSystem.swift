import SwiftUI

// MARK: - Design System
struct DesignSystem {
    
    // MARK: - Modern Color Palette (Contemporary Healthcare Theme)
    struct Colors {
        // Primary Colors - Modern Medical Blues with Purple Accent
        static let primary = Color(red: 0.25, green: 0.45, blue: 1.0)           // Modern Medical Blue #4073FF
        static let primaryDark = Color(red: 0.18, green: 0.35, blue: 0.85)      // Deep Medical Blue #2D59D9
        static let primaryLight = Color(red: 0.92, green: 0.95, blue: 1.0)      // Ultra Light Blue #EBEFFF
        
        // Secondary Colors - Sophisticated Purple Gradient
        static let secondary = Color(red: 0.45, green: 0.25, blue: 1.0)         // Medical Purple #7340FF
        static let secondaryDark = Color(red: 0.35, green: 0.18, blue: 0.85)    // Deep Purple #592DD9
        static let secondaryLight = Color(red: 0.95, green: 0.92, blue: 1.0)    // Ultra Light Purple #F2EBFF
        
        // Accent Colors - Vibrant and Professional
        static let accent = Color(red: 0.0, green: 0.85, blue: 0.55)            // Modern Teal #00D98C
        static let accentDark = Color(red: 0.0, green: 0.75, blue: 0.45)        // Deep Teal #00BF73
        static let accentLight = Color(red: 0.90, green: 0.98, blue: 0.95)      // Ultra Light Teal #E6FAF2
        
        // Neutral Colors - Soft Grays
        static let neutral100 = Color(red: 0.98, green: 0.98, blue: 0.98)       // Almost White #FAFAFA
        static let neutral200 = Color(red: 0.95, green: 0.95, blue: 0.95)       // Very Light Gray #F2F2F2
        static let neutral300 = Color(red: 0.88, green: 0.88, blue: 0.88)       // Light Gray #E0E0E0
        static let neutral400 = Color(red: 0.74, green: 0.74, blue: 0.74)       // Medium Gray #BDBDBD
        static let neutral500 = Color(red: 0.62, green: 0.62, blue: 0.62)       // Gray #9E9E9E
        static let neutral600 = Color(red: 0.46, green: 0.46, blue: 0.46)       // Dark Gray #757575
        static let neutral700 = Color(red: 0.26, green: 0.26, blue: 0.26)       // Very Dark Gray #424242
        
        // Status Colors - Modern and Vibrant
        static let success = Color(red: 0.0, green: 0.85, blue: 0.45)           // Modern Success Green #00D973
        static let successLight = Color(red: 0.90, green: 0.98, blue: 0.94)     // Ultra Light Success #E6FAF0
        static let warning = Color(red: 1.0, green: 0.60, blue: 0.0)            // Modern Warning Orange #FF9900
        static let warningLight = Color(red: 1.0, green: 0.95, blue: 0.90)      // Ultra Light Warning #FFF2E6
        static let error = Color(red: 1.0, green: 0.25, blue: 0.45)             // Modern Error Red #FF4073
        static let errorLight = Color(red: 1.0, green: 0.92, blue: 0.95)        // Ultra Light Error #FFEBEF
        
        // Background Colors - Modern Glassmorphism
        static let background = Color(red: 0.98, green: 0.99, blue: 1.0)        // Pure White with Blue Tint #FAFDFF
        static let cardBackground = Color.white.opacity(0.85)                   // Glassmorphism Card
        static let modalBackground = Color.black.opacity(0.4)                   // Modern Modal Overlay
        static let glassBackground = Color.white.opacity(0.25)                  // Glass Effect
        
        // Text Colors
        static let textPrimary = neutral700
        static let textSecondary = neutral500
        static let textTertiary = neutral400
    }
    
    // MARK: - Enhanced Typography System
    struct Typography {
        
        // MARK: - Font Families
        enum FontFamily: String {
            case sfPro = "SF Pro"
            case avenir = "Avenir Next"
            case georgia = "Georgia"
            case menlo = "Menlo"
            case helvetica = "Helvetica Neue"
        }
        
        // MARK: - Hero Display Fonts (Extra Large Headlines)
        static func heroDisplay(weight: Font.Weight = .black, family: FontFamily = .sfPro) -> Font {
            .custom(family.rawValue, size: 42, relativeTo: .largeTitle).weight(weight)
        }
        
        static func heroTitle(weight: Font.Weight = .heavy, family: FontFamily = .avenir) -> Font {
            .custom(family.rawValue, size: 38, relativeTo: .title).weight(weight)
        }
        
        // MARK: - Display Fonts (Large Headers)
        static func displayLarge(weight: Font.Weight = .bold, family: FontFamily = .sfPro) -> Font {
            .custom(family.rawValue, size: 34, relativeTo: .largeTitle).weight(weight)
        }
        
        static func displayMedium(weight: Font.Weight = .bold, family: FontFamily = .sfPro) -> Font {
            .custom(family.rawValue, size: 30, relativeTo: .title).weight(weight)
        }
        
        static func displaySmall(weight: Font.Weight = .semibold, family: FontFamily = .sfPro) -> Font {
            .custom(family.rawValue, size: 26, relativeTo: .title2).weight(weight)
        }
        
        // MARK: - Title Fonts (Section Headers)
        static func titleLarge(weight: Font.Weight = .bold, family: FontFamily = .avenir) -> Font {
            .custom(family.rawValue, size: 22, relativeTo: .title2).weight(weight)
        }
        
        static func titleMedium(weight: Font.Weight = .semibold, family: FontFamily = .avenir) -> Font {
            .custom(family.rawValue, size: 20, relativeTo: .title3).weight(weight)
        }
        
        static func titleSmall(weight: Font.Weight = .semibold, family: FontFamily = .sfPro) -> Font {
            .custom(family.rawValue, size: 18, relativeTo: .headline).weight(weight)
        }
        
        // MARK: - Heading Fonts
        static func headingLarge(weight: Font.Weight = .semibold, family: FontFamily = .sfPro) -> Font {
            .custom(family.rawValue, size: 20, relativeTo: .headline).weight(weight)
        }
        
        static func headingMedium(weight: Font.Weight = .medium, family: FontFamily = .sfPro) -> Font {
            .custom(family.rawValue, size: 18, relativeTo: .subheadline).weight(weight)
        }
        
        static func headingSmall(weight: Font.Weight = .medium, family: FontFamily = .sfPro) -> Font {
            .custom(family.rawValue, size: 16, relativeTo: .callout).weight(weight)
        }
        
        // MARK: - Body Text (Reading Content)
        static func bodyLarge(weight: Font.Weight = .regular, family: FontFamily = .sfPro) -> Font {
            .custom(family.rawValue, size: 17, relativeTo: .body).weight(weight)
        }
        
        static func bodyMedium(weight: Font.Weight = .regular, family: FontFamily = .sfPro) -> Font {
            .custom(family.rawValue, size: 15, relativeTo: .callout).weight(weight)
        }
        
        static func bodySmall(weight: Font.Weight = .regular, family: FontFamily = .sfPro) -> Font {
            .custom(family.rawValue, size: 13, relativeTo: .footnote).weight(weight)
        }
        
        // MARK: - Caption and Label Fonts
        static func captionLarge(weight: Font.Weight = .medium, family: FontFamily = .sfPro) -> Font {
            .custom(family.rawValue, size: 13, relativeTo: .caption).weight(weight)
        }
        
        static func captionMedium(weight: Font.Weight = .regular, family: FontFamily = .sfPro) -> Font {
            .custom(family.rawValue, size: 12, relativeTo: .caption).weight(weight)
        }
        
        static func captionSmall(weight: Font.Weight = .regular, family: FontFamily = .sfPro) -> Font {
            .custom(family.rawValue, size: 11, relativeTo: .caption2).weight(weight)
        }
        
        // MARK: - Special Purpose Fonts
        static func monospace(size: CGFloat = 14, weight: Font.Weight = .regular) -> Font {
            .custom(FontFamily.menlo.rawValue, size: size, relativeTo: .body).weight(weight)
        }
        
        static func elegant(size: CGFloat = 16, weight: Font.Weight = .regular) -> Font {
            .custom(FontFamily.georgia.rawValue, size: size, relativeTo: .body).weight(weight)
        }
        
        static func modern(size: CGFloat = 16, weight: Font.Weight = .medium) -> Font {
            .custom(FontFamily.helvetica.rawValue, size: size, relativeTo: .body).weight(weight)
        }
        
        // MARK: - Contextual Typography
        static func navigationTitle() -> Font {
            titleLarge(weight: .bold, family: .avenir)
        }
        
        static func cardTitle() -> Font {
            headingMedium(weight: .semibold, family: .sfPro)
        }
        
        static func buttonText() -> Font {
            bodyMedium(weight: .semibold, family: .sfPro)
        }
        
        static func fieldLabel() -> Font {
            captionLarge(weight: .medium, family: .sfPro)
        }
        
        static func brandName() -> Font {
            heroTitle(weight: .heavy, family: .avenir)
        }
        
        static func statusText() -> Font {
            captionMedium(weight: .medium, family: .sfPro)
        }
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
        static let huge: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let pill: CGFloat = 100
    }
    
    // MARK: - Modern Shadows and Effects
    struct Shadows {
        static let minimal = (color: Color.black.opacity(0.05), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(1))
        static let soft = (color: Color.black.opacity(0.08), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(4))
        static let medium = (color: Color.black.opacity(0.15), radius: CGFloat(20), x: CGFloat(0), y: CGFloat(8))
        static let strong = (color: Color.black.opacity(0.25), radius: CGFloat(32), x: CGFloat(0), y: CGFloat(16))
        static let floating = (color: Color.black.opacity(0.12), radius: CGFloat(24), x: CGFloat(0), y: CGFloat(12))
        
        // Colored shadows for modern effect
        static let primaryGlow = (color: Colors.primary.opacity(0.3), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
        static let successGlow = (color: Colors.success.opacity(0.3), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
        static let errorGlow = (color: Colors.error.opacity(0.3), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
    }
    
    // MARK: - Modern Gradients and Effects
    struct Gradients {
        // Primary brand gradients
        static let primaryGradient = LinearGradient(
            colors: [Colors.primary, Colors.primaryDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let secondaryGradient = LinearGradient(
            colors: [Colors.secondary, Colors.secondaryDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let accentGradient = LinearGradient(
            colors: [Colors.accent, Colors.accentDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Modern background gradients
        static let backgroundGradient = RadialGradient(
            colors: [Colors.primaryLight.opacity(0.4), Colors.background],
            center: .topLeading,
            startRadius: 0,
            endRadius: 800
        )
        
        static let heroGradient = LinearGradient(
            colors: [Colors.primary, Colors.secondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Glass morphism effects
        static let glassGradient = LinearGradient(
            colors: [Colors.glassBackground, Colors.glassBackground.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let cardGradient = LinearGradient(
            colors: [Colors.cardBackground, Colors.cardBackground.opacity(0.7)],
            startPoint: .top,
            endPoint: .bottom
        )
        
        // Status gradients with depth
        static let successGradient = LinearGradient(
            colors: [Colors.success, Colors.success.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let warningGradient = LinearGradient(
            colors: [Colors.warning, Colors.warning.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let errorGradient = LinearGradient(
            colors: [Colors.error, Colors.error.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Subtle overlay gradients
        static let overlayGradient = LinearGradient(
            colors: [Color.clear, Color.black.opacity(0.3)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Modern Custom Modifiers
struct GlassmorphismCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let blur: Bool
    let shadow: Bool
    
    init(cornerRadius: CGFloat = DesignSystem.CornerRadius.xl, blur: Bool = true, shadow: Bool = true) {
        self.cornerRadius = cornerRadius
        self.blur = blur
        self.shadow = shadow
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(DesignSystem.Gradients.glassGradient)
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                            .opacity(blur ? 1.0 : 0.0)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: shadow ? DesignSystem.Shadows.soft.color : Color.clear,
                        radius: shadow ? DesignSystem.Shadows.soft.radius : 0,
                        x: shadow ? DesignSystem.Shadows.soft.x : 0,
                        y: shadow ? DesignSystem.Shadows.soft.y : 0
                    )
            )
    }
}

struct ModernCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let shadow: Bool
    let elevation: CardElevation
    
    enum CardElevation {
        case minimal, soft, medium, strong, floating
        
        var shadowProperties: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            switch self {
            case .minimal: return DesignSystem.Shadows.minimal
            case .soft: return DesignSystem.Shadows.soft
            case .medium: return DesignSystem.Shadows.medium
            case .strong: return DesignSystem.Shadows.strong
            case .floating: return DesignSystem.Shadows.floating
            }
        }
    }
    
    init(cornerRadius: CGFloat = DesignSystem.CornerRadius.xl, shadow: Bool = true, elevation: CardElevation = .soft) {
        self.cornerRadius = cornerRadius
        self.shadow = shadow
        self.elevation = elevation
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white)
                    .shadow(
                        color: shadow ? elevation.shadowProperties.color : Color.clear,
                        radius: shadow ? elevation.shadowProperties.radius : 0,
                        x: shadow ? elevation.shadowProperties.x : 0,
                        y: shadow ? elevation.shadowProperties.y : 0
                    )
            )
    }
}

struct ModernPrimaryButtonModifier: ViewModifier {
    let isDisabled: Bool
    let style: ButtonStyle
    
    enum ButtonStyle {
        case filled, glassmorphism, floating
    }
    
    init(isDisabled: Bool = false, style: ButtonStyle = .filled) {
        self.isDisabled = isDisabled
        self.style = style
    }
    
    func body(content: Content) -> some View {
        content
            .font(DesignSystem.Typography.bodyLarge(weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.xxl)
            .padding(.vertical, DesignSystem.Spacing.lg)
            .background(backgroundView)
            .scaleEffect(isDisabled ? 0.98 : 1.0)
            .disabled(isDisabled)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .filled:
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(isDisabled ? 
                      LinearGradient(colors: [DesignSystem.Colors.neutral300], startPoint: .center, endPoint: .center) : 
                      DesignSystem.Gradients.primaryGradient)
                .shadow(
                    color: isDisabled ? Color.clear : DesignSystem.Shadows.primaryGlow.color,
                    radius: DesignSystem.Shadows.primaryGlow.radius,
                    x: DesignSystem.Shadows.primaryGlow.x,
                    y: DesignSystem.Shadows.primaryGlow.y
                )
                
        case .glassmorphism:
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .fill(DesignSystem.Gradients.primaryGradient.opacity(0.8))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                )
                
        case .floating:
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.pill)
                .fill(DesignSystem.Gradients.primaryGradient)
                .shadow(
                    color: DesignSystem.Shadows.floating.color,
                    radius: DesignSystem.Shadows.floating.radius,
                    x: DesignSystem.Shadows.floating.x,
                    y: DesignSystem.Shadows.floating.y
                )
        }
    }
}

struct ModernSecondaryButtonModifier: ViewModifier {
    let style: ButtonStyle
    
    enum ButtonStyle {
        case outlined, ghost, subtle
    }
    
    init(style: ButtonStyle = .outlined) {
        self.style = style
    }
    
    func body(content: Content) -> some View {
        content
            .font(DesignSystem.Typography.bodyLarge(weight: .medium))
            .foregroundColor(DesignSystem.Colors.primary)
            .padding(.horizontal, DesignSystem.Spacing.xxl)
            .padding(.vertical, DesignSystem.Spacing.lg)
            .background(backgroundView)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .outlined:
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .strokeBorder(
                            LinearGradient(
                                colors: [DesignSystem.Colors.primary, DesignSystem.Colors.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                
        case .ghost:
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.primaryLight.opacity(0.5))
                
        case .subtle:
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.neutral100)
                .shadow(
                    color: DesignSystem.Shadows.minimal.color,
                    radius: DesignSystem.Shadows.minimal.radius,
                    x: DesignSystem.Shadows.minimal.x,
                    y: DesignSystem.Shadows.minimal.y
                )
        }
    }
}

// MARK: - Modern View Extensions
extension View {
    // Card styles
    func modernCard(cornerRadius: CGFloat = DesignSystem.CornerRadius.xl, shadow: Bool = true, elevation: ModernCardModifier.CardElevation = .soft) -> some View {
        self.modifier(ModernCardModifier(cornerRadius: cornerRadius, shadow: shadow, elevation: elevation))
    }
    
    func glassCard(cornerRadius: CGFloat = DesignSystem.CornerRadius.xl, blur: Bool = true, shadow: Bool = true) -> some View {
        self.modifier(GlassmorphismCardModifier(cornerRadius: cornerRadius, blur: blur, shadow: shadow))
    }
    
    // Legacy card style (kept for compatibility)
    func cardStyle(cornerRadius: CGFloat = DesignSystem.CornerRadius.lg, shadow: Bool = true) -> some View {
        self.modernCard(cornerRadius: cornerRadius, shadow: shadow, elevation: .soft)
    }
    
    // Button styles
    func modernPrimaryButton(isDisabled: Bool = false, style: ModernPrimaryButtonModifier.ButtonStyle = .filled) -> some View {
        self.modifier(ModernPrimaryButtonModifier(isDisabled: isDisabled, style: style))
    }
    
    func modernSecondaryButton(style: ModernSecondaryButtonModifier.ButtonStyle = .outlined) -> some View {
        self.modifier(ModernSecondaryButtonModifier(style: style))
    }
    
    // Legacy button styles (kept for compatibility)
    func primaryButtonStyle(isDisabled: Bool = false) -> some View {
        self.modernPrimaryButton(isDisabled: isDisabled)
    }
    
    func secondaryButtonStyle() -> some View {
        self.modernSecondaryButton()
    }
    
    // Animation helpers
    func modernSpringAnimation() -> some View {
        self.animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0), value: UUID())
    }
    
    func modernEaseAnimation() -> some View {
        self.animation(.easeInOut(duration: 0.3), value: UUID())
    }
    
    // Interactive effects
    func modernTapEffect() -> some View {
        self.scaleEffect(1.0)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.1)) {
                    // Haptic feedback would go here in real implementation
                }
            }
    }
}