import Foundation

class StorageService {
    static let shared = StorageService()
    
    private let billsKey = "saved_bills"
    private let settingsKey = "app_settings"
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Bills
    
    func saveBill(_ bill: Bill) {
        var savedBills = loadBills()
        savedBills.append(bill)
        
        if let encoded = try? JSONEncoder().encode(savedBills) {
            userDefaults.set(encoded, forKey: billsKey)
        }
    }
    
    func loadBills() -> [Bill] {
        guard let data = userDefaults.data(forKey: billsKey),
              let bills = try? JSONDecoder().decode([Bill].self, from: data) else {
            return []
        }
        return bills
    }
    
    func deleteBill(at index: Int) {
        var savedBills = loadBills()
        guard index < savedBills.count else { return }
        savedBills.remove(at: index)
        
        if let encoded = try? JSONEncoder().encode(savedBills) {
            userDefaults.set(encoded, forKey: billsKey)
        }
    }
    
    // MARK: - Settings
    
    func saveSettings(_ settings: AppSettings) {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: settingsKey)
        }
    }
    
    func loadSettings() -> AppSettings {
        guard let data = userDefaults.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return settings
    }
} 