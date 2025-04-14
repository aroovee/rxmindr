

import SwiftUI

struct OnboardingPage: Identifiable{
    let text: String
    let image: String
    let description: String
 

}
struct OnboardingPageView: View {
    let page: OnboardingPage
        var body: some View {
            VStack(spacing: 20) {
                Image(systemName: page.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                Text(page.text)
                    .font(.title)
                    .bold()
                
                Text(page.description)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
    
    
    
    #Preview {
        OnboardingPageView()
    }

