//
//  ContentView.swift
//  MedboxPrescriptionManager
//
//  Created by Aroovee Nandakumar on 10/17/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewRouter: ViewRouter
        
    var body: some View {
        VStack(spacing: 0) {
            switch viewRouter.currentPage {
            case .onboarding:
                OnboardingView()
                    .environmentObject(OnboardingStateManager())
            case .main:
                MainTabView()
                    .environmentObject(OnboardingStateManager())
            case .prescription:
                PrescriptionListView(prescriptionStore: PrescriptionStore.shared)
                    .environmentObject(OnboardingStateManager())
            case .settings:
                SettingsView()
                    .environmentObject(OnboardingStateManager())
            case .search:
                SearchView(prescriptionStore: PrescriptionStore.shared)
                    .environmentObject(OnboardingStateManager())
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

