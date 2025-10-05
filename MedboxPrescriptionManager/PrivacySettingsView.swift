import SwiftUI

struct PrivacySettingsView: View {
    let profileId: UUID
    @Environment(\.dismiss) private var dismiss
    @StateObject private var sharingManager = SharingManager.shared
    
    @State private var privacySettings: SharingPermission.PrivacySettings
    
    init(profileId: UUID) {
        self.profileId = profileId
        let currentSettings = SharingManager.shared.sharingPermissions[profileId]?.privacySettings ?? SharingPermission.PrivacySettings()
        _privacySettings = State(initialValue: currentSettings)
    }
    
    var body: some View {
        NavigationView {
            Form {
                informationSharingSection
                explanationSection
            }
            .navigationTitle("Privacy Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                    }
                }
            }
        }
    }
    
    private var informationSharingSection: some View {
        Section {
            PrivacyToggle(
                title: "Medication Names",
                description: "Share specific names of medications",
                isOn: $privacySettings.shareMedicationNames,
                icon: "pills.fill"
            )
            
            PrivacyToggle(
                title: "Dosage Information",
                description: "Include dosage amounts in updates",
                isOn: $privacySettings.shareDosageInformation,
                icon: "number.circle.fill"
            )
            .disabled(!privacySettings.shareMedicationNames)
            
            PrivacyToggle(
                title: "Timing Information",
                description: "Share scheduled and actual medication times",
                isOn: $privacySettings.shareTimingInformation,
                icon: "clock.fill"
            )
            
            PrivacyToggle(
                title: "Adherence Statistics",
                description: "Share overall medication adherence rates",
                isOn: $privacySettings.shareAdherenceStats,
                icon: "chart.line.uptrend.xyaxis"
            )
            
            PrivacyToggle(
                title: "Physician Information",
                description: "Share prescribing physician details",
                isOn: $privacySettings.sharePhysicianInfo,
                icon: "stethoscope"
            )
        } header: {
            Text("Information Sharing")
        } footer: {
            Text("Choose what information to include when sharing medication progress with trusted contacts.")
        }
    }
    
    private var explanationSection: some View {
        Section {
            PrivacyLevelInfo(
                level: "Minimum Privacy",
                description: "Only adherence statistics are shared. No medication names or specific details.",
                isCurrentLevel: isMinimumPrivacy
            )
            
            PrivacyLevelInfo(
                level: "Standard Privacy",
                description: "Medication names, timing, and adherence statistics are shared.",
                isCurrentLevel: isStandardPrivacy
            )
            
            PrivacyLevelInfo(
                level: "Full Transparency",
                description: "All available information including dosages and physician details are shared.",
                isCurrentLevel: isFullTransparency
            )
        } header: {
            Text("Privacy Levels")
        } footer: {
            Text("Your current privacy settings determine how much information your trusted contacts can see. You can adjust these settings at any time.")
        }
    }
    
    private var isMinimumPrivacy: Bool {
        !privacySettings.shareMedicationNames &&
        !privacySettings.shareDosageInformation &&
        !privacySettings.shareTimingInformation &&
        privacySettings.shareAdherenceStats &&
        !privacySettings.sharePhysicianInfo
    }
    
    private var isStandardPrivacy: Bool {
        privacySettings.shareMedicationNames &&
        !privacySettings.shareDosageInformation &&
        privacySettings.shareTimingInformation &&
        privacySettings.shareAdherenceStats &&
        !privacySettings.sharePhysicianInfo
    }
    
    private var isFullTransparency: Bool {
        privacySettings.shareMedicationNames &&
        privacySettings.shareDosageInformation &&
        privacySettings.shareTimingInformation &&
        privacySettings.shareAdherenceStats &&
        privacySettings.sharePhysicianInfo
    }
    
    private func saveSettings() {
        sharingManager.updatePrivacySettings(privacySettings, for: profileId)
        dismiss()
    }
}

struct PrivacyToggle: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isOn ? DesignSystem.Colors.primary : .secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .onChange(of: isOn) { newValue in
                    if !newValue && title == "Medication Names" {
                        // If medication names are turned off, also turn off dosage info
                        // This will be handled by the parent view's disabled state
                    }
                }
        }
        .padding(.vertical, 4)
    }
}

struct PrivacyLevelInfo: View {
    let level: String
    let description: String
    let isCurrentLevel: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(level)
                    .font(.headline)
                    .foregroundColor(isCurrentLevel ? DesignSystem.Colors.primary : .primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            if isCurrentLevel {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DesignSystem.Colors.success)
            }
        }
        .padding(.vertical, 4)
        .background(
            isCurrentLevel ? DesignSystem.Colors.primary.opacity(0.1) : Color.clear
        )
        .cornerRadius(8)
    }
}

#Preview {
    PrivacySettingsView(profileId: UUID())
}