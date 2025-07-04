import Foundation
import Supabase
import Combine

// MARK: - Database Models for Supabase
struct DatabaseBill: Identifiable, Sendable {
    let id: UUID
    var items: [DatabaseBillItem]
    var participants: [DatabaseParticipant]
    var taxAmount: Double
    var tipAmount: Double
    var date: Date
    var updatedAt: Date
    
    init(from bill: Bill) {
        self.id = bill.id
        self.items = bill.items.map { DatabaseBillItem(from: $0) }
        self.participants = bill.participants.map { DatabaseParticipant(from: $0) }
        self.taxAmount = bill.taxAmount
        self.tipAmount = bill.tipAmount
        self.date = bill.date
        self.updatedAt = Date()
    }
    
    func toBill() -> Bill {
        return Bill(
            id: id,
            items: items.map { $0.toBillItem() },
            participants: participants.map { $0.toParticipant() },
            taxAmount: taxAmount,
            tipAmount: tipAmount,
            date: date
        )
    }
}

extension DatabaseBill: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case items
        case participants
        case taxAmount = "tax_amount"
        case tipAmount = "tip_amount"
        case date
        case updatedAt = "updated_at"
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        items = try container.decodeIfPresent([DatabaseBillItem].self, forKey: .items) ?? []
        participants = try container.decodeIfPresent([DatabaseParticipant].self, forKey: .participants) ?? []
        taxAmount = try container.decodeIfPresent(Double.self, forKey: .taxAmount) ?? 0.0
        tipAmount = try container.decodeIfPresent(Double.self, forKey: .tipAmount) ?? 0.0
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(items, forKey: .items)
        try container.encode(participants, forKey: .participants)
        try container.encode(taxAmount, forKey: .taxAmount)
        try container.encode(tipAmount, forKey: .tipAmount)
        try container.encode(date, forKey: .date)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

struct DatabaseBillItem: Identifiable, Sendable {
    let id: UUID
    var name: String
    var price: Double
    var quantity: Int
    var assignedTo: UUID?
    var isManuallyAssigned: Bool
    var billId: UUID
    
    init(from item: BillItem, billId: UUID = UUID()) {
        self.id = item.id
        self.name = item.name
        self.price = item.price
        self.quantity = item.quantity
        self.assignedTo = item.assignedTo
        self.isManuallyAssigned = item.isManuallyAssigned
        self.billId = billId
    }
    
    func toBillItem() -> BillItem {
        return BillItem(
            id: id,
            name: name,
            price: price,
            quantity: quantity,
            assignedTo: assignedTo,
            isManuallyAssigned: isManuallyAssigned
        )
    }
}

extension DatabaseBillItem: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case price
        case quantity
        case assignedTo = "assigned_to"
        case isManuallyAssigned = "is_manually_assigned"
        case billId = "bill_id"
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        price = try container.decode(Double.self, forKey: .price)
        quantity = try container.decodeIfPresent(Int.self, forKey: .quantity) ?? 1
        assignedTo = try container.decodeIfPresent(UUID.self, forKey: .assignedTo)
        isManuallyAssigned = try container.decodeIfPresent(Bool.self, forKey: .isManuallyAssigned) ?? false
        billId = try container.decode(UUID.self, forKey: .billId)
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(price, forKey: .price)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(assignedTo, forKey: .assignedTo)
        try container.encode(isManuallyAssigned, forKey: .isManuallyAssigned)
        try container.encode(billId, forKey: .billId)
    }
}

struct DatabaseParticipant: Identifiable, Sendable {
    let id: UUID
    var name: String
    var colorName: String
    var billId: UUID
    
    init(from participant: Participant, billId: UUID = UUID()) {
        self.id = participant.id
        self.name = participant.name
        self.colorName = participant.colorName
        self.billId = billId
    }
    
    func toParticipant() -> Participant {
        return Participant(id: id, name: name, colorName: colorName)
    }
}

extension DatabaseParticipant: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case colorName = "color_name"
        case billId = "bill_id"
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        colorName = try container.decodeIfPresent(String.self, forKey: .colorName) ?? "blue"
        billId = try container.decode(UUID.self, forKey: .billId)
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(colorName, forKey: .colorName)
        try container.encode(billId, forKey: .billId)
    }
}

// MARK: - Supabase Service
@MainActor
class SupabaseService: ObservableObject {
    private let supabase: SupabaseClient
    @Published var isLoading = false
    @Published var error: Error?
    
    init() {
        // Initialize Supabase client using configuration
        let supabaseURL = URL(string: SupabaseConfig.supabaseURL)!
        let supabaseKey = SupabaseConfig.supabaseAnonKey
        
        supabase = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
    }
    
