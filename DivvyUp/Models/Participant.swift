import Foundation
import SwiftUI

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
        case "blue": return Color(.systemBlue)
        case "green": return Color(.systemGreen)
        case "red": return Color(.systemRed)
        case "orange": return Color(.systemOrange)
        case "purple": return Color(.systemPurple)
        case "pink": return Color(.systemPink)
        case "teal": return Color.teal
        case "indigo": return Color(.systemIndigo)
        default: return Color(.systemBlue)
        }
    }
} 
