import SwiftUI

struct ProfilesView: View {
    @EnvironmentObject var profileStore: ProfileStore
    @State private var showingAddProfile = false
    @State private var selectedProfile: Profile?
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                DesignSystem.Gradients.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Header Card
                        ProfilesHeaderCard()
                        
                        // Current Profile Card
                        if let currentProfile = profileStore.currentProfile {
                            CurrentProfileCard(
                                profile: currentProfile,
                                onEditProfile: {
                                    selectedProfile = currentProfile
                                    showingEditProfile = true
                                }
                            )
                        }
                        
                        // Other Profiles Section
                        if !profileStore.nonCurrentProfiles.isEmpty {
                            OtherProfilesSection(
                                profiles: profileStore.nonCurrentProfiles,
                                onSelectProfile: { profile in
                                    profileStore.switchToProfile(profile)
                                },
                                onEditProfile: { profile in
                                    selectedProfile = profile
                                    showingEditProfile = true
                                },
                                onDeleteProfile: { profile in
                                    profileStore.deleteProfile(profile)
                                }
                            )
                        }
                        
                        // Add New Profile Button
                        AddProfileButton {
                            showingAddProfile = true
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Profiles")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddProfile = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddProfile) {
                AddEditProfileView(profileStore: profileStore)
            }
            .sheet(isPresented: $showingEditProfile) {
                if let profile = selectedProfile {
                    AddEditProfileView(profileStore: profileStore, editingProfile: profile)
                }
            }
        }
    }
}

struct ProfilesHeaderCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(DesignSystem.Gradients.primaryGradient.opacity(0.3))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.primary)
                )
            
            VStack(spacing: 8) {
                Text("Manage Profiles")
                    .font(DesignSystem.Typography.displaySmall(weight: .bold, family: .avenir))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Create and manage profiles for different family members or individuals")
                    .font(DesignSystem.Typography.bodyMedium(weight: .regular, family: .sfPro))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .cardStyle()
    }
}

struct CurrentProfileCard: View {
    let profile: Profile
    let onEditProfile: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Active Profile")
                    .font(DesignSystem.Typography.headingMedium(weight: .semibold, family: .avenir))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                if profile.isDefault {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.Colors.warning)
                        Text("Default")
                            .font(DesignSystem.Typography.captionLarge(weight: .medium))
                            .foregroundColor(DesignSystem.Colors.warning)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(DesignSystem.Colors.warningLight)
                    )
                }
            }
            
            HStack(spacing: 16) {
                // Profile Icon
                Circle()
                    .fill(profile.color.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: profile.profileIcon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(profile.color)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(DesignSystem.Typography.headingMedium(weight: .semibold, family: .avenir))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    if profile.age > 0 {
                        Text("\(profile.age) years old")
                            .font(DesignSystem.Typography.bodyMedium(weight: .regular, family: .sfPro))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    if !profile.notes.isEmpty {
                        Text(profile.notes)
                            .font(DesignSystem.Typography.captionLarge(weight: .regular))
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Button(action: onEditProfile) {
                    Circle()
                        .fill(DesignSystem.Colors.neutral200)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "pencil")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        )
                }
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct OtherProfilesSection: View {
    let profiles: [Profile]
    let onSelectProfile: (Profile) -> Void
    let onEditProfile: (Profile) -> Void
    let onDeleteProfile: (Profile) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Other Profiles")
                .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .padding(.horizontal, 4)
            
            LazyVStack(spacing: 12) {
                ForEach(profiles) { profile in
                    ProfileRowView(
                        profile: profile,
                        onSelect: { onSelectProfile(profile) },
                        onEdit: { onEditProfile(profile) },
                        onDelete: { onDeleteProfile(profile) }
                    )
                }
            }
        }
    }
}

struct ProfileRowView: View {
    let profile: Profile
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Profile Icon
                Circle()
                    .fill(profile.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: profile.profileIcon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(profile.color)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(profile.name)
                            .font(DesignSystem.Typography.bodyMedium(weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        if profile.isDefault {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(DesignSystem.Colors.warning)
                        }
                    }
                    
                    if profile.age > 0 {
                        Text("\(profile.age) years old")
                            .font(DesignSystem.Typography.captionLarge(weight: .regular))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            .padding(16)
            .cardStyle()
        }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing) {
            Button("Delete", systemImage: "trash", role: .destructive) {
                showingDeleteConfirmation = true
            }
            .tint(.red)
            
            Button("Edit", systemImage: "pencil") {
                onEdit()
            }
            .tint(DesignSystem.Colors.primary)
        }
        .alert("Delete Profile", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete \(profile.name)'s profile? This action cannot be undone.")
        }
    }
}

