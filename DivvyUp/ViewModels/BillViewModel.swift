import SwiftUI
import VisionKit
import Vision
import Combine

class BillViewModel: ObservableObject {
    @Published var bill = Bill()
    @Published var isScanning = false
    @Published var scanningProgress: Double = 0
    @Published var showingScanningError = false
    @Published var scanningErrorMessage = ""
    @Published var settings = AppSettings()
    @Published var savedBills: [Bill] = []
    
    private let storageService = StorageService.shared
    
    init() {
        loadSettings()
        loadSavedBills()
    }
    
    // MARK: - Settings Management
    
    func loadSettings() {
        settings = storageService.loadSettings()
        
        // Apply default settings to new bill
        bill.taxAmount = settings.defaultTaxPercentage
        bill.tipAmount = settings.defaultTipPercentage
        
        // Add default participants if bill is new
        if bill.participants.isEmpty {
            bill.participants = settings.defaultParticipants
        }
    }
    
    func saveSettings() {
        storageService.saveSettings(settings)
    }
    
    // MARK: - Bill History
    
    func loadSavedBills() {
        savedBills = storageService.loadBills()
    }
    
    func saveBill() {
        storageService.saveBill(bill)
        loadSavedBills() // Refresh the list
    }
    
    func deleteBill(at index: Int) {
        storageService.deleteBill(at: index)
        loadSavedBills() // Refresh the list
    }
    
    // MARK: - Scanning Methods
    
    func startScanning() {
        isScanning = true
        scanningProgress = 0
    }
    
    func processScanResult(_ result: VNRecognizedTextObservation) {
        // Update progress
        scanningProgress += 0.1
        
        guard let text = result.topCandidates(1).first?.string else { return }
        
        // Process the recognized text to extract items and prices
        let lines = text.components(separatedBy: .newlines)
        var potentialTotal: Double?
        
        for line in lines {
            // Check for total line
            if line.lowercased().contains("total") && !line.lowercased().contains("subtotal") {
                if let total = extractPrice(from: line) {
                    potentialTotal = total
                }
            }
            
            if let item = parseItemFromLine(line) {
                // Validate price is reasonable (not too high relative to potential total)
                if let total = potentialTotal {
                    if item.price > total {
                        // Skip items with prices higher than total
                        continue
                    }
                }
                
                // Skip items with unreasonably high prices (configurable threshold)
                if item.price > 1000 {
                    continue
                }
                
                DispatchQueue.main.async {
                    self.bill.items.append(item)
                }
            }
        }
    }
    
    private func extractPrice(from line: String) -> Double? {
        // Match price patterns with optional currency symbols and thousands separators
        let pricePattern = "\\$?([\\d,]+\\.?\\d{0,2})"
        
        guard let regex = try? NSRegularExpression(pattern: pricePattern, options: []),
              let match = regex.firstMatch(in: line, options: [], range: NSRange(line.startIndex..., in: line)),
              let priceRange = Range(match.range(at: 1), in: line) else {
            return nil
        }
        
        let priceString = String(line[priceRange])
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        return Double(priceString)
    }
    
    func finishScanning() {
        isScanning = false
        scanningProgress = 1.0
        
        // Apply default tax and tip if enabled
        bill.taxAmount = settings.defaultTaxPercentage
        bill.tipAmount = settings.defaultTipPercentage
        
        // Auto-save if enabled
        if settings.saveHistory {
            saveBill()
        }
    }
    
    func handleScanningError(_ error: Error) {
        isScanning = false
        showingScanningError = true
        scanningErrorMessage = error.localizedDescription
    }
    
    // MARK: - Helper Methods
    
