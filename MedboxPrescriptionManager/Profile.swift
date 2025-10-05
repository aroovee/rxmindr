import Foundation
import SwiftUI
import UIKit

struct Profile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var dateOfBirth: Date
    var profileColor: String // Store as hex string for Codable
    var profileIcon: String // SF Symbol name
    var notes: String
    var emergencyContact: String
    var medicalAllergies: [String]
    let createdDate: Date
    var isDefault: Bool
    
    init(
        name: String,
        dateOfBirth: Date = Date(),
        profileColor: String = "#6BB0DA", // Default to design system primary
        profileIcon: String = "person.fill",
        notes: String = "",
        emergencyContact: String = "",
        medicalAllergies: [String] = [],
        isDefault: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.dateOfBirth = dateOfBirth
        self.profileColor = profileColor
        self.profileIcon = profileIcon
        self.notes = notes
        self.emergencyContact = emergencyContact
        self.medicalAllergies = medicalAllergies
        self.createdDate = Date()
        self.isDefault = isDefault
    }
    
    // Computed property to get SwiftUI Color from hex string
    var color: Color {
        Color(hex: profileColor) ?? DesignSystem.Colors.primary
    }
    
    // Age calculation
    var age: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return ageComponents.year ?? 0
    }
    
    // Display name with age
    var displayName: String {
        "\(name) (\(age))"
    }
    
    // Method to create updated profile preserving ID and creation date
    func updated(
        name: String? = nil,
        dateOfBirth: Date? = nil,
        profileColor: String? = nil,
        profileIcon: String? = nil,
        notes: String? = nil,
        emergencyContact: String? = nil,
        medicalAllergies: [String]? = nil,
        isDefault: Bool? = nil
    ) -> Profile {
        var updatedProfile = self
        if let name = name { updatedProfile.name = name }
        if let dateOfBirth = dateOfBirth { updatedProfile.dateOfBirth = dateOfBirth }
        if let profileColor = profileColor { updatedProfile.profileColor = profileColor }
        if let profileIcon = profileIcon { updatedProfile.profileIcon = profileIcon }
        if let notes = notes { updatedProfile.notes = notes }
        if let emergencyContact = emergencyContact { updatedProfile.emergencyContact = emergencyContact }
        if let medicalAllergies = medicalAllergies { updatedProfile.medicalAllergies = medicalAllergies }
        if let isDefault = isDefault { updatedProfile.isDefault = isDefault }
        return updatedProfile
    }
}

// Extension to create Color from hex string
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}