import Foundation

// MARK: - Daily Medication Record
struct DailyMedicationRecord: Codable, Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let prescriptionId: UUID
    let prescriptionName: String
    let scheduledDoses: Int // Total doses scheduled for this day
    let takenDoses: Int // Actual doses taken
    let reminderTimes: [Date] // Scheduled reminder times for this day
    let takenTimes: [Date] // Actual times when medication was taken
    let adherencePercentage: Double // Calculated: takenDoses / scheduledDoses * 100
    
    init(date: Date, prescriptionId: UUID, prescriptionName: String, scheduledDoses: Int, takenDoses: Int = 0, reminderTimes: [Date] = [], takenTimes: [Date] = []) {
        self.date = Calendar.current.startOfDay(for: date)
        self.prescriptionId = prescriptionId
        self.prescriptionName = prescriptionName
        self.scheduledDoses = max(1, scheduledDoses)
        self.takenDoses = min(takenDoses, self.scheduledDoses)
        self.reminderTimes = reminderTimes
        self.takenTimes = takenTimes
        self.adherencePercentage = self.scheduledDoses > 0 ? (Double(self.takenDoses) / Double(self.scheduledDoses)) * 100.0 : 0.0
    }
}

// MARK: - Monthly Adherence Summary
struct MonthlyAdherenceData: Codable, Equatable {
    let month: Int
    let year: Int
    let dailyRecords: [String: DayAdherenceData] // Key: "yyyy-MM-dd" format
    let overallAdherence: Double
    let totalDays: Int
    let activeDays: Int // Days where medications were scheduled
    
    init(month: Int, year: Int, records: [DailyMedicationRecord]) {
        self.month = month
        self.year = year
        
        // Group records by date
        var dailyData: [String: DayAdherenceData] = [:]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let groupedRecords = Dictionary(grouping: records) { record in
            dateFormatter.string(from: record.date)
        }
        
        var totalScheduled = 0
        var totalTaken = 0
        
        for (dateString, dayRecords) in groupedRecords {
            let dayScheduled = dayRecords.reduce(0) { $0 + $1.scheduledDoses }
            let dayTaken = dayRecords.reduce(0) { $0 + $1.takenDoses }
            let dayAdherence = dayScheduled > 0 ? (Double(dayTaken) / Double(dayScheduled)) * 100.0 : 0.0
            
            dailyData[dateString] = DayAdherenceData(
                date: dayRecords.first?.date ?? Date(),
                totalScheduled: dayScheduled,
                totalTaken: dayTaken,
                adherencePercentage: dayAdherence,
                medicationRecords: dayRecords
            )
            
            totalScheduled += dayScheduled
            totalTaken += dayTaken
        }
        
        self.dailyRecords = dailyData
        self.overallAdherence = totalScheduled > 0 ? (Double(totalTaken) / Double(totalScheduled)) * 100.0 : 0.0
        self.totalDays = Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 30
        self.activeDays = dailyData.count
    }
}

// MARK: - Day Adherence Data
struct DayAdherenceData: Codable, Equatable {
    let date: Date
    let totalScheduled: Int
    let totalTaken: Int
    let adherencePercentage: Double
    let medicationRecords: [DailyMedicationRecord]
    
    var adherenceLevel: AdherenceLevel {
        if totalScheduled == 0 { return .noMedications }
        if adherencePercentage >= 100 { return .perfect }
        if adherencePercentage >= 80 { return .good }
        if adherencePercentage >= 50 { return .fair }
        if adherencePercentage > 0 { return .poor }
        return .missed
    }
}

// MARK: - Adherence Level Enum
enum AdherenceLevel: String, CaseIterable, Codable {
    case perfect = "perfect"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    case missed = "missed"
    case noMedications = "none"
    
    var color: String {
        switch self {
        case .perfect: return "green"
        case .good: return "blue"
        case .fair: return "yellow"
        case .poor: return "orange"
        case .missed: return "red"
        case .noMedications: return "gray"
        }
    }
    
    var opacity: Double {
        switch self {
        case .perfect: return 1.0
        case .good: return 0.8
        case .fair: return 0.6
        case .poor: return 0.4
        case .missed: return 0.2
        case .noMedications: return 0.1
        }
    }
    
    var description: String {
        switch self {
        case .perfect: return "Perfect (100%)"
        case .good: return "Good (80-99%)"
        case .fair: return "Fair (50-79%)"
        case .poor: return "Poor (1-49%)"
        case .missed: return "Missed (0%)"
        case .noMedications: return "No medications"
        }
    }
}

