import SwiftUI

struct EditTrustedContactView: View {
    let contact: TrustedContact
    let profileId: UUID
    @Environment(\.dismiss) private var dismiss
    @StateObject private var sharingManager = SharingManager.shared
    
    @State private var name: String
    @State private var email: String
    @State private var phoneNumber: String
    @State private var relationship: String
    @State private var accessLevel: TrustedContact.AccessLevel
    @State private var notificationPreferences: TrustedContact.NotificationPreferences
    @State private var isActive: Bool
    
    @State private var showingDeleteConfirmation = false
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    private let relationships = ["Family", "Friend", "Caregiver", "Healthcare Provider", "Spouse", "Partner", "Child", "Parent", "Sibling", "Other"]
    
    init(contact: TrustedContact, profileId: UUID) {
        self.contact = contact
        self.profileId = profileId
        
        _name = State(initialValue: contact.name)
        _email = State(initialValue: contact.email)
        _phoneNumber = State(initialValue: contact.phoneNumber ?? "")
        _relationship = State(initialValue: contact.relationship)
        _accessLevel = State(initialValue: contact.accessLevel)
        _notificationPreferences = State(initialValue: contact.notificationPreferences)
        _isActive = State(initialValue: contact.isActive)
    }
    
    var body: some View {
        NavigationView {
            Form {
                contactInfoSection
                accessLevelSection
                notificationSection
                statusSection
                activitySection
            }
            .navigationTitle("Edit Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert("Invalid Information", isPresented: $showingValidationAlert) {
                Button("OK") { }
            } message: {
                Text(validationMessage)
            }
            .confirmationDialog("Remove Contact", isPresented: $showingDeleteConfirmation) {
                Button("Remove Contact", role: .destructive) {
                    deleteContact()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Remove \(contact.name) from trusted contacts?")
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
            footer: Text("Choose access level for this contact.")
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
        Section(header: Text("Notification Preferences")) {
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
    
    private var statusSection: some View {
        Section(
            header: Text("Status"),
            footer: Text(isActive ? "This contact will receive notifications based on their preferences." : "This contact is inactive and will not receive any notifications.")
        ) {
            Toggle("Active Contact", isOn: $isActive)
        }
    }
    
    private var activitySection: some View {
        Section(header: Text("Activity")) {
            HStack {
                Text("Added")
                Spacer()
                Text(DateFormatter.shortDateTime.string(from: contact.dateAdded))
                    .foregroundColor(.secondary)
            }
            
            if let lastNotified = contact.lastNotified {
                HStack {
                    Text("Last Notified")
                    Spacer()
                    Text(DateFormatter.shortDateTime.string(from: lastNotified))
                        .foregroundColor(.secondary)
                }
            }
            
            Button("Remove Contact", role: .destructive) {
                showingDeleteConfirmation = true
            }
            .foregroundColor(DesignSystem.Colors.error)
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
    
    private func saveChanges() {
        guard isFormValid else {
            validationMessage = "Please fill in all required fields with valid information."
            showingValidationAlert = true
            return
        }
        
        var updatedContact = contact
        updatedContact.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedContact.email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        updatedContact.phoneNumber = phoneNumber.isEmpty ? nil : phoneNumber
        updatedContact.relationship = relationship
        updatedContact.accessLevel = accessLevel
        updatedContact.notificationPreferences = notificationPreferences
        updatedContact.isActive = isActive
        
        sharingManager.updateTrustedContact(updatedContact, for: profileId)
        dismiss()
    }
    
    private func deleteContact() {
        sharingManager.removeTrustedContact(contact.id, from: profileId)
        dismiss()
    }
}

extension DateFormatter {
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    EditTrustedContactView(
        contact: TrustedContact(
            name: "Jane Doe",
            email: "jane@example.com",
            relationship: "Family",
            accessLevel: .detailed
        ),
        profileId: UUID()
    )
}