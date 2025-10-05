import Foundation

struct Prescription: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var dose: String
    var frequency: String
    var dailyFrequency: Int  // Added this property
    var startDate: Date
    var endDate: Date?
    var reminderTimes: [ReminderTime]
    var isTaken: Bool
    var lastTaken: Date?
    var recordTaken: [Date] = []
    var drugInfo: DrugInformation?
    var hasConflicts: Bool
    var conflicts: [String]
    
    // Refill tracking fields
    var totalPills: Int?
    var pillsRemaining: Int?
    var refillDate: Date?
    var prescriptionNumber: String?
    var pharmacy: String?
    var physicianName: String?
    
    // Travel mode fields
    var isEssentialForTravel: Bool = false
    var travelNotes: String?
    
    
    struct ReminderTime: Codable, Identifiable, Equatable {
        let id: UUID
        var time: Date
        var isEnabled: Bool
        
        init(id: UUID = UUID(), time: Date = Date(), isEnabled: Bool = true) {
            self.id = id
            self.time = time
            self.isEnabled = isEnabled
        }
    }
    
    init(id: UUID = UUID(),
         name: String,
         dose: String,
         frequency: String,
         dailyFrequency: Int = 1,
         startDate: Date,
         endDate: Date? = nil,
         reminderTimes: [ReminderTime] = [],
         isTaken: Bool = false,
         lastTaken: Date? = nil,
         hasConflicts: Bool = false,
         conflicts: [String] = [],
         drugInfo: DrugInformation? = nil,
         totalPills: Int? = nil,
         pillsRemaining: Int? = nil,
         refillDate: Date? = nil,
         prescriptionNumber: String? = nil,
         pharmacy: String? = nil,
         physicianName: String? = nil,
         isEssentialForTravel: Bool = false,
         travelNotes: String? = nil) {
         
        self.id = id
        self.name = name
        self.dose = dose
        self.frequency = frequency
        self.dailyFrequency = dailyFrequency
        self.startDate = startDate
        self.endDate = endDate
        self.reminderTimes = reminderTimes.isEmpty ? [ReminderTime()] : reminderTimes
        self.isTaken = isTaken
        self.lastTaken = lastTaken
        self.drugInfo = drugInfo
        self.hasConflicts = hasConflicts
        self.conflicts = []
        self.totalPills = totalPills
        self.pillsRemaining = pillsRemaining
        self.refillDate = refillDate
        self.prescriptionNumber = prescriptionNumber
        self.pharmacy = pharmacy
        self.physicianName = physicianName
        self.isEssentialForTravel = isEssentialForTravel
        self.travelNotes = travelNotes
    }
}
