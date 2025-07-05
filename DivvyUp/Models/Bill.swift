import Foundation

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
        items.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
    }
    
    var taxTotal: Double {
        subtotal * (taxAmount / 100.0)
    }
    
    var tipTotal: Double {
        subtotal * (tipAmount / 100.0)
    }
    
    var finalTotal: Double {
        subtotal + taxTotal + tipTotal
    }
    
    func totalForParticipant(_ participant: Participant) -> Double {
        let participantItems = items.filter { $0.assignedTo == participant.id }
        let itemsTotal = participantItems.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
        
        // Guard against division by zero
        guard subtotal > 0 else { return itemsTotal }
        
        // Calculate proportional share of tax and tip
        let proportion = itemsTotal / subtotal
        let taxShare = proportion * taxTotal
        let tipShare = proportion * tipTotal
        
        return itemsTotal + taxShare + tipShare
    }
} 