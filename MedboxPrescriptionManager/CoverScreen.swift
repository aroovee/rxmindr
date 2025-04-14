import SwiftUI

struct CoverScreen: View {
    @State private var isStarted = false
    @State private var logoScale: CGFloat = 0.8
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    
    var body: some View {
        if isStarted {
            MainTabView()
        } else {
            ZStack {
                // Background - fixed the color initialization
                Color(.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 30) {
                    // Logo and Title
                    VStack(spacing: 20) {
                        // Pill Logo
                        ZStack {
                            // Pill shape
                            Capsule()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 100, height: 200)
                            
                            // Line in middle
                            Rectangle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 100, height: 2)
                            
                            // Rx symbol
                            Text("℞")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                        }
                        .scaleEffect(logoScale)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: logoScale)
                        
                        // App Name
                        Text("Rxmindr")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                            .opacity(textOpacity)
                    }
                    
                    // Start Button
                    Button(action: {
                        withAnimation {
                            isStarted = true
                        }
                    }) {
                        Text("Get Started")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(Color.blue)
                            .cornerRadius(25)
                            .shadow(radius: 5)
                    }
                    .opacity(buttonOpacity)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    logoScale = 1.0
                }
                
                withAnimation(.easeIn(duration: 0.8).delay(0.4)) {
                    textOpacity = 1.0
                }
                
                withAnimation(.easeIn(duration: 0.8).delay(0.8)) {
                    buttonOpacity = 1.0
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
