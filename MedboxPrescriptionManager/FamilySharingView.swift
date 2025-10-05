import SwiftUI

struct FamilySharingView: View {
    @StateObject private var sharingManager = SharingManager.shared
    @StateObject private var profileStore = ProfileStore()
    
    @State private var showingAddContact = false
    @State private var selectedContact: TrustedContact?
    @State private var showingContactDetail = false
    @State private var showingPrivacySettings = false
    @State private var isAnimating = false
    
    private var currentProfileId: UUID {
        profileStore.currentProfile?.id ?? UUID()
    }
    
    private var sharingEnabled: Bool {
        sharingManager.sharingPermissions[currentProfileId]?.isEnabled ?? false
    }
    
    private var trustedContacts: [TrustedContact] {
        sharingManager.getTrustedContacts(for: currentProfileId)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern background with subtle gradient
                DesignSystem.Gradients.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: DesignSystem.Spacing.xl) {
                        // Hero section with modern card
                        heroSection
                        
                        // Sharing toggle with glassmorphism
                        modernSharingToggle
                        
                        if sharingEnabled {
                            // Trusted contacts with modern cards
                            modernTrustedContactsSection
                            
                            // Privacy settings card
                            modernPrivacySection
                            
                            // Information cards
                            modernInformationSection
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.bottom, DesignSystem.Spacing.xxxl)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddContact) {
                AddTrustedContactView(profileId: currentProfileId)
            }
            .sheet(item: $selectedContact) { contact in
                EditTrustedContactView(contact: contact, profileId: currentProfileId)
            }
            .sheet(isPresented: $showingPrivacySettings) {
                PrivacySettingsView(profileId: currentProfileId)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8)) {
                    isAnimating = true
                }
            }
        }
    }
    
    // MARK: - Modern UI Components
    
    private var heroSection: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Header with back button and title
            HStack {
                Button("Back") {
                    // Handle back navigation
                }
                .font(DesignSystem.Typography.bodyLarge(weight: .medium))
                .foregroundColor(DesignSystem.Colors.primary)
                
                Spacer()
                
                Text("Family Sharing")
                    .font(DesignSystem.Typography.navigationTitle())
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                // Spacer for layout balance
                Button("") { }
                    .opacity(0)
                    .disabled(true)
            }
            .padding(.top, DesignSystem.Spacing.xl)
            
            // Sharing illustration card
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(DesignSystem.Gradients.primaryGradient)
                        .frame(width: 80, height: 80)
                        .shadow(
                            color: DesignSystem.Colors.primary.opacity(0.3),
                            radius: 12,
                            x: 0,
                            y: 8
                        )
                    
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: DesignSystem.Spacing.md) {
                    Text("Keep Your Loved Ones Informed")
                        .font(DesignSystem.Typography.titleLarge(weight: .bold, family: .avenir))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Share medication progress with trusted contacts.")
                        .font(DesignSystem.Typography.bodyMedium(weight: .medium, family: .sfPro))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
            }
            .padding(DesignSystem.Spacing.xl)
            .glassCard()
            .scaleEffect(isAnimating ? 1.0 : 0.9)
            .opacity(isAnimating ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.6).delay(0.2), value: isAnimating)
        }
    }
    
    private var modernSharingToggle: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("Enable Family Sharing")
                        .font(DesignSystem.Typography.headingLarge(weight: .bold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(sharingEnabled ? 
                         "Your trusted contacts are receiving medication updates" : 
                         "Allow family and friends to help support your routine")
                        .font(DesignSystem.Typography.bodyMedium(weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Modern toggle with glow effect
                ZStack {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(sharingEnabled ? DesignSystem.Gradients.primaryGradient : DesignSystem.Gradients.glassGradient)
                        .frame(width: 60, height: 34)
                        .shadow(
                            color: sharingEnabled ? DesignSystem.Colors.primary.opacity(0.4) : Color.clear,
                            radius: sharingEnabled ? 8 : 0,
                            x: 0,
                            y: 4
                        )
                    
                    Circle()
                        .fill(.white)
                        .frame(width: 28, height: 28)
                        .offset(x: sharingEnabled ? 13 : -13)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: sharingEnabled)
                }
                .onTapGesture {
                    withAnimation(.spring()) {
                        if sharingEnabled {
                            sharingManager.disableSharing(for: currentProfileId)
                        } else {
                            sharingManager.enableSharing(for: currentProfileId)
                        }
                    }
                }
            }
            
            // Status indicator
            HStack(spacing: DesignSystem.Spacing.sm) {
                Circle()
                    .fill(sharingEnabled ? DesignSystem.Colors.success : DesignSystem.Colors.neutral300)
                    .frame(width: 8, height: 8)
                
                Text(sharingEnabled ? "Active" : "Disabled")
                    .font(DesignSystem.Typography.captionLarge(weight: .semibold))
                    .foregroundColor(sharingEnabled ? DesignSystem.Colors.success : DesignSystem.Colors.textTertiary)
                
                Spacer()
                
                if sharingEnabled && !trustedContacts.isEmpty {
                    Text("\(trustedContacts.count) contact\(trustedContacts.count == 1 ? "" : "s")")
                        .font(DesignSystem.Typography.captionLarge(weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .modernCard(elevation: .soft)
        .scaleEffect(isAnimating ? 1.0 : 0.9)
        .opacity(isAnimating ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.6).delay(0.4), value: isAnimating)
    }
    
    private var modernTrustedContactsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack {
                Text("Trusted Contacts")
                    .font(DesignSystem.Typography.headingLarge(weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                if !trustedContacts.isEmpty {
                    Text("\(trustedContacts.count)")
                        .font(DesignSystem.Typography.bodyMedium(weight: .bold))
                        .foregroundColor(DesignSystem.Colors.primary)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(
                            Circle()
                                .fill(DesignSystem.Colors.primaryLight)
                        )
                }
            }
            
            if trustedContacts.isEmpty {
                emptyContactsState
            } else {
                LazyVStack(spacing: DesignSystem.Spacing.md) {
                    ForEach(Array(trustedContacts.enumerated()), id: \.element.id) { index, contact in
                        ModernTrustedContactCard(contact: contact) {
                            selectedContact = contact
                            showingContactDetail = true
                        }
                        .scaleEffect(isAnimating ? 1.0 : 0.9)
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.1 + 0.6), value: isAnimating)
                    }
                }
            }
            
            // Add contact button
            Button(action: { showingAddContact = true }) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Gradients.primaryGradient)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Add Trusted Contact")
                        .font(DesignSystem.Typography.bodyLarge(weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.primary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
                .padding(DesignSystem.Spacing.lg)
                .modernCard(elevation: .minimal)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var emptyContactsState: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.neutral200)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("No Trusted Contacts")
                    .font(DesignSystem.Typography.headingMedium(weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Add family members and friends to keep them informed about your medication progress.")
                    .font(DesignSystem.Typography.bodyMedium(weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .frame(maxWidth: .infinity)
        .glassCard()
    }
    
    private var modernPrivacySection: some View {
        Button(action: { showingPrivacySettings = true }) {
            HStack(spacing: DesignSystem.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.secondary.opacity(0.2))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.secondary)
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Privacy Settings")
                        .font(DesignSystem.Typography.bodyLarge(weight: .bold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("Control what information is shared")
                        .font(DesignSystem.Typography.bodyMedium(weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.lg)
            .modernCard(elevation: .minimal)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var modernInformationSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            Text("How It Works")
                .font(DesignSystem.Typography.headingLarge(weight: .bold))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            VStack(spacing: DesignSystem.Spacing.md) {
                ModernInfoCard(
                    icon: "clock.badge.checkmark",
                    title: "Daily Summaries",
                    description: "Trusted contacts receive daily updates about medication adherence",
                    color: DesignSystem.Colors.primary
                )
                
                ModernInfoCard(
                    icon: "exclamationmark.triangle",
                    title: "Missed Medication Alerts",
                    description: "Contacts with detailed access get notified when medications are missed",
                    color: DesignSystem.Colors.warning
                )
                
                ModernInfoCard(
                    icon: "sos",
                    title: "Emergency Alerts",
                    description: "Emergency contacts receive critical alerts for serious adherence issues",
                    color: DesignSystem.Colors.error
                )
            }
        }
    }
    
    private func deleteContacts(offsets: IndexSet) {
        for index in offsets {
            let contact = trustedContacts[index]
            sharingManager.removeTrustedContact(contact.id, from: currentProfileId)
        }
    }
}

struct TrustedContactRow: View {
    let contact: TrustedContact
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(contact.relationship)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        accessLevelBadge
                        
                        if !contact.isActive {
                            Text("Inactive")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.2))
                                .foregroundColor(.secondary)
                                .clipShape(Capsule())
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var accessLevelBadge: some View {
        Text(contact.accessLevel.displayName)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(backgroundColorForAccessLevel)
            .foregroundColor(.white)
            .clipShape(Capsule())
    }
    
    private var backgroundColorForAccessLevel: Color {
        switch contact.accessLevel {
        case .basic:
            return DesignSystem.Colors.primary
        case .detailed:
            return DesignSystem.Colors.secondary
        case .emergency:
            return DesignSystem.Colors.error
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(DesignSystem.Colors.primary)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Supporting Modern Components

struct ModernTrustedContactCard: View {
    let contact: TrustedContact
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.lg) {
                // Avatar with initial or icon
                ZStack {
                    Circle()
                        .fill(colorForAccessLevel)
                        .frame(width: 52, height: 52)
                        .shadow(
                            color: colorForAccessLevel.opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    
                    Text(String(contact.name.prefix(1).uppercased()))
                        .font(DesignSystem.Typography.headingMedium(weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    HStack {
                        Text(contact.name)
                            .font(DesignSystem.Typography.bodyLarge(weight: .bold))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Spacer()
                        
                        if !contact.isActive {
                            Text("Inactive")
                                .font(DesignSystem.Typography.captionSmall(weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                                .padding(.horizontal, DesignSystem.Spacing.sm)
                                .padding(.vertical, DesignSystem.Spacing.xs)
                                .background(
                                    Capsule()
                                        .fill(DesignSystem.Colors.neutral200)
                                )
                        }
                    }
                    
                    Text(contact.relationship)
                        .font(DesignSystem.Typography.bodyMedium(weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        AccessLevelBadge(level: contact.accessLevel)
                        
                        Spacer()
                        
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            if let lastNotified = contact.lastNotified {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(DesignSystem.Colors.success)
                                
                                Text("Last notified \(RelativeDateTimeFormatter().localizedString(for: lastNotified, relativeTo: Date()))")
                                    .font(DesignSystem.Typography.captionSmall(weight: .medium))
                                    .foregroundColor(DesignSystem.Colors.textTertiary)
                            } else {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                    .foregroundColor(DesignSystem.Colors.textTertiary)
                                
                                Text("Never notified")
                                    .font(DesignSystem.Typography.captionSmall(weight: .medium))
                                    .foregroundColor(DesignSystem.Colors.textTertiary)
                            }
                        }
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.lg)
            .modernCard(elevation: .minimal)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var colorForAccessLevel: Color {
        switch contact.accessLevel {
        case .basic:
            return DesignSystem.Colors.primary
        case .detailed:
            return DesignSystem.Colors.secondary
        case .emergency:
            return DesignSystem.Colors.error
        }
    }
}

struct AccessLevelBadge: View {
    let level: TrustedContact.AccessLevel
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Circle()
                .fill(colorForLevel)
                .frame(width: 6, height: 6)
            
            Text(level.displayName)
                .font(DesignSystem.Typography.captionSmall(weight: .semibold))
                .foregroundColor(colorForLevel)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            Capsule()
                .fill(colorForLevel.opacity(0.15))
        )
    }
    
    private var colorForLevel: Color {
        switch level {
        case .basic:
            return DesignSystem.Colors.primary
        case .detailed:
            return DesignSystem.Colors.secondary
        case .emergency:
            return DesignSystem.Colors.error
        }
    }
}

struct ModernInfoCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(title)
                    .font(DesignSystem.Typography.bodyLarge(weight: .bold))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(description)
                    .font(DesignSystem.Typography.bodyMedium(weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.lg)
        .modernCard(elevation: .minimal)
    }
}

#Preview {
    FamilySharingView()
}