    // MARK: - Bill Operations
    
    /// Save a bill to the database
    func saveBill(_ bill: Bill) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let databaseBill = DatabaseBill(from: bill)
            
            // Insert or update the bill
            try await supabase.database
                .from(SupabaseConfig.billsTable)
                .upsert(databaseBill)
                .execute()
            
            // Save items
            try await saveBillItems(bill.items, billId: bill.id)
            
            // Save participants
            try await saveParticipants(bill.participants, billId: bill.id)
            
        } catch {
            self.error = error
            throw error
        }
    }
    
    /// Load a bill from the database
    func loadBill(id: UUID) async throws -> Bill {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response: DatabaseBill = try await supabase.database
                .from(SupabaseConfig.billsTable)
                .select()
                .eq("id", value: id)
                .single()
                .execute()
                .value
            
            return response.toBill()
            
        } catch {
            self.error = error
            throw error
        }
    }
    
    /// Load all bills from the database
    func loadAllBills() async throws -> [Bill] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response: [DatabaseBill] = try await supabase.database
                .from(SupabaseConfig.billsTable)
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return response.map { $0.toBill() }
            
        } catch {
            self.error = error
            throw error
        }
    }
    
    /// Delete a bill from the database
    func deleteBill(id: UUID) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await supabase.database
                .from(SupabaseConfig.billsTable)
                .delete()
                .eq("id", value: id)
                .execute()
            
        } catch {
            self.error = error
            throw error
        }
    }
    
    // MARK: - Bill Items Operations
    
    private func saveBillItems(_ items: [BillItem], billId: UUID) async throws {
        let databaseItems = items.map { DatabaseBillItem(from: $0, billId: billId) }
        
        // Delete existing items for this bill
        try await supabase.database
            .from(SupabaseConfig.billItemsTable)
            .delete()
            .eq("bill_id", value: billId)
            .execute()
        
        // Insert new items
        if !databaseItems.isEmpty {
            try await supabase.database
                .from(SupabaseConfig.billItemsTable)
                .insert(databaseItems)
                .execute()
        }
    }
    
    func loadBillItems(billId: UUID) async throws -> [BillItem] {
        let response: [DatabaseBillItem] = try await supabase.database
            .from(SupabaseConfig.billItemsTable)
            .select()
            .eq("bill_id", value: billId)
            .execute()
            .value
        
        return response.map { $0.toBillItem() }
    }
    
    // MARK: - Participants Operations
    
    private func saveParticipants(_ participants: [Participant], billId: UUID) async throws {
        let databaseParticipants = participants.map { DatabaseParticipant(from: $0, billId: billId) }
        
        // Delete existing participants for this bill
        try await supabase.database
            .from(SupabaseConfig.participantsTable)
            .delete()
            .eq("bill_id", value: billId)
            .execute()
        
        // Insert new participants
        if !databaseParticipants.isEmpty {
            try await supabase.database
                .from(SupabaseConfig.participantsTable)
                .insert(databaseParticipants)
                .execute()
        }
    }
    
    func loadParticipants(billId: UUID) async throws -> [Participant] {
        let response: [DatabaseParticipant] = try await supabase.database
            .from(SupabaseConfig.participantsTable)
            .select()
            .eq("bill_id", value: billId)
            .execute()
            .value
        
        return response.map { $0.toParticipant() }
    }
    
    // MARK: - Authentication (Optional)
    
    func signIn(email: String, password: String) async throws {
        try await supabase.auth.signIn(email: email, password: password)
    }
    
    func signUp(email: String, password: String) async throws {
        try await supabase.auth.signUp(email: email, password: password)
    }
    
    func signOut() async throws {
        try await supabase.auth.signOut()
    }
    
    func getCurrentUser() async throws -> User? {
        return try await supabase.auth.session.user
    }
    
    // MARK: - Real-time Updates (Optional)
    
    func subscribeToBillUpdates(billId: UUID, completion: @escaping (Bill) -> Void) {
        // Note: Real-time functionality requires the Realtime module
        // This is a simplified version that can be enhanced based on your Supabase Swift SDK version
        Task {
            do {
                // For now, we'll implement a simple polling mechanism
                // You can enhance this with proper real-time subscriptions later
                let bill = try await self.loadBill(id: billId)
                await MainActor.run {
                    completion(bill)
                }
            } catch {
                print("Error in bill subscription: \(error)")
            }
        }
    }
    
    // MARK: - Utility Methods
    
    func clearError() {
        error = nil
    }
} 