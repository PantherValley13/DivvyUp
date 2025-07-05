import SwiftUI
import CoreImage.CIFilterBuiltins
import Combine

@MainActor
class CoopModeViewModel: ObservableObject {
    @Published var participants: [Participant] = []
    @Published var participantItems: [UUID: [BillItem]] = [:]
    @Published var qrCode: UIImage?
    @Published var coopURL: URL?
    @Published var canFinalize = false
    
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    func setupCoopSession(for bill: Bill) {
        participants = bill.participants
        
        // Generate a unique session ID
        let sessionId = UUID().uuidString
        
        // Create the co-op URL (you'll need to replace this with your actual web app URL)
        let urlString = "https://divvyup.app/coop/\(sessionId)"
        coopURL = URL(string: urlString)
        
        // Generate QR code
        generateQRCode(from: urlString)
        
        // In a real app, you would:
        // 1. Create a session on your backend
        // 2. Store the bill and participant information
        // 3. Set up real-time updates for participant submissions
        
        // For now, we'll simulate some submissions
        simulateParticipantSubmissions()
    }
    
    private func generateQRCode(from string: String) {
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                qrCode = UIImage(cgImage: cgimg)
            }
        }
    }
    
    func finalizeSplit() {
        // In a real app, you would:
        // 1. Confirm all submissions are complete
        // 2. Update the bill with final assignments
        // 3. Close the co-op session
        // 4. Navigate back to the split view
    }
    
    // MARK: - Simulation Methods (Remove in production)
    
    private func simulateParticipantSubmissions() {
        // Simulate participants submitting their items over time
        for participant in participants {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2...5)) {
                self.simulateSubmission(for: participant)
            }
        }
    }
    
    private func simulateSubmission(for participant: Participant) {
        // Simulate a participant selecting some items
        let items = [
            BillItem(name: "Simulated Item 1", price: 10.99),
            BillItem(name: "Simulated Item 2", price: 15.99)
        ]
        
        DispatchQueue.main.async {
            self.participantItems[participant.id] = items
            self.checkCanFinalize()
        }
    }
    
    private func checkCanFinalize() {
        // Can finalize when all participants have submitted their items
        canFinalize = participants.allSatisfy { participant in
            participantItems[participant.id] != nil
        }
    }
} 