import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var onboardingState: OnboardingStateManager
    @State private var currentPage = 0
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            text: "Track Medications",
            image: "pills",
            description: "Keep track of all your prescriptions in one place."
        ),
        OnboardingPage(
            text: "Reminders",
            image: "bell",
            description: "Set reminders to never miss taking your medications."
        ),
        OnboardingPage(
            text: "Scan Prescriptions",
            image: "camera",
            description: "Quickly add medications by scanning your prescription label."
        )
    ]
    
    var body: some View {
        ZStack {
            // Background color
            Color.white.edgesIgnoringSafeArea(.all)
            
            VStack {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        onboardingState.completeOnboarding()
                    }
                    .padding()
                }
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                // Next button
                Button(currentPage == pages.count - 1 ? "Get Started" : "Next") {
                    if currentPage == pages.count - 1 {
                        onboardingState.completeOnboarding()
                    } else {
                        currentPage += 1
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}
