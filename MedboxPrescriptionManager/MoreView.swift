import SwiftUI

struct MoreView: View {
    @ObservedObject var profileStore: ProfileStore
    @State private var showingProfiles = false
    @State private var showingSettings = false
    @State private var showingHealthData = false
    @State private var showingFamilySharing = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                DesignSystem.Gradients.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Current Profile Card
                        if let currentProfile = profileStore.currentProfile {
                            CurrentProfileSummaryCard(
                                profile: currentProfile,
                                onSwitchProfile: {
                                    showingProfiles = true
                                }
                            )
                        }
                        
                        // Quick Actions
                        QuickActionsSection(
                            onShowProfiles: {
                                showingProfiles = true
                            },
                            onShowSettings: {
                                showingSettings = true
                            },
                            onShowHealthData: {
                                showingHealthData = true
                            },
                            onShowFamilySharing: {
                                showingFamilySharing = true
                            }
                        )
                        
                        // App Information
                        AppInfoSection()
                    }
                    .padding()
                }
            }
            .navigationTitle("More")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingProfiles) {
                ProfilesView()
                    .environmentObject(profileStore)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingHealthData) {
                HealthKitView()
            }
            .sheet(isPresented: $showingFamilySharing) {
                FamilySharingView()
            }
        }
    }
}

struct CurrentProfileSummaryCard: View {
    let profile: Profile
    let onSwitchProfile: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Active Profile")
                    .font(DesignSystem.Typography.titleMedium(weight: .semibold, family: .avenir))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
                
                Button("Switch", action: onSwitchProfile)
                    .font(DesignSystem.Typography.buttonText())
                    .foregroundColor(DesignSystem.Colors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(DesignSystem.Colors.primaryLight)
                    )
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
                    HStack {
                        Text(profile.name)
                            .font(DesignSystem.Typography.headingLarge(weight: .semibold, family: .avenir))
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        if profile.isDefault {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundColor(DesignSystem.Colors.warning)
                        }
                    }
                    
                    if profile.age > 0 {
                        Text("\(profile.age) years old")
                            .font(DesignSystem.Typography.bodyMedium(weight: .regular, family: .sfPro))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    if !profile.notes.isEmpty {
                        Text(profile.notes)
                            .font(DesignSystem.Typography.bodySmall(weight: .regular, family: .sfPro))
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct QuickActionsSection: View {
    let onShowProfiles: () -> Void
    let onShowSettings: () -> Void
    let onShowHealthData: () -> Void
    let onShowFamilySharing: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(DesignSystem.Typography.titleMedium(weight: .semibold, family: .avenir))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                MoreActionRow(
                    icon: "person.3.fill",
                    title: "Manage Profiles",
                    subtitle: "Add, edit, or switch between different people",
                    color: DesignSystem.Colors.primary,
                    action: onShowProfiles
                )
                
                MoreActionRow(
                    icon: "gear.circle.fill",
                    title: "App Settings",
                    subtitle: "Notifications, privacy, and app preferences",
                    color: DesignSystem.Colors.secondary,
                    action: onShowSettings
                )
                
                MoreActionRow(
                    icon: "heart.circle.fill",
                    title: "Health Data",
                    subtitle: "View your medication adherence trends",
                    color: DesignSystem.Colors.success,
                    action: onShowHealthData
                )
                
                MoreActionRow(
                    icon: "person.2.circle.fill",
                    title: "Family Sharing",
                    subtitle: "Share medication progress with trusted contacts",
                    color: Color.purple,
                    action: onShowFamilySharing
                )
                
                MoreActionRow(
                    icon: "bell.circle.fill",
                    title: "Reminders",
                    subtitle: "Manage medication reminder settings",
                    color: DesignSystem.Colors.warning,
                    action: {
                        // Could navigate to reminders settings
                    }
                )
            }
        }
    }
}

struct MoreActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(color)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(DesignSystem.Typography.headingSmall(weight: .semibold, family: .sfPro))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(subtitle)
                        .font(DesignSystem.Typography.bodySmall(weight: .regular, family: .sfPro))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
    }
}

struct AppInfoSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("App Information")
                .font(DesignSystem.Typography.titleMedium(weight: .semibold, family: .avenir))
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                AppInfoRow(title: "Version", value: "1.0.0")
                AppInfoRow(title: "Build", value: "100")
                AppInfoRow(title: "Last Updated", value: "Today")
            }
            .padding(20)
            .cardStyle()
        }
    }
}

struct AppInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(DesignSystem.Typography.bodyMedium(weight: .regular, family: .sfPro))
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(DesignSystem.Typography.bodyMedium(weight: .medium, family: .sfPro))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
    }
}

// Preview
struct MoreView_Previews: PreviewProvider {
    static var previews: some View {
        MoreView(profileStore: ProfileStore())
    }
}