import SwiftUI
import Combine

@MainActor
class WebCoopViewModel: ObservableObject {
    @Published var bill: Bill = Bill(items: [], participants: [], date: Date())
    @Published var availableItems: [BillItem] = []
    @Published var selectedItems: [BillItem] = []
    @Published var participantName: String = ""
    @Published var isSubmitting = false
    @Published var showingSuccessAlert = false
    @Published var showingErrorAlert = false
    @Published var errorMessage = ""
    
    var selectedSubtotal: Double {
        selectedItems.reduce(0) { $0 + $1.price }
    }
    
    var selectedTax: Double {
        (selectedSubtotal * bill.taxAmount) / 100
    }
    
    var selectedTip: Double {
        (selectedSubtotal * bill.tipAmount) / 100
    }
    
    var selectedTotal: Double {
        selectedSubtotal + selectedTax + selectedTip
    }
    
    func loadSession(id: String) async {
        do {
            // In a real app, you would:
            // 1. Make an API call to fetch the session data
            // 2. Update the bill and available items
            
            // For now, we'll use sample data
            let items = [
                BillItem(name: "Burger", price: 12.99),
                BillItem(name: "Fries", price: 4.99),
                BillItem(name: "Soda", price: 2.99),
                BillItem(name: "Salad", price: 8.99)
            ]
            
            await MainActor.run {
                self.bill = Bill(
                    items: items,
                    participants: [],
                    taxAmount: 8.0,
                    tipAmount: 15.0,
                    date: Date()
                )
                self.availableItems = items
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load session: \(error.localizedDescription)"
                self.showingErrorAlert = true
            }
        }
    }
    
    func toggleItem(_ item: BillItem) {
        if selectedItems.contains(item) {
            selectedItems.removeAll { $0.id == item.id }
        } else {
            selectedItems.append(item)
        }
    }
    
    func submitSelection() async {
        guard !participantName.isEmpty && !selectedItems.isEmpty else { return }
        
        isSubmitting = true
        
        do {
            // In a real app, you would:
            // 1. Create a new participant with the entered name
            // 2. Submit the selected items to your backend
            // 3. Update the session state
            
            // Simulate network delay
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            await MainActor.run {
                self.showingSuccessAlert = true
                self.isSubmitting = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to submit selection: \(error.localizedDescription)"
                self.showingErrorAlert = true
                self.isSubmitting = false
            }
        }
    }
    
    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
} 
