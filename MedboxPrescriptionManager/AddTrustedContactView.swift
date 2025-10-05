import SwiftUI

struct AddTrustedContactView: View {
    let profileId: UUID
    @Environment(\.dismiss) private var dismiss
    @StateObject private var sharingManager = SharingManager.shared
    
    @State private var name = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var relationship = "Family"
    @State private var accessLevel: TrustedContact.AccessLevel = .basic
    @State private var notificationPreferences = TrustedContact.NotificationPreferences()
    
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    private let relationships = ["Family", "Friend", "Caregiver", "Healthcare Provider", "Spouse", "Partner", "Child", "Parent", "Sibling", "Other"]
    
    var body: some View {
        NavigationView {
            Form {
                contactInfoSection
                accessLevelSection
                notificationSection
            }
            .navigationTitle("Add Trusted Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addContact()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert("Invalid Information", isPresented: $showingValidationAlert) {
                Button("OK") { }
            } message: {
                Text(validationMessage)
            }
        }
    }
    
    private var contactInfoSection: some View {
        Section(header: Text("Contact Information")) {
            TextField("Full Name", text: $name)
                .textContentType(.name)
            
            TextField("Email Address", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            TextField("Phone Number (Optional)", text: $phoneNumber)
                .textContentType(.telephoneNumber)
                .keyboardType(.phonePad)
            
            Picker("Relationship", selection: $relationship) {
                ForEach(relationships, id: \.self) { relationship in
                    Text(relationship).tag(relationship)
                }
            }
        }
    }
    
    private var accessLevelSection: some View {
        Section(
            header: Text("Access Level"),
            footer: Text("Choose what information this contact can see about your medication routine.")
        ) {
            ForEach(TrustedContact.AccessLevel.allCases, id: \.self) { level in
                AccessLevelRow(
                    level: level,
                    isSelected: accessLevel == level
                ) {
                    accessLevel = level
                }
            }
        }
    }
    
    private var notificationSection: some View {
        Section(
            header: Text("Notification Preferences"),
            footer: Text("Configure how and when this contact should be notified about your medication progress.")
        ) {
            Toggle("Daily Summaries", isOn: $notificationPreferences.enableDailySummary)
            
            if accessLevel == .detailed || accessLevel == .emergency {
                Toggle("Missed Medication Alerts", isOn: $notificationPreferences.enableMissedMedicationAlerts)
            }
            
            Toggle("Weekly Summaries", isOn: $notificationPreferences.enableWeeklySummary)
            
            if accessLevel == .emergency {
                Toggle("Emergency Alerts", isOn: $notificationPreferences.enableEmergencyAlerts)
            }
            
            Picker("Preferred Contact Method", selection: $notificationPreferences.preferredContactMethod) {
                ForEach(TrustedContact.NotificationPreferences.ContactMethod.allCases, id: \.self) { method in
                    Text(method.displayName).tag(method)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isValidEmail(email) &&
        !relationship.isEmpty
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    private func addContact() {
        // Validate form
        guard isFormValid else {
            validationMessage = "Please fill in all required fields with valid information."
            showingValidationAlert = true
            return
        }
        
        // Create contact
        let contact = TrustedContact(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
            relationship: relationship,
            accessLevel: accessLevel,
            notificationPreferences: notificationPreferences
        )
        
        // Add to sharing manager
        sharingManager.addTrustedContact(contact, to: profileId)
        
        dismiss()
    }
}

struct AccessLevelRow: View {
    let level: TrustedContact.AccessLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(level.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.vertical, 4)
    }
}

#Preview {
    AddTrustedContactView(profileId: UUID())
}