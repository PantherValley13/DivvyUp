import Foundation
import SwiftUI
import UniformTypeIdentifiers

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

// MARK: - Transferable Conformance
extension BillItem: Transferable {
    nonisolated static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
} 