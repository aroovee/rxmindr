import SwiftUI

struct PrescriptionListView: View {
    @ObservedObject var prescriptionStore: PrescriptionStore
    @State private var showingAddPrescription = false
    @State private var showingScanner = false
    @State private var searchText = ""
    @State private var showOverdueOnly = false
    
    // MARK: - Static Constants for Compile Optimization  
    private static let backgroundGradient = DesignSystem.Gradients.backgroundGradient
    
    // MARK: - Computed Properties for Compile Optimization
    private var filteredPrescriptions: [Prescription] {
        let filtered = searchFilteredPrescriptions
        return showOverdueOnly ? overdueFilteredPrescriptions(filtered) : filtered
    }
    
    private var searchFilteredPrescriptions: [Prescription] {
        guard !searchText.isEmpty else { return prescriptionStore.prescriptions }
        return prescriptionStore.prescriptions.filter { prescription in
            prescription.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func overdueFilteredPrescriptions(_ prescriptions: [Prescription]) -> [Prescription] {
        return prescriptions.filter { prescription in
            guard let lastTaken = prescription.lastTaken else { return true }
            let frequency = Calendar.current.dateComponents([.hour], from: lastTaken, to: Date()).hour ?? 0
            return frequency >= 24
        }
    }
    
    private var filterButtonBackground: some View {
        Group {
            if showOverdueOnly {
                Capsule()
                    .fill(DesignSystem.Colors.warning)
            } else {
                Capsule()
                    .fill(DesignSystem.Colors.cardBackground)
            }
        }
        .shadow(color: DesignSystem.Shadows.medium.color, radius: DesignSystem.Shadows.medium.radius, x: DesignSystem.Shadows.medium.x, y: DesignSystem.Shadows.medium.y)
    }
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                Self.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Enhanced Search Bar
                    SearchBarView(searchText: $searchText, showOverdueOnly: $showOverdueOnly)
                    
                    // Interaction Warnings
                    if prescriptionStore.interactionManager.hasActiveInteractions {
                        InteractionWarningsView(interactionManager: prescriptionStore.interactionManager)
                    }
                    
                    // Prescription List or Empty State
                    if filteredPrescriptions.isEmpty {
                        NoResultsView(searchText: searchText, showingOverdueOnly: showOverdueOnly)
                    } else {
                        GeometryReader { geometry in
                            ScrollView(.vertical, showsIndicators: false) {
                                LazyVStack(spacing: 16) {
                                    ForEach(filteredPrescriptions, id: \.id) { prescription in
                                        NavigationLink(
                                            destination: PrescriptionDetailView(
                                                prescriptionStore: prescriptionStore,
                                                prescription: binding(for: prescription)
                                            )
                                        ) {
                                            EnhancedPrescriptionCard(
                                                prescription: prescription,
                                                onMarkAsTaken: { markAsTaken(prescription) },
                                                onMarkAsUntaken: { markAsUntaken(prescription) },
                                                onDelete: { deletePrescription(prescription) },
                                                interactionManager: prescriptionStore.interactionManager
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .swipeActions(edge: .trailing) {
                                            // Delete Action
                                            Button("Delete", systemImage: "trash", role: .destructive) {
                                                deletePrescription(prescription)
                                            }
                                            .tint(.red)
                                            
                                            // Toggle Taken Status Action
                                            if prescription.isTaken {
                                                Button("Mark Not Taken", systemImage: "xmark.circle") {
                                                    markAsUntaken(prescription)
                                                }
                                                .tint(.orange)
                                            } else {
                                                Button("Mark Taken", systemImage: "checkmark.circle") {
                                                    markAsTaken(prescription)
                                                }
                                                .tint(.green)
                                            }
                                        }
                                        .swipeActions(edge: .leading) {
                                            // Quick Actions on leading edge
                                            Button("Remind Me", systemImage: "bell") {
                                                sendQuickReminder(for: prescription)
                                            }
                                            .tint(.blue)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .frame(minHeight: geometry.size.height)
                            }
                            .refreshable {
                                // Refresh action can be added here
                            }
                            .scrollBounceBehavior(.basedOnSize)
                        }
                    }
                    
                    // Floating Filter Button
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.spring()) {
                                    showOverdueOnly.toggle()
                                }
                            }) {
                                HStack(spacing: DesignSystem.Spacing.sm) {
                                    Image(systemName: showOverdueOnly ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    if !showOverdueOnly {
                                        Text("Filter")
                                            .font(DesignSystem.Typography.statusText())
                                    }
                                }
                                .foregroundColor(showOverdueOnly ? .white : DesignSystem.Colors.primary)
                                .padding(.horizontal, DesignSystem.Spacing.lg)
                                .padding(.vertical, DesignSystem.Spacing.md)
                                .background(filterButtonBackground)
                            }
                            .padding(.trailing, DesignSystem.Spacing.xl)
                            .padding(.bottom, DesignSystem.Spacing.huge)
                        }
                    }
                }
            }
            .navigationTitle("Wellness")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: DesignSystem.Spacing.xl) {
                        Button(action: {
                            showingScanner = true
                        }) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.secondary)
                        }
                        
                        Button(action: {
                            showingAddPrescription = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddPrescription) {
                AddPrescriptionView(prescriptionStore: prescriptionStore)
            }
            .sheet(isPresented: $showingScanner) {
                ScanView(prescriptionStore: prescriptionStore)
            }
        }
    }
    
    private func binding(for prescription: Prescription) -> Binding<Prescription> {
        guard let index: Int = prescriptionStore.prescriptions.firstIndex(where: { $0.id == prescription.id }) else {
            fatalError("Prescription not found")
        }
        return $prescriptionStore.prescriptions[index]
    }
    
    private func markAsTaken(_ prescription: Prescription) {
        var updatedPrescription: Prescription = prescription
        updatedPrescription.isTaken = true
        updatedPrescription.lastTaken = Date()
        prescriptionStore.updatePrescription(updatedPrescription)
        
        // Also record in the medication tracker
        prescriptionStore.recordManager.recordMedicationTaken(prescription: prescription)
        
        // Send confirmation notification
        NotificationManager.shared.sendImmediateNotification(
            for: updatedPrescription,
            message: "\(prescription.name) marked as taken ✓"
        )
    }
    
    private func markAsUntaken(_ prescription: Prescription) {
        var updatedPrescription: Prescription = prescription
        updatedPrescription.isTaken = false
        updatedPrescription.lastTaken = nil
        prescriptionStore.updatePrescription(updatedPrescription)
        
        // Record as not taken
        prescriptionStore.recordManager.recordMedicationNotTaken(prescription: prescription)
        
        // Record in HealthKit as skipped
        Task {
            await HealthKitManager.shared.recordMedicationSkipped(prescription: prescription)
        }
        
        // Send confirmation notification
        NotificationManager.shared.sendImmediateNotification(
            for: updatedPrescription,
            message: "\(prescription.name) marked as not taken"
        )
    }
    
    private func sendQuickReminder(for prescription: Prescription) {
        // Send an immediate reminder notification
        NotificationManager.shared.sendImmediateNotification(
            for: prescription,
            message: "Quick reminder: Don't forget to take \(prescription.name)"
        )
    }
    
    private func deletePrescription(_ prescription: Prescription) {
        prescriptionStore.deletePrescription(prescription)
    }
}

