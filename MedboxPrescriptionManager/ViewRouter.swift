//
//  ViewRouter.swift
//  Rxmindr
//
//  Created by Aroovee Nandakumar on 3/29/25.
//

import Foundation


import SwiftUI

class ViewRouter: ObservableObject{
    enum appScreen {
        case onboarding
        case main
        case prescription
        case settings
        case search
    }
    
    @Published var currentPage: appScreen
   
    
    func navigateTo(screen: appScreen){
        currentPage = screen
    }
    init(initialPage: appScreen = .main){
        currentPage.self = initialPage
    }
}
