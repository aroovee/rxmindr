//
//  OnboardingManager.swift
//  Rxmindr
//
//  Created by Aroovee Nandakumar on 4/2/25.
//

import Foundation


class OnboardingStateManager: ObservableObject{
    @Published var completedOnboarding: Bool
    
    init(){
        self.completedOnboarding = UserDefaults.standard.bool(forKey: "completedOnboarding")
    }
    
    func completeOnboarding(){
        completedOnboarding = true
        UserDefaults.standard.set(true, forKey: "completedOnboarding")
    }
}
