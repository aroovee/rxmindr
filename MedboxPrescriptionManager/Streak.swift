import Foundation

class Streak: ObservableObject {
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var weeklyProgress: [Bool] = Array(repeating: false, count: 7)
    @Published var totalDaysTaken: Int = 0
    @Published var streakStartDate: Date?
    
    private let calendar = Calendar.current
    private var recordManager: MedicationRecordManager?
    
    init() {
        loadStreakData()
    }
    
    func setRecordManager(_ recordManager: MedicationRecordManager) {
        self.recordManager = recordManager
        updateStreakFromRecords()
    }
    
    func updateStreak(for prescriptions: [Prescription]) {
        // Use record manager if available for more accurate data
        if recordManager != nil {
            updateStreakFromRecords()
        } else {
            // Fallback to old method
            updateStreakLegacy(for: prescriptions)
        }
    }
    
    private func updateStreakFromRecords() {
        guard let recordManager = recordManager else { return }
        
        // Get streak data from record manager
        let newStreak = recordManager.getAdherenceStreak()
        let weeklyProgress = recordManager.getWeeklyProgress()
        
        // Update our published properties
        if newStreak != currentStreak {
            currentStreak = newStreak
            if currentStreak > longestStreak {
                longestStreak = currentStreak
            }
        }
        
        self.weeklyProgress = weeklyProgress
        
        // Update streak start date if needed
        if currentStreak > 0 && streakStartDate == nil {
            let today = Date()
            streakStartDate = calendar.date(byAdding: .day, value: -currentStreak + 1, to: today)
        } else if currentStreak == 0 {
            streakStartDate = nil
        }
        
        saveStreakData()
    }
    
    private func updateStreakLegacy(for prescriptions: [Prescription]) {
        let today = Date()
        
        var todayTaken = false
        for prescription in prescriptions {
            if let lastTaken = prescription.lastTaken,
               calendar.isDate(lastTaken, inSameDayAs: today) {
                todayTaken = true
                break
            }
        }
        
        let weekday = calendar.component(.weekday, from: today)
        let adjustedWeekday = weekday == 1 ? 6 : weekday - 2
        
        // Ensure adjustedWeekday is within valid range (0-6)
        guard adjustedWeekday >= 0 && adjustedWeekday < weeklyProgress.count else { return }
        
        if todayTaken && !weeklyProgress[adjustedWeekday] {
            weeklyProgress[adjustedWeekday] = true
            currentStreak += 1
            totalDaysTaken += 1
            
            if streakStartDate == nil {
                streakStartDate = today
            }
            
            if currentStreak > longestStreak {
                longestStreak = currentStreak
            }
        } else if !todayTaken && shouldResetStreak(today) {
            resetCurrentStreak()
        }
        
        saveStreakData()
    }
    
    private func shouldResetStreak(_ today: Date) -> Bool {
        guard let startDate = streakStartDate else { return false }
        let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: today).day ?? 0
        return daysSinceStart > currentStreak
    }
    
    private func resetCurrentStreak() {
        currentStreak = 0
        streakStartDate = nil
        weeklyProgress = Array(repeating: false, count: 7)
    }
    
    func getWeeklyCompletionRate() -> Double {
        let completedDays = weeklyProgress.filter { $0 }.count
        return Double(completedDays) / 7.0
    }
    
    func getCurrentWeekDays() -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = weekday == 1 ? 6 : weekday - 2
        
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            return ["M", "T", "W", "T", "F", "S", "S"]
        }
        
        return (0..<7).compactMap { dayOffset in
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: monday) else { return nil }
            return formatter.string(from: day)
        }
    }
    
    private func saveStreakData() {
        UserDefaults.standard.set(currentStreak, forKey: "currentStreak")
        UserDefaults.standard.set(longestStreak, forKey: "longestStreak")
        UserDefaults.standard.set(totalDaysTaken, forKey: "totalDaysTaken")
        UserDefaults.standard.set(weeklyProgress, forKey: "weeklyProgress")
        if let startDate = streakStartDate {
            UserDefaults.standard.set(startDate, forKey: "streakStartDate")
        }
    }
    
    private func loadStreakData() {
        currentStreak = UserDefaults.standard.integer(forKey: "currentStreak")
        longestStreak = UserDefaults.standard.integer(forKey: "longestStreak")
        totalDaysTaken = UserDefaults.standard.integer(forKey: "totalDaysTaken")
        weeklyProgress = UserDefaults.standard.array(forKey: "weeklyProgress") as? [Bool] ?? Array(repeating: false, count: 7)
        streakStartDate = UserDefaults.standard.object(forKey: "streakStartDate") as? Date
    }
}

typealias StreakManager = Streak
