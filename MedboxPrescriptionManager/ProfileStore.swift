import Foundation
import SwiftUI
import Combine

class ProfileStore: ObservableObject {
    @Published var profiles: [Profile] = []
    @Published var currentProfile: Profile?
    
    private let profilesKey = "SavedProfiles"
    private let currentProfileKey = "CurrentProfile"
    
    init() {
        loadProfiles()
        if profiles.isEmpty {
            createDefaultProfile()
        }
        if currentProfile == nil {
            currentProfile = profiles.first
        }
    }
    
    // MARK: - Profile Management
    
    func addProfile(_ profile: Profile) {
        // Ensure only one default profile
        if profile.isDefault {
            profiles = profiles.map { existingProfile in
                return existingProfile.updated(isDefault: false)
            }
        }
        
        profiles.append(profile)
        
        // Set as current if it's the default or if no current profile
        if profile.isDefault || currentProfile == nil {
            currentProfile = profile
        }
        
        saveProfiles()
    }
    
    func updateProfile(_ profile: Profile) {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        
        // Handle default profile logic
        if profile.isDefault {
            profiles = profiles.map { existingProfile in
                if existingProfile.id != profile.id {
                    return existingProfile.updated(isDefault: false)
                }
                return existingProfile
            }
        }
        
        profiles[index] = profile
        
        // Update current profile if it's the one being updated
        if currentProfile?.id == profile.id {
            currentProfile = profile
        }
        
        // Set as current if it became the default
        if profile.isDefault {
            currentProfile = profile
        }
        
        saveProfiles()
    }
    
    func deleteProfile(_ profile: Profile) {
        guard profiles.count > 1 else { 
            // Don't allow deleting the last profile
            return 
        }
        
        profiles.removeAll { $0.id == profile.id }
        
        // If the deleted profile was current, switch to the first available or default
        if currentProfile?.id == profile.id {
            currentProfile = profiles.first { $0.isDefault } ?? profiles.first
        }
        
        saveProfiles()
    }
    
    func switchToProfile(_ profile: Profile) {
        guard profiles.contains(where: { $0.id == profile.id }) else { return }
        currentProfile = profile
        saveCurrentProfile()
    }
    
    func setDefaultProfile(_ profile: Profile) {
        var updatedProfile = profile
        updatedProfile.isDefault = true
        updateProfile(updatedProfile)
    }
    
    // MARK: - Computed Properties
    
    var defaultProfile: Profile? {
        profiles.first { $0.isDefault }
    }
    
    var nonCurrentProfiles: [Profile] {
        profiles.filter { $0.id != currentProfile?.id }
    }
    
    // MARK: - Private Methods
    
    private func createDefaultProfile() {
        let defaultProfile = Profile(
            name: "Me",
            profileColor: DesignSystem.Colors.primary.toHex() ?? "#6BB0DA",
            profileIcon: "person.fill",
            isDefault: true
        )
        addProfile(defaultProfile)
    }
    
    private func saveProfiles() {
        if let encoded = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(encoded, forKey: profilesKey)
        }
        saveCurrentProfile()
    }
    
    private func saveCurrentProfile() {
        if let currentProfile = currentProfile,
           let encoded = try? JSONEncoder().encode(currentProfile) {
            UserDefaults.standard.set(encoded, forKey: currentProfileKey)
        }
    }
    
    private func loadProfiles() {
        if let data = UserDefaults.standard.data(forKey: profilesKey),
           let decoded = try? JSONDecoder().decode([Profile].self, from: data) {
            profiles = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: currentProfileKey),
           let decoded = try? JSONDecoder().decode(Profile.self, from: data) {
            // Make sure the current profile still exists in the profiles array
            if profiles.contains(where: { $0.id == decoded.id }) {
                currentProfile = decoded
            }
        }
    }
}

// MARK: - Profile Icons and Colors

extension ProfileStore {
    static let availableIcons = [
        "person.fill", "person.circle.fill", "heart.fill", "star.fill",
        "sun.max.fill", "moon.fill", "leaf.fill", "snowflake",
        "flame.fill", "drop.fill", "bolt.fill", "sparkles"
    ]
    
    static let availableColors = [
        "#6BB0DA", // Primary blue
        "#A6C7BA", // Sage green
        "#F2D9BA", // Warm cream
        "#99CCAB", // Success green
        "#F2D19C", // Warning orange
        "#EAB3B3", // Error red
        "#8CAE9F", // Secondary sage
        "#D9BFA0", // Accent cream
        "#5297BF", // Dark blue
        "#E8F5ED", // Light green
        "#FDF6EB", // Light orange
        "#FAF0F0"  // Light red
    ]
}