    private func parseItemFromLine(_ line: String) -> BillItem? {
        // Skip lines that are likely headers or footers
        let lowercaseLine = line.lowercased()
        let skipWords = ["total", "subtotal", "tax", "tip", "card", "cash", "change", "balance", "due", "paid", "payment", "thank", "welcome", "order", "table", "server", "date", "time"]
        if skipWords.contains(where: { lowercaseLine.contains($0) }) {
            return nil
        }
        
        // More flexible regex pattern to match various receipt formats
        let pattern = "(?:(?:(\\d+)\\s*(?:x|@)\\s*)?([\\w\\s\\-&'.]+)\\s+\\$?([\\d,]+(?:\\.\\d{2})?))|(?:\\$?([\\d,]+(?:\\.\\d{2})?)\\s+([\\w\\s\\-&'.]+))"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        
        let nsRange = NSRange(line.startIndex..., in: line)
        guard let match = regex.firstMatch(in: line, options: [], range: nsRange) else {
            return nil
        }
        
        // Try both formats (price at end or beginning)
        let ranges = (1...5).map { match.range(at: $0) }
        
        func cleanPrice(_ price: String) -> Double {
            let cleaned = price.replacingOccurrences(of: ",", with: "")
            if let price = Double(cleaned) {
                // Round to 2 decimal places to avoid floating point issues
                return round(price * 100) / 100
            }
            return 0
        }
        
        // Format 1: [Quantity] Item Price
        if ranges[2].location != NSNotFound {
            let quantity = ranges[0].location != NSNotFound ? Range(ranges[0], in: line).map { String(line[$0]) } : nil
            let nameRange = Range(ranges[1], in: line)!
            let priceRange = Range(ranges[2], in: line)!
            
            let name = String(line[nameRange]).trimmingCharacters(in: .whitespaces)
            var price = cleanPrice(String(line[priceRange]))
            
            if let qty = quantity, let qtyNum = Double(qty), qtyNum > 0 {
                price = price / qtyNum
            }
            
            return price > 0 ? BillItem(name: name, price: price) : nil
        }
        // Format 2: Price Item
        else if ranges[3].location != NSNotFound {
            let priceRange = Range(ranges[3], in: line)!
            let nameRange = Range(ranges[4], in: line)!
            
            let name = String(line[nameRange]).trimmingCharacters(in: .whitespaces)
            let price = cleanPrice(String(line[priceRange]))
            
            return price > 0 ? BillItem(name: name, price: price) : nil
        }
        
        return nil
    }
    
    // MARK: - Bill Management
    
    func addParticipant(_ participant: Participant) {
        bill.participants.append(participant)
    }
    
    func removeParticipant(_ participant: Participant) {
        // Unassign items
        for index in bill.items.indices {
            if bill.items[index].assignedTo == participant.id {
                bill.items[index].assignedTo = nil
            }
        }
        
        // Remove participant
        bill.participants.removeAll { $0.id == participant.id }
    }
    
    func assignItem(_ item: BillItem, to participant: Participant) {
        if let index = bill.items.firstIndex(where: { $0.id == item.id }) {
            bill.items[index].assignedTo = participant.id
        }
    }
    
    func unassignItem(_ item: BillItem) {
        if let index = bill.items.firstIndex(where: { $0.id == item.id }) {
            bill.items[index].assignedTo = nil
        }
    }
    
    func updateTax(_ tax: Double) {
        bill.taxAmount = tax
    }
    
    func updateTip(_ tip: Double) {
        bill.tipAmount = tip
    }
    
    // MARK: - Calculations
    
    func totalForParticipant(_ participant: Participant) -> Double {
        let assignedItems = bill.items.filter { $0.assignedTo == participant.id }
        let itemsTotal = assignedItems.reduce(0) { $0 + $1.price }
        
        // Calculate share of tax and tip
        let taxShare = (itemsTotal / bill.subtotal) * bill.taxAmount
        let tipShare = (itemsTotal / bill.subtotal) * bill.tipAmount
        
        let total = itemsTotal + taxShare + tipShare
        
        // Apply rounding if configured
        switch settings.roundingMode {
        case .up:
            return ceil(total)
        case .down:
            return floor(total)
        case .nearest:
            return round(total)
        case .none:
            return total
        }
    }
    
    func resetBill() {
        bill = Bill()
        scanningProgress = 0
        
        // Apply default settings to new bill
        loadSettings()
    }
    
    // MARK: - Currency Formatting
    
    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = settings.currencyCode
        
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
} 