// Enhanced UI Components
struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var showOverdueOnly: Bool
    
    // MARK: - Computed Properties for Compile Optimization
    private var searchBarBackground: some View {
        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
            .fill(DesignSystem.Colors.cardBackground)
            .shadow(color: DesignSystem.Shadows.soft.color, radius: DesignSystem.Shadows.soft.radius, x: DesignSystem.Shadows.soft.x, y: DesignSystem.Shadows.soft.y)
    }
    
    private var overdueFilterBackground: some View {
        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
            .fill(DesignSystem.Colors.warningLight)
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .font(DesignSystem.Typography.bodyMedium(weight: .medium, family: .sfPro))
                
                TextField("Find your medications", text: $searchText)
                    .font(DesignSystem.Typography.bodyMedium(weight: .regular, family: .sfPro))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(searchBarBackground)
            
            if showOverdueOnly {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(DesignSystem.Colors.warning)
                        .font(.system(size: 14, weight: .medium))
                    
                    Text("Showing overdue medications only")
                        .font(DesignSystem.Typography.statusText())
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Spacer()
                    
                    Button("Show All") {
                        showOverdueOnly = false
                    }
                    .font(DesignSystem.Typography.statusText())
                    .foregroundColor(DesignSystem.Colors.primary)
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(overdueFilterBackground)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.xl)
        .padding(.vertical, DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.background.opacity(0.8))
    }
}

