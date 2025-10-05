import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var onboardingState: OnboardingStateManager
    @State private var currentPage = 0
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            id: ObjectIdentifier(AnyObject.self),
            text: "Track Medications",
            image: "pills",
            description: "Keep track of all your prescriptions in one place."
        ),
        OnboardingPage(
            id: ObjectIdentifier(AnyObject.self),
            text: "Reminders",
            image: "bell",
            description: "Set reminders to never miss taking your medications."
        ),
        OnboardingPage(
            id: ObjectIdentifier(AnyObject.self),
            text: "Scan Prescriptions",
            image: "camera",
            description: "Quickly add medications by scanning your prescription label."
        )
    ]
    
    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            onboardingState.completeOnboarding()
                        }
                    }
                    .font(.body.weight(.medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                
                Spacer()
                
                // Enhanced page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        EnhancedOnboardingPageView(
                            page: pages[index],
                            isActive: currentPage == index
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)
                
                // Custom page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .frame(width: currentPage == index ? 12 : 8, height: currentPage == index ? 12 : 8)
                            .foregroundColor(.white)
                            .opacity(currentPage == index ? 1.0 : 0.5)
                            .scaleEffect(currentPage == index ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentPage)
                    }
                }
                .padding(.bottom, 30)
                
                // Enhanced action button
                VStack(spacing: 16) {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            if currentPage == pages.count - 1 {
                                onboardingState.completeOnboarding()
                            } else {
                                currentPage += 1
                            }
                        }
                    }) {
                        HStack {
                            Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            if currentPage < pages.count - 1 {
                                Image(systemName: "arrow.right")
                                    .font(.body.weight(.semibold))
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.body.weight(.semibold))
                            }
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                    }
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentPage)
                    
                    // Progress indicator
                    HStack {
                        Text("Step \\(currentPage + 1) of \\(pages.count)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        if currentPage > 0 {
                            Button("Back") {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    currentPage -= 1
                                }
                            }
                            .font(.caption.weight(.medium))
                            .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }
}

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.blue.opacity(0.8),
                Color.purple.opacity(0.8),
                Color.mint.opacity(0.6)
            ]),
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

struct EnhancedOnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon with animated background
            ZStack {
                Circle()
                    .frame(width: 120, height: 120)
                    .foregroundStyle(
                        .ultraThinMaterial.opacity(0.8)
                    )
                    .scaleEffect(showContent ? 1.0 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2), value: showContent)
                
                Image(systemName: page.image)
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.white)
                    .scaleEffect(showContent ? 1.0 : 0.5)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.4), value: showContent)
            }
            
            // Text content
            VStack(spacing: 16) {
                Text(page.text)
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)
                    .animation(.easeOut(duration: 0.8).delay(0.6), value: showContent)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.8), value: showContent)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: isActive) { active in
            if active {
                showContent = true
            } else {
                showContent = false
            }
        }
        .onAppear {
            if isActive {
                showContent = true
            }
        }
    }
}
