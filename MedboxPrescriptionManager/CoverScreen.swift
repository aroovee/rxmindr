import SwiftUI

struct CoverScreen: View {
    @State private var isStarted = false
    @State private var logoScale: CGFloat = 0.8
    @State private var textOpacity: Double = 0
    
    var body: some View {
        if isStarted {
            MainTabView()
        } else {
            ZStack {
                // Background - fixed the color initialization
                DesignSystem.Colors.background
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 30) {
                    // Logo and Title
                    VStack(spacing: 20) {
                        // Pill Logo
                        ZStack {
                            // Pill shape
                            Capsule()
                                .fill(DesignSystem.Colors.primary.opacity(0.2))
                                .frame(width: 100, height: 200)
                            
                            // Line in middle
                            Rectangle()
                                .fill(DesignSystem.Colors.primary.opacity(0.2))
                                .frame(width: 100, height: 2)
                            
                            // Rx symbol
                            Text("℞")
                                .font(.system(size: 60))
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                        .scaleEffect(logoScale)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: logoScale)
                        
                        // App Name
                        Text("Rxmindr")
                            .font(DesignSystem.Typography.brandName())
                            .foregroundColor(DesignSystem.Colors.primary)
                            .opacity(textOpacity)
                            .shadow(color: DesignSystem.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
            }
            .onAppear {
                // Start logo animation
                withAnimation(.easeOut(duration: 0.8)) {
                    logoScale = 1.0
                }
                
                // Show app name
                withAnimation(.easeIn(duration: 0.8).delay(0.4)) {
                    textOpacity = 1.0
                }
                
                // Automatically transition to main app after animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isStarted = true
                    }
                }
            }
        }
    }
}

// Preview
struct CoverScreen_Previews: PreviewProvider {
    static var previews: some View {
        CoverScreen()
    }
}   
