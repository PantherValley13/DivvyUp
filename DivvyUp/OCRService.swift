import Foundation
import Vision
import VisionKit
import UIKit
import SwiftUI
import Combine

// MARK: - OCR Service
class OCRService: ObservableObject {
    @Published var recognizedText: String = ""
    @Published var extractedItems: [BillItem] = []
    @Published var isProcessing: Bool = false
    @Published var processingProgress: Double = 0.0
    @Published var currentProcessingStep: String = ""
    
    // Enhanced processing service
    private let receiptProcessor = ReceiptProcessingService()
    
    // Legacy regex patterns for backward compatibility
    private let priceRegex = try! NSRegularExpression(pattern: #"\$?(\d+\.?\d*)"#)
    private let itemRegex = try! NSRegularExpression(pattern: #"^([A-Za-z0-9\s\-\&\+]+)\s*\$?(\d+\.?\d*)$"#, options: .anchorsMatchLines)
    
    init() {
        // Observe the enhanced processor's progress
        receiptProcessor.$processingProgress
            .assign(to: &$processingProgress)
        
        receiptProcessor.$currentStep
            .map { step in
                switch step {
                case .preprocessing: return "Processing image..."
                case .textDetection: return "Recognizing text..."
                case .itemExtraction: return "Extracting items..."
                case .aiFallback: return "Smart analysis..."
                case .completed: return "Complete!"
                }
            }
            .assign(to: &$currentProcessingStep)
    }
    
    func processImage(_ image: UIImage) {
        Task {
            await processImageAsync(image)
        }
    }
    
    @MainActor
    private func processImageAsync(_ image: UIImage) async {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            // Use the enhanced receipt processing pipeline
            let items = try await receiptProcessor.processReceipt(image: image)
            self.extractedItems = items
            
            // Extract recognized text for display (if needed)
            if let cgImage = image.cgImage {
                let recognizedText = try await performBasicTextRecognition(cgImage)
                self.recognizedText = recognizedText
            }
            
        } catch {
            print("Failed to process receipt: \(error)")
            // Fallback to legacy processing
            await processImageLegacy(image)
        }
    }
    
    // Legacy processing method as fallback
    private func processImageLegacy(_ image: UIImage) async {
        guard let cgImage = image.cgImage else { return }
        
        do {
            let recognizedText = try await performBasicTextRecognition(cgImage)
            let items = extractItemsFromText(recognizedText)
            
            await MainActor.run {
                self.recognizedText = recognizedText
                self.extractedItems = items
            }
        } catch {
            print("Failed to perform legacy OCR: \(error)")
        }
    }
    
    private func performBasicTextRecognition(_ cgImage: CGImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                let recognizedLines = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                let fullText = recognizedLines.joined(separator: "\n")
                continuation.resume(returning: fullText)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // Legacy text recognition method (kept for backward compatibility)
    private func handleTextRecognition(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            return
        }
        
        let recognizedLines = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }
        
        recognizedText = recognizedLines.joined(separator: "\n")
        extractedItems = extractItemsFromText(recognizedText)
    }
    
    private func extractItemsFromText(_ text: String) -> [BillItem] {
        let lines = text.components(separatedBy: .newlines)
        var items: [BillItem] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines and common receipt headers/footers
            if trimmedLine.isEmpty || 
               trimmedLine.lowercased().contains("receipt") ||
               trimmedLine.lowercased().contains("total") ||
               trimmedLine.lowercased().contains("tax") ||
               trimmedLine.lowercased().contains("tip") ||
               trimmedLine.lowercased().contains("subtotal") ||
               trimmedLine.lowercased().contains("thank you") ||
               trimmedLine.count < 3 {
                continue
            }
            
            if let item = extractItemFromLine(trimmedLine) {
                items.append(item)
            }
        }
        
        return items
    }
    
    private func extractItemFromLine(_ line: String) -> BillItem? {
        // Try to match item name with price pattern
        let range = NSRange(location: 0, length: line.utf16.count)
        
        if let match = itemRegex.firstMatch(in: line, options: [], range: range) {
            let itemNameRange = Range(match.range(at: 1), in: line)
            let priceRange = Range(match.range(at: 2), in: line)
            
            if let itemNameRange = itemNameRange, let priceRange = priceRange {
                let itemName = String(line[itemNameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                let priceString = String(line[priceRange])
                
                if let price = Double(priceString), price > 0 {
                    return BillItem(name: itemName, price: price)
                }
            }
        }
        
        // Fallback: look for any price in the line
        let priceMatches = priceRegex.matches(in: line, options: [], range: range)
        if let priceMatch = priceMatches.first {
            let priceRange = Range(priceMatch.range(at: 1), in: line)
            if let priceRange = priceRange {
                let priceString = String(line[priceRange])
                if let price = Double(priceString), price > 0 {
                    // Extract item name (everything before the price)
                    let itemName = line.replacingOccurrences(of: "$\(priceString)", with: "")
                        .replacingOccurrences(of: priceString, with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if !itemName.isEmpty && itemName.count > 2 {
                        return BillItem(name: itemName, price: price)
                    }
                }
            }
        }
        
        return nil
    }
    
    func addManualItem(name: String, price: Double) {
        let item = BillItem(name: name, price: price, isManuallyAssigned: true)
        extractedItems.append(item)
    }
    
    func removeItem(at index: Int) {
        guard index < extractedItems.count else { return }
        extractedItems.remove(at: index)
    }
    
    func clearItems() {
        extractedItems.removeAll()
        recognizedText = ""
    }
}

// MARK: - Camera OCR View
struct CameraOCRView: UIViewControllerRepresentable {
    @ObservedObject var ocrService: OCRService
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: CameraOCRView
        
        init(_ parent: CameraOCRView) {
            self.parent = parent
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            // Process the first scanned page
            if scan.pageCount > 0 {
                let image = scan.imageOfPage(at: 0)
                parent.ocrService.processImage(image)
            }
            parent.dismiss()
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            print("Camera OCR failed: \(error)")
            parent.dismiss()
        }
    }
} 
 