import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Data Models

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

struct BillItem: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var price: Double
    var quantity: Int = 1
    var assignedTo: UUID? = nil // Single participant ID
    var isManuallyAssigned: Bool = false
    
    init(id: UUID = UUID(), name: String, price: Double, quantity: Int = 1, assignedTo: UUID? = nil, isManuallyAssigned: Bool = false) {
        self.id = id
        self.name = name
        self.price = price
        self.quantity = quantity
        self.assignedTo = assignedTo
        self.isManuallyAssigned = isManuallyAssigned
    }
    
    var pricePerPerson: Double {
        guard assignedTo != nil else { return 0 }
        return price
    }
    
    static func == (lhs: BillItem, rhs: BillItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Codable Conformance
extension BillItem: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, price, quantity, assignedTo, isManuallyAssigned
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        price = try container.decode(Double.self, forKey: .price)
        quantity = try container.decodeIfPresent(Int.self, forKey: .quantity) ?? 1
        assignedTo = try container.decodeIfPresent(UUID.self, forKey: .assignedTo)
        isManuallyAssigned = try container.decodeIfPresent(Bool.self, forKey: .isManuallyAssigned) ?? false
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(price, forKey: .price)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(assignedTo, forKey: .assignedTo)
        try container.encode(isManuallyAssigned, forKey: .isManuallyAssigned)
    }
}

struct Participant: Identifiable, Codable {
    let id: UUID
    var name: String
    var colorName: String
    
    init(id: UUID = UUID(), name: String, colorName: String = "blue") {
        self.id = id
        self.name = name
        self.colorName = colorName
    }
}

extension Participant {
    var color: Color {
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "teal": return .teal
        case "indigo": return .indigo
        default: return .blue
        }
    }
}

struct Bill: Identifiable, Codable {
    let id: UUID
    var items: [BillItem] = []
    var participants: [Participant] = []
    var taxAmount: Double = 0.0
    var tipAmount: Double = 0.0
    var date: Date = Date()
    
    init(
        id: UUID = UUID(),
        items: [BillItem] = [],
        participants: [Participant] = [],
        taxAmount: Double = 0.0,
        tipAmount: Double = 0.0,
        date: Date = Date()
    ) {
        self.id = id
        self.items = items
        self.participants = participants
        self.taxAmount = taxAmount
        self.tipAmount = tipAmount
        self.date = date
    }
    
    var subtotal: Double {
        items.reduce(0) { $0 + $1.price * Double($1.quantity) }
    }
    
    var taxTotal: Double {
        subtotal * (taxAmount / 100)
    }
    
    var tipTotal: Double {
        subtotal * (tipAmount / 100)
    }
    
    var finalTotal: Double {
        subtotal + taxTotal + tipTotal
    }
    
    func totalForParticipant(_ participant: Participant) -> Double {
        let assignedItems = items.filter { $0.assignedTo == participant.id }
        let itemsTotal = assignedItems.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
        
        // Calculate share of tax and tip
        let taxShare = (itemsTotal / subtotal) * taxTotal
        let tipShare = (itemsTotal / subtotal) * tipTotal
        
        return itemsTotal + taxShare + tipShare
    }
}

// MARK: - Transferable Conformance
// The Transferable conformance must be 'nonisolated' so it does not inherit actor isolation and break Sendable/Codable synthesis.
// Do not add actor-isolated or MainActor-isolated properties or methods to BillItem.
extension BillItem: Transferable {
    nonisolated static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}
 