struct AddProfileButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(DesignSystem.Colors.primaryLight)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(DesignSystem.Colors.primary)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add New Profile")
                        .font(DesignSystem.Typography.bodyMedium(weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                    
                    Text("Create a profile for another person")
                        .font(DesignSystem.Typography.captionLarge(weight: .regular))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                    .fill(DesignSystem.Colors.primaryLight.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .strokeBorder(DesignSystem.Colors.primary.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Add/Edit Profile View

struct AddEditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var profileStore: ProfileStore
    
    let editingProfile: Profile?
    @State private var name: String
    @State private var dateOfBirth: Date
    @State private var selectedColor: String
    @State private var selectedIcon: String
    @State private var notes: String
    @State private var emergencyContact: String
    @State private var isDefault: Bool
    
    init(profileStore: ProfileStore, editingProfile: Profile? = nil) {
        self.profileStore = profileStore
        self.editingProfile = editingProfile
        
        _name = State(initialValue: editingProfile?.name ?? "")
        _dateOfBirth = State(initialValue: editingProfile?.dateOfBirth ?? Date())
        _selectedColor = State(initialValue: editingProfile?.profileColor ?? ProfileStore.availableColors.first ?? "#6BB0DA")
        _selectedIcon = State(initialValue: editingProfile?.profileIcon ?? "person.fill")
        _notes = State(initialValue: editingProfile?.notes ?? "")
        _emergencyContact = State(initialValue: editingProfile?.emergencyContact ?? "")
        _isDefault = State(initialValue: editingProfile?.isDefault ?? false)
    }
    
    private var isEditing: Bool {
        editingProfile != nil
    }
    
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Gradients.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Profile Preview
                        ProfilePreviewCard(
                            name: name,
                            dateOfBirth: dateOfBirth,
                            color: Color(hex: selectedColor) ?? DesignSystem.Colors.primary,
                            icon: selectedIcon
                        )
                        
                        // Basic Information
                        ProfileFormSection(title: "Basic Information") {
                            VStack(spacing: 16) {
                                FormField(title: "Name") {
                                    TextField("Enter name", text: $name)
                                        .font(DesignSystem.Typography.bodyMedium(weight: .regular, family: .sfPro))
                                        .padding()
                                        .background(DesignSystem.Colors.neutral100)
                                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                                }
                                
                                FormField(title: "Date of Birth") {
                                    DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                                        .datePickerStyle(.compact)
                                        .labelsHidden()
                                }
                                
                                FormField(title: "Notes (Optional)") {
                                    TextField("Any additional notes", text: $notes, axis: .vertical)
                                        .font(DesignSystem.Typography.bodyMedium(weight: .regular, family: .sfPro))
                                        .lineLimit(3...6)
                                        .padding()
                                        .background(DesignSystem.Colors.neutral100)
                                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                                }
                            }
                        }
                        
                        // Appearance
                        ProfileFormSection(title: "Appearance") {
                            VStack(spacing: 16) {
                                FormField(title: "Profile Color") {
                                    ColorSelectionGrid(selectedColor: $selectedColor)
                                }
                                
                                FormField(title: "Profile Icon") {
                                    IconSelectionGrid(selectedIcon: $selectedIcon, color: Color(hex: selectedColor) ?? DesignSystem.Colors.primary)
                                }
                            }
                        }
                        
                        // Settings
                        if profileStore.profiles.count > 1 || isEditing {
                            ProfileFormSection(title: "Settings") {
                                Toggle("Set as Default Profile", isOn: $isDefault)
                                    .font(DesignSystem.Typography.bodyMedium(weight: .medium))
                                    .foregroundColor(DesignSystem.Colors.textPrimary)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(isEditing ? "Edit Profile" : "New Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                    .disabled(!canSave)
                }
            }
        }
    }
    
    private func saveProfile() {
        let profile = Profile(
            name: name,
            dateOfBirth: dateOfBirth,
            profileColor: selectedColor,
            profileIcon: selectedIcon,
            notes: notes,
            emergencyContact: emergencyContact,
            isDefault: isDefault
        )
        
        if let editingProfile = editingProfile {
            var updatedProfile = profile
            updatedProfile = Profile(
                name: name,
                dateOfBirth: dateOfBirth,
                profileColor: selectedColor,
                profileIcon: selectedIcon,
                notes: notes,
                emergencyContact: emergencyContact,
                isDefault: isDefault
            )
            // Preserve the original ID and creation date
            let finalProfile = Profile(
                name: name,
                dateOfBirth: dateOfBirth,
                profileColor: selectedColor,
                profileIcon: selectedIcon,
                notes: notes,
                emergencyContact: emergencyContact,
                isDefault: isDefault
            )
            profileStore.updateProfile(finalProfile)
        } else {
            profileStore.addProfile(profile)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Supporting Views

struct ProfilePreviewCard: View {
    let name: String
    let dateOfBirth: Date
    let color: Color
    let icon: String
    
    private var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(color)
                )
            
            VStack(spacing: 4) {
                Text(name.isEmpty ? "Profile Name" : name)
                    .font(DesignSystem.Typography.headingMedium(weight: .semibold, family: .avenir))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                if age > 0 {
                    Text("\(age) years old")
                        .font(DesignSystem.Typography.bodyMedium(weight: .regular, family: .sfPro))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .cardStyle()
    }
}

struct ProfileFormSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(DesignSystem.Typography.headingMedium(weight: .semibold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 16) {
                content
            }
            .padding(20)
            .cardStyle()
        }
    }
}

struct FormField<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(DesignSystem.Typography.bodyMedium(weight: .medium))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            content
        }
    }
}

struct ColorSelectionGrid: View {
    @Binding var selectedColor: String
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            ForEach(ProfileStore.availableColors, id: \.self) { colorHex in
                Button(action: {
                    selectedColor = colorHex
                }) {
                    Circle()
                        .fill(Color(hex: colorHex) ?? DesignSystem.Colors.primary)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    selectedColor == colorHex ? Color.white : Color.clear,
                                    lineWidth: 3
                                )
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    selectedColor == colorHex ? DesignSystem.Colors.textPrimary : Color.clear,
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct IconSelectionGrid: View {
    @Binding var selectedIcon: String
    let color: Color
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
            ForEach(ProfileStore.availableIcons, id: \.self) { icon in
                Button(action: {
                    selectedIcon = icon
                }) {
                    Circle()
                        .fill(selectedIcon == icon ? color.opacity(0.2) : DesignSystem.Colors.neutral100)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(selectedIcon == icon ? color : DesignSystem.Colors.textSecondary)
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    selectedIcon == icon ? color : Color.clear,
                                    lineWidth: 2
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// Preview
struct ProfilesView_Previews: PreviewProvider {
    static var previews: some View {
        ProfilesView()
            .environmentObject(ProfileStore())
    }
}