struct InteractionWarningsView: View {
    @ObservedObject var interactionManager: InteractionManager
    @State private var showingDetails = false
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingDetails.toggle()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 16, weight: .medium))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Medication Interactions Detected")
                            .font(DesignSystem.Typography.cardTitle())
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("\(interactionManager.activeInteractions.count) interaction\(interactionManager.activeInteractions.count == 1 ? "" : "s") found")
                            .font(DesignSystem.Typography.bodySmall(weight: .regular, family: .sfPro))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: showingDetails ? "chevron.up" : "chevron.down")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            if showingDetails {
                VStack(spacing: 8) {
                    ForEach(Array(interactionManager.activeInteractions.enumerated()), id: \.offset) { index, interaction in
                        InteractionDetailRow(
                            interaction: interaction,
                            severity: interactionManager.getInteractionSeverity(interaction)
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.3), value: showingDetails)
    }
}

struct InteractionDetailRow: View {
    let interaction: DrugInteraction
    let severity: InteractionManager.InteractionSeverity
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: severity.icon)
                .foregroundColor(severity.color)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(interaction.drug1)
                        .font(DesignSystem.Typography.statusText())
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    
                    Text(interaction.drug2)
                        .font(DesignSystem.Typography.statusText())
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    Text(severity.rawValue)
                        .font(DesignSystem.Typography.statusText())
                        .foregroundColor(severity.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(severity.color.opacity(0.15))
                        )
                }
                
                if !interaction.description.isEmpty {
                    Text(interaction.description)
                        .font(DesignSystem.Typography.bodySmall(weight: .regular, family: .sfPro))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(DesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(severity.color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct EnhancedPrescriptionCard: View {
    let prescription: Prescription
    let onMarkAsTaken: () -> Void
    let onMarkAsUntaken: () -> Void
    let onDelete: () -> Void
    @ObservedObject var interactionManager: InteractionManager
    @State private var showingDeleteConfirmation = false
    @State private var dragOffset: CGSize = .zero
    @State private var showingSwipeHint = false
    
    // MARK: - Computed Properties for Compile Optimization
    private var iconGradient: LinearGradient {
        prescription.isTaken ? DesignSystem.Gradients.successGradient : DesignSystem.Gradients.primaryGradient
    }
    
    private var iconName: String {
        prescription.isTaken ? "checkmark" : "pills.fill"
    }
    
    private var iconSize: CGFloat {
        prescription.isTaken ? 20 : 18
    }
    
    private var shadowColor: Color {
        (prescription.isTaken ? DesignSystem.Colors.success : DesignSystem.Colors.primary).opacity(0.3)
    }
    
    private var cardBackgroundColor: Color {
        if dragOffset.width > 50 {
            return Color.green.opacity(0.2)
        } else if dragOffset.width < -50 {
            return Color.orange.opacity(0.2)
        } else {
            return Color.clear
        }
    }
    
    private var conflictBorder: LinearGradient {
        if let severity = interactionManager.getHighestSeverityFor(prescription: prescription) {
            return LinearGradient(
                colors: [severity.color.opacity(0.4), severity.color.opacity(0.1)], 
                startPoint: .topLeading, 
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(colors: [Color.clear], startPoint: .center, endPoint: .center)
        }
    }
    
    private var borderWidth: CGFloat {
        interactionManager.hasInteractions(for: prescription) ? 2.0 : 0
    }
    
    private var medicationIcon: some View {
        Circle()
            .fill(iconGradient)
            .frame(width: 56, height: 56)
            .overlay(
                Image(systemName: iconName)
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundColor(.white)
            )
            .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
    }
    
    var body: some View {
        ZStack {
            // Background with swipe indicator
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBackgroundColor)
                .animation(.easeInOut(duration: 0.2), value: dragOffset)
            
            VStack(spacing: 0) {
                // Main card content with improved spacing
                HStack(spacing: DesignSystem.Spacing.lg) {
                    // Medication Icon with better proportions
                    medicationIcon
                    
                    // Medication Details with improved spacing
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Text(prescription.name)
                                .font(DesignSystem.Typography.headingSmall(weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .lineLimit(1)
                            
                            if let severity = interactionManager.getHighestSeverityFor(prescription: prescription) {
                                Image(systemName: severity.icon)
                                    .foregroundColor(severity.color)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            
                            Spacer()
                        }
                        
                        Text(prescription.dose)
                            .font(DesignSystem.Typography.bodyMedium(weight: .medium, family: .sfPro))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        if let lastTaken = prescription.lastTaken {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Image(systemName: "clock")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(DesignSystem.Colors.textTertiary)
                                
                                Text("Taken \(formatDate(lastTaken))")
                                    .font(DesignSystem.Typography.bodySmall(weight: .regular, family: .sfPro))
                                    .foregroundColor(DesignSystem.Colors.textTertiary)
                            }
                        }
                    }
                    
                    Spacer(minLength: DesignSystem.Spacing.sm)
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.lg)
                
                // Swipe hint overlay
                if showingSwipeHint {
                    HStack {
                        if dragOffset.width > 50 && !prescription.isTaken {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(DesignSystem.Colors.success)
                                Text("Release to mark taken")
                                    .font(DesignSystem.Typography.statusText())
                                    .foregroundColor(DesignSystem.Colors.success)
                            }
                        } else if dragOffset.width < -50 && prescription.isTaken {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(DesignSystem.Colors.warning)
                                Text("Release to mark untaken")
                                    .font(DesignSystem.Typography.statusText())
                                    .foregroundColor(DesignSystem.Colors.warning)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.bottom, DesignSystem.Spacing.md)
                }
            }
            .offset(x: dragOffset.width * 0.1) // Subtle movement
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                        // Only show hint if the swipe direction makes sense for the current state
                        let shouldShowHint = (dragOffset.width > 30 && !prescription.isTaken) || 
                                           (dragOffset.width < -30 && prescription.isTaken)
                        showingSwipeHint = shouldShowHint
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 60
                        
                        if value.translation.width > threshold {
                            // Swipe right - mark as taken
                            if !prescription.isTaken {
                                onMarkAsTaken()
                            }
                        } else if value.translation.width < -threshold {
                            // Swipe left - mark as untaken
                            if prescription.isTaken {
                                onMarkAsUntaken()
                            }
                        }
                        
                        // Reset with animation
                        withAnimation(.spring(response: 0.4)) {
                            dragOffset = .zero
                            showingSwipeHint = false
                        }
                    }
            )
            
        }
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .strokeBorder(conflictBorder, lineWidth: borderWidth)
        )
        .alert("Delete Medication", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete \(prescription.name)?")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}


struct NoResultsView: View {
    let searchText: String
    let showingOverdueOnly: Bool
    
    // MARK: - Computed Properties for Compile Optimization
    private var iconName: String {
        if !searchText.isEmpty {
            return "magnifyingglass"
        } else if showingOverdueOnly {
            return "moon.stars"
        } else {
            return "leaf.fill"
        }
    }
    
    private var titleText: String {
        if !searchText.isEmpty {
            return "Nothing found"
        } else if showingOverdueOnly {
            return "All set!"
        } else {
            return "Welcome to Wellness"
        }
    }
    
    private var subtitleText: String {
        if !searchText.isEmpty {
            return "Try searching for a different medication"
        } else if showingOverdueOnly {
            return "No overdue medications to worry about"
        } else {
            return "Start your health journey by adding your first medication"
        }
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xxxl) {
            Spacer()
            
            VStack(spacing: DesignSystem.Spacing.xxl) {
                Circle()
                    .fill(DesignSystem.Gradients.secondaryGradient.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: iconName)
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(DesignSystem.Colors.secondary)
                    )
                
                VStack(spacing: DesignSystem.Spacing.md) {
                    Text(titleText)
                        .font(DesignSystem.Typography.displaySmall(weight: .semibold))
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(subtitleText)
                        .font(DesignSystem.Typography.bodyMedium(weight: .regular, family: .sfPro))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, searchText.isEmpty && !showingOverdueOnly ? DesignSystem.Spacing.xl : 0)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignSystem.Spacing.xl)
    }
}

// Preview
struct PrescriptionListView_Previews: PreviewProvider {
    static var previews: some View {
        PrescriptionListView(prescriptionStore: PrescriptionStore())
    }
}
