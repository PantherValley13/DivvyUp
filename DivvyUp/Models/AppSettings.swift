import Foundation

struct AppSettings: Identifiable, Codable {
    let id: UUID = UUID()
    var defaultTipPercentage: Double
    var defaultTaxPercentage: Double
    var currencyCode: String
    var roundingMode: RoundingMode
    var saveHistory: Bool
    var defaultParticipants: [Participant]
    
    enum RoundingMode: String, Codable {
        case none
        case up
        case down
        case nearest
    }
    
    init(
        defaultTipPercentage: Double = 15.0,
        defaultTaxPercentage: Double = 8.0,
        currencyCode: String = "USD",
        roundingMode: RoundingMode = .nearest,
        saveHistory: Bool = true,
        defaultParticipants: [Participant] = []
    ) {
        self.defaultTipPercentage = defaultTipPercentage
        self.defaultTaxPercentage = defaultTaxPercentage
        self.currencyCode = currencyCode
        self.roundingMode = roundingMode
        self.saveHistory = saveHistory
        self.defaultParticipants = defaultParticipants
    }
} 