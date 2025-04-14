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
        VStack {
            switch viewRouter.currentPage {
            case .onboarding:
                
            case .main:
                MainTabView()
                    .environmentObject
            case .prescription:
                PrescriptionListView(prescriptionStore: <#T##PrescriptionStore#>)
                    .environmentObject
            case .settings:
                SettingsView()
                    .environmentObject
            case .search:
                SearchView()
                    .environmentObject
                
            }
        }
        .padding()
    }
}

