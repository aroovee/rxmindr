import SwiftUI

struct MedicationCalendarView: View {
    @ObservedObject var recordManager: MedicationRecordManager
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @State private var showingDateDetail = false
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.mint.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Calendar Header Card
                        CalendarHeaderCard(
                            currentMonth: $currentMonth,
                            recordManager: recordManager,
                            dateFormatter: dateFormatter
                        )
                        
                        // Calendar Grid Card
                        CalendarGridCard(
                            currentMonth: $currentMonth,
                            selectedDate: $selectedDate,
                            showingDateDetail: $showingDateDetail,
                            recordManager: recordManager
                        )
                        
                        // Legend Card
                        AdherenceLegendCard()
                        
                        // Monthly Statistics Card
                        MonthlyStatsCard(
                            currentMonth: currentMonth,
                            recordManager: recordManager
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("Medication Calendar")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingDateDetail) {
                DayDetailView(
                    date: selectedDate,
                    recordManager: recordManager
                )
            }
        }
    }
}

// MARK: - Calendar Header Card
struct CalendarHeaderCard: View {
    @Binding var currentMonth: Date
    let recordManager: MedicationRecordManager
    let dateFormatter: DateFormatter
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(dateFormatter.string(from: currentMonth))
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    
                    if let monthData = recordManager.getMonthlyData(for: currentMonth) {
                        Text("\(Int(monthData.overallAdherence))% adherence this month")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .disabled(calendar.isDate(currentMonth, equalTo: Date(), toGranularity: .month))
            }
            
            // Week day headers
            HStack {
                ForEach(weekdayHeaders, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private var weekdayHeaders: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.shortWeekdaySymbols
    }
    
    private func previousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }
    
    private func nextMonth() {
        guard let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth),
              !calendar.isDate(newMonth, equalTo: Date(), toGranularity: .month) || calendar.compare(newMonth, to: Date(), toGranularity: .month) != .orderedDescending else {
            return
        }
        currentMonth = newMonth
    }
}

// MARK: - Calendar Grid Card
struct CalendarGridCard: View {
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date
    @Binding var showingDateDetail: Bool
    let recordManager: MedicationRecordManager
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(monthDays, id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        currentMonth: currentMonth,
                        recordManager: recordManager,
                        onTap: {
                            selectedDate = date
                            showingDateDetail = true
                        }
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private var monthDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }
        let monthStart = monthInterval.start
        let monthEnd = monthInterval.end
        
        // Find the first day of the week that contains the first day of the month
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let daysFromPreviousMonth = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        let startDate = calendar.date(byAdding: .day, value: -daysFromPreviousMonth, to: monthStart) ?? monthStart
        
        // Generate dates for the calendar grid (6 weeks = 42 days)
        var days: [Date] = []
        var currentDate = startDate
        
        for _ in 0..<42 {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            
            // Stop if we've passed the end of the next month
            if calendar.compare(currentDate, to: monthEnd, toGranularity: .month) == .orderedDescending {
                let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
                if calendar.component(.weekday, from: currentDate) == calendar.firstWeekday {
                    break
                }
            }
        }
        
        return days
    }
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    let date: Date
    let currentMonth: Date
    let recordManager: MedicationRecordManager
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(borderColor, lineWidth: isToday ? 2 : 0)
                    )
                
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textColor)
            }
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.3 : 1.0)
    }
    
    private var dayData: DayAdherenceData? {
        recordManager.getDayData(for: date)
    }
    
    private var adherenceLevel: AdherenceLevel {
        dayData?.adherenceLevel ?? .noMedications
    }
    
    private var backgroundColor: Color {
        if !isCurrentMonth { return .clear }
        
        switch adherenceLevel {
        case .perfect: return .green.opacity(0.9)
        case .good: return .blue.opacity(0.8)
        case .fair: return .yellow.opacity(0.7)
        case .poor: return .orange.opacity(0.6)
        case .missed: return .red.opacity(0.5)
        case .noMedications: return .gray.opacity(0.2)
        }
    }
    
    private var textColor: Color {
        if !isCurrentMonth { return .secondary }
        if adherenceLevel == .noMedications { return .primary }
        return .white
    }
    
    private var borderColor: Color {
        isToday ? .blue : .clear
    }
    
    private var isCurrentMonth: Bool {
        calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    private var isFuture: Bool {
        calendar.compare(date, to: Date(), toGranularity: .day) == .orderedDescending
    }
    
    private var isDisabled: Bool {
        isFuture || !isCurrentMonth
    }
}