// MARK: - Record Manager
class MedicationRecordManager: ObservableObject {
    @Published var monthlyData: [String: MonthlyAdherenceData] = [:]  // Key: "yyyy-MM" format
    @Published var currentMonthKey: String = ""
    
    private let userDefaults = UserDefaults.standard
    private let recordsKey = "MedicationRecords"
    
    init() {
        loadRecords()
        updateCurrentMonthKey()
    }
    
    private func updateCurrentMonthKey() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        currentMonthKey = formatter.string(from: Date())
    }
    
    // MARK: - Record Management
    func recordMedicationTaken(prescription: Prescription, takenAt: Date = Date()) {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: takenAt)
        
        // Create or update daily record
        let record = createOrUpdateDailyRecord(
            for: prescription,
            date: dayStart,
            incrementTaken: true,
            takenTime: takenAt
        )
        
        updateMonthlyData(with: record)
        saveRecords()
    }
    
    func recordMedicationNotTaken(prescription: Prescription, date: Date = Date()) {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        // Create or update daily record to mark as not taken
        let record = createOrUpdateDailyRecord(
            for: prescription,
            date: dayStart,
            incrementTaken: false,
            takenTime: nil
        )
        
        updateMonthlyData(with: record)
        saveRecords()
    }
    
    func initializeDailyRecords(for prescriptions: [Prescription], date: Date = Date()) {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        
        for prescription in prescriptions {
            // Only create records for active prescriptions
            if isActivePrescription(prescription, on: date) {
                let _ = createOrUpdateDailyRecord(
                    for: prescription,
                    date: dayStart,
                    incrementTaken: false
                )
            }
        }
        
        rebuildMonthlyData()
        saveRecords()
    }
    
    private func createOrUpdateDailyRecord(for prescription: Prescription, date: Date, incrementTaken: Bool, takenTime: Date? = nil) -> DailyMedicationRecord {
        let monthKey = getMonthKey(for: date)
        let dateKey = getDateKey(for: date)
        
        // Get existing record or create new one
        var existingRecord = monthlyData[monthKey]?.dailyRecords[dateKey]?.medicationRecords.first { $0.prescriptionId == prescription.id }
        
        let scheduledDoses = prescription.dailyFrequency
        let reminderTimes = prescription.reminderTimes.map { reminderTime in
            Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: reminderTime.time),
                                  minute: Calendar.current.component(.minute, from: reminderTime.time),
                                  second: 0,
                                  of: date) ?? date
        }
        
        if var record = existingRecord {
            // Update existing record
            if incrementTaken {
                let newTakenDoses = min(record.takenDoses + 1, scheduledDoses)
                var newTakenTimes = record.takenTimes
                if let takenTime = takenTime {
                    newTakenTimes.append(takenTime)
                }
                
                existingRecord = DailyMedicationRecord(
                    date: date,
                    prescriptionId: prescription.id,
                    prescriptionName: prescription.name,
                    scheduledDoses: scheduledDoses,
                    takenDoses: newTakenDoses,
                    reminderTimes: reminderTimes,
                    takenTimes: newTakenTimes
                )
            }
        } else {
            // Create new record
            let takenDoses = incrementTaken ? 1 : 0
            let takenTimes = incrementTaken && takenTime != nil ? [takenTime!] : []
            
            existingRecord = DailyMedicationRecord(
                date: date,
                prescriptionId: prescription.id,
                prescriptionName: prescription.name,
                scheduledDoses: scheduledDoses,
                takenDoses: takenDoses,
                reminderTimes: reminderTimes,
                takenTimes: takenTimes
            )
        }
        
        return existingRecord!
    }
    
    private func updateMonthlyData(with record: DailyMedicationRecord) {
        let monthKey = getMonthKey(for: record.date)
        let dateKey = getDateKey(for: record.date)
        
        // Get all records for this month
        var allRecords: [DailyMedicationRecord] = []
        
        if let existingMonthData = monthlyData[monthKey] {
            // Collect all existing records except the one we're updating
            for (_, dayData) in existingMonthData.dailyRecords {
                allRecords.append(contentsOf: dayData.medicationRecords.filter { $0.prescriptionId != record.prescriptionId || getDateKey(for: $0.date) != dateKey })
            }
        }
        
        // Add the updated record
        allRecords.append(record)
        
        // Rebuild monthly data
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month], from: record.date)
        
        monthlyData[monthKey] = MonthlyAdherenceData(
            month: dateComponents.month ?? 1,
            year: dateComponents.year ?? 2024,
            records: allRecords
        )
    }
    
    private func rebuildMonthlyData() {
        let calendar = Calendar.current
        var allRecords: [String: [DailyMedicationRecord]] = [:]
        
        // Group all records by month
        for (monthKey, monthData) in monthlyData {
            var monthRecords: [DailyMedicationRecord] = []
            for (_, dayData) in monthData.dailyRecords {
                monthRecords.append(contentsOf: dayData.medicationRecords)
            }
            allRecords[monthKey] = monthRecords
        }
        
        // Rebuild monthly data for each month
        for (monthKey, records) in allRecords {
            let firstRecord = records.first
            let dateComponents = calendar.dateComponents([.year, .month], from: firstRecord?.date ?? Date())
            
            monthlyData[monthKey] = MonthlyAdherenceData(
                month: dateComponents.month ?? 1,
                year: dateComponents.year ?? 2024,
                records: records
            )
        }
    }
    
    // MARK: - Data Retrieval
    func getMonthlyData(for date: Date) -> MonthlyAdherenceData? {
        let monthKey = getMonthKey(for: date)
        return monthlyData[monthKey]
    }
    
    func getCurrentMonthData() -> MonthlyAdherenceData? {
        return monthlyData[currentMonthKey]
    }
    
    // Get all daily records for a specific prescription
    func getRecords(for prescriptionId: UUID) -> [DailyMedicationRecord] {
        var allRecords: [DailyMedicationRecord] = []
        
        // Go through all monthly data and collect records for this prescription
        for (_, monthlyData) in monthlyData {
            for (_, dayData) in monthlyData.dailyRecords {
                for record in dayData.medicationRecords {
                    if record.prescriptionId == prescriptionId {
                        allRecords.append(record)
                    }
                }
            }
        }
        
        // Sort by date (most recent first)
        return allRecords.sorted { $0.date > $1.date }
    }
    
    func getDayData(for date: Date) -> DayAdherenceData? {
        let monthKey = getMonthKey(for: date)
        let dateKey = getDateKey(for: date)
        return monthlyData[monthKey]?.dailyRecords[dateKey]
    }
    
    // MARK: - Utility Methods
    private func isActivePrescription(_ prescription: Prescription, on date: Date) -> Bool {
        let calendar = Calendar.current
        
        // Check if prescription has started
        if calendar.compare(date, to: prescription.startDate, toGranularity: .day) == .orderedAscending {
            return false
        }
        
        // Check if prescription has ended
        if let endDate = prescription.endDate,
           calendar.compare(date, to: endDate, toGranularity: .day) == .orderedDescending {
            return false
        }
        
        return true
    }
    
    private func getMonthKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }
    
    private func getDateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // MARK: - Persistence
    private func saveRecords() {
        if let data = try? JSONEncoder().encode(monthlyData) {
            userDefaults.set(data, forKey: recordsKey)
        }
    }
    
    private func loadRecords() {
        guard let data = userDefaults.data(forKey: recordsKey),
              let records = try? JSONDecoder().decode([String: MonthlyAdherenceData].self, from: data) else {
            return
        }
        monthlyData = records
    }
    
    // MARK: - Analytics
    func getAdherenceStreak() -> Int {
        guard let currentMonth = getCurrentMonthData() else { return 0 }
        
        let calendar = Calendar.current
        var streak = 0
        let today = calendar.startOfDay(for: Date())
        
        for i in 0..<30 { // Check last 30 days
            let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
            let dateKey = getDateKey(for: date)
            
            if let dayData = currentMonth.dailyRecords[dateKey] {
                if dayData.adherencePercentage >= 80 { // Consider 80%+ as maintaining streak
                    streak += 1
                } else {
                    break
                }
            } else {
                break
            }
        }
        
        return streak
    }
    
    func getWeeklyProgress() -> [Bool] {
        let calendar = Calendar.current
        var progress: [Bool] = Array(repeating: false, count: 7)
        let today = calendar.startOfDay(for: Date())
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: today) ?? today
            if let dayData = getDayData(for: date) {
                progress[6-i] = dayData.adherencePercentage >= 80
            }
        }
        
        return progress
    }
}