// MARK: - Adherence Legend Card
struct AdherenceLegendCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text("Adherence Legend")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(AdherenceLevel.allCases.filter { $0 != .noMedications }, id: \.self) { level in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(colorForLevel(level))
                            .frame(width: 20, height: 20)
                        
                        Text(level.description)
                            .font(.caption)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private func colorForLevel(_ level: AdherenceLevel) -> Color {
        switch level {
        case .perfect: return .green.opacity(0.9)
        case .good: return .blue.opacity(0.8)
        case .fair: return .yellow.opacity(0.7)
        case .poor: return .orange.opacity(0.6)
        case .missed: return .red.opacity(0.5)
        case .noMedications: return .gray.opacity(0.2)
        }
    }
}

// MARK: - Monthly Statistics Card
struct MonthlyStatsCard: View {
    let currentMonth: Date
    let recordManager: MedicationRecordManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                
                Text("Monthly Statistics")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            if let monthData = recordManager.getMonthlyData(for: currentMonth) {
                VStack(spacing: 12) {
                    StatRow(
                        icon: "percent",
                        title: "Overall Adherence",
                        value: "\(Int(monthData.overallAdherence))%",
                        color: adherenceColor(monthData.overallAdherence)
                    )
                    
                    StatRow(
                        icon: "calendar",
                        title: "Active Days",
                        value: "\(monthData.activeDays) of \(monthData.totalDays)",
                        color: .blue
                    )
                    
                    StatRow(
                        icon: "flame.fill",
                        title: "Current Streak",
                        value: "\(recordManager.getAdherenceStreak()) days",
                        color: .orange
                    )
                }
            } else {
                Text("No data available for this month")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private func adherenceColor(_ percentage: Double) -> Color {
        if percentage >= 90 { return .green }
        if percentage >= 70 { return .blue }
        if percentage >= 50 { return .yellow }
        return .red
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(color)
        }
    }
}

// MARK: - Day Detail View
struct DayDetailView: View {
    let date: Date
    let recordManager: MedicationRecordManager
    @Environment(\.presentationMode) var presentationMode
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.05), Color.mint.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Date Header
                        DayDetailHeaderCard(date: date, dayData: dayData)
                        
                        // Medication Records
                        if let dayData = dayData, !dayData.medicationRecords.isEmpty {
                            ForEach(dayData.medicationRecords, id: \.id) { record in
                                MedicationRecordCard(record: record)
                            }
                        } else {
                            NoMedicationsCard(date: date)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Day Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private var dayData: DayAdherenceData? {
        recordManager.getDayData(for: date)
    }
}

// MARK: - Day Detail Header Card
struct DayDetailHeaderCard: View {
    let date: Date
    let dayData: DayAdherenceData?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 12) {
            Text(dateFormatter.string(from: date))
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            if let dayData = dayData {
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("\(dayData.totalTaken)")
                            .font(.title.bold())
                            .foregroundColor(.blue)
                        Text("Taken")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 4) {
                        Text("\(dayData.totalScheduled)")
                            .font(.title.bold())
                            .foregroundColor(.gray)
                        Text("Scheduled")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 4) {
                        Text("\(Int(dayData.adherencePercentage))%")
                            .font(.title.bold())
                            .foregroundColor(.green)
                        Text("Adherence")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("No medications scheduled")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Medication Record Card
struct MedicationRecordCard: View {
    let record: DailyMedicationRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pills.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(record.prescriptionName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("\(record.takenDoses) of \(record.scheduledDoses) doses taken")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(Int(record.adherencePercentage))%")
                    .font(.title3.bold())
                    .foregroundColor(adherenceColor)
            }
            
            if !record.takenTimes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Taken at:")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                    
                    ForEach(record.takenTimes.indices, id: \.self) { index in
                        Text(timeFormatter.string(from: record.takenTimes[index]))
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(adherenceColor.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    private var adherenceColor: Color {
        if record.adherencePercentage >= 100 { return .green }
        if record.adherencePercentage >= 80 { return .blue }
        if record.adherencePercentage >= 50 { return .yellow }
        if record.adherencePercentage > 0 { return .orange }
        return .red
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - No Medications Card
struct NoMedicationsCard: View {
    let date: Date
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.minus")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No medications scheduled")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("You didn't have any medications to take on this day.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}