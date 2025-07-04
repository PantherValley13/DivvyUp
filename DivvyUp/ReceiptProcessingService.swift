import Foundation
import UIKit
import Vision
import VisionKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Combine

// MARK: - Receipt Processing Pipeline
@MainActor
class ReceiptProcessingService: ObservableObject {
    
    // MARK: - Processing States
    enum ProcessingStep {
        case preprocessing
        case textDetection
        case itemExtraction
        case aiFallback
        case completed
    }
    
    @Published var currentStep: ProcessingStep = .preprocessing
    @Published var processingProgress: Double = 0.0
    @Published var isProcessing: Bool = false
    @Published var extractedItems: [BillItem] = []
    @Published var processingError: Error?
    
    // MARK: - Configuration
    private let itemPatterns: [String] = [
        // Standard item-price patterns
        #"^([A-Za-z0-9\s\-\&\+\.\(\)]+)\s*\$?(\d+\.?\d{0,2})$"#,
        // Price on separate line
        #"^([A-Za-z0-9\s\-\&\+\.\(\)]+)\s*$\n\s*\$?(\d+\.?\d{0,2})$"#,
        // Quantity x item @ price
        #"^(\d+)\s*x?\s*([A-Za-z0-9\s\-\&\+\.\(\)]+)\s*@?\s*\$?(\d+\.?\d{0,2})$"#,
        // Item with quantity and total
        #"^([A-Za-z0-9\s\-\&\+\.\(\)]+)\s*\((\d+)\)\s*\$?(\d+\.?\d{0,2})$"#
    ]
    
    private let excludePatterns: [String] = [
        #"(?i)(subtotal|total|tax|tip|receipt|thank\s+you|server|table|check|bill)"#,
        #"(?i)(change|cash|card|credit|debit|visa|mastercard|amex)"#,
        #"(?i)(date|time|\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})"#,
        #"(?i)(phone|address|street|city|state|zip)"#
    ]
    
    // MARK: - Main Processing Pipeline
    func processReceipt(image: UIImage) async throws -> [BillItem] {
        isProcessing = true
        processingError = nil
        extractedItems = []
        processingProgress = 0.0
        
        defer { isProcessing = false }
        
        do {
            // Step 1: Preprocess Image
            currentStep = .preprocessing
            processingProgress = 0.1
            let preprocessedImage = await preprocessImage(image)
            
            // Step 2: Run VisionKit Text Detection
            currentStep = .textDetection
            processingProgress = 0.3
            let recognizedText = try await performTextRecognition(preprocessedImage)
            
            // Step 3: Extract Items/Prices using Regex Patterns
            currentStep = .itemExtraction
            processingProgress = 0.6
            let extractedItems = await extractItemsWithPatterns(recognizedText)
            
            // Step 4: Fallback to AI when structure unclear
            if extractedItems.isEmpty || extractedItems.count < 2 {
                currentStep = .aiFallback
                processingProgress = 0.8
                let aiItems = await performAIFallback(recognizedText)
                self.extractedItems = aiItems
            } else {
                self.extractedItems = extractedItems
            }
            
            // Step 5: Completion
            currentStep = .completed
            processingProgress = 1.0
            
            return self.extractedItems
            
        } catch {
            processingError = error
            throw error
        }
    }
    
    // MARK: - Step 1: Image Preprocessing
    private func preprocessImage(_ image: UIImage) async -> UIImage {
        return await withCheckedContinuation { continuation in
            guard let ciImage = CIImage(image: image) else {
                continuation.resume(returning: image)
                return
            }
            
            let context = CIContext()
            var processedImage = ciImage
            
            // 1. Deskew/Perspective Correction
            processedImage = applyPerspectiveCorrection(processedImage)
            
            // 2. Enhance Contrast
            let contrastFilter = CIFilter.colorControls()
            contrastFilter.inputImage = processedImage
            contrastFilter.contrast = 1.2
            contrastFilter.brightness = 0.1
            contrastFilter.saturation = 0.8
            
            if let contrastOutput = contrastFilter.outputImage {
                processedImage = contrastOutput
            }
            
            // 3. Sharpen for better OCR
            let sharpenFilter = CIFilter.sharpenLuminance()
            sharpenFilter.inputImage = processedImage
            sharpenFilter.sharpness = 0.7
            
            if let sharpenOutput = sharpenFilter.outputImage {
                processedImage = sharpenOutput
            }
            
            // 4. Convert back to UIImage
            if let cgImage = context.createCGImage(processedImage, from: processedImage.extent) {
                let resultImage = UIImage(cgImage: cgImage)
                continuation.resume(returning: resultImage)
            } else {
                continuation.resume(returning: image)
            }
        }
    }
    
    private func applyPerspectiveCorrection(_ image: CIImage) -> CIImage {
        // Simple perspective correction using rectangle detection
        let detector = CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: [
            CIDetectorAccuracy: CIDetectorAccuracyHigh
        ])
        
        if let features = detector?.features(in: image) as? [CIRectangleFeature],
           let rectangle = features.first {
            
            let perspectiveFilter = CIFilter.perspectiveCorrection()
            perspectiveFilter.inputImage = image
            perspectiveFilter.topLeft = rectangle.topLeft
            perspectiveFilter.topRight = rectangle.topRight
            perspectiveFilter.bottomLeft = rectangle.bottomLeft
            perspectiveFilter.bottomRight = rectangle.bottomRight
            
            return perspectiveFilter.outputImage ?? image
        }
        
        return image
    }
    
    // MARK: - Step 2: VisionKit Text Detection
    private func performTextRecognition(_ image: UIImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: ReceiptProcessingError.imageProcessingFailed)
                return
            }
            
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: ReceiptProcessingError.textRecognitionFailed)
                    return
                }
                
                let recognizedLines = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                let fullText = recognizedLines.joined(separator: "\n")
                continuation.resume(returning: fullText)
            }
            
            // Configure for better receipt recognition
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    // MARK: - Step 3: Pattern-Based Item Extraction
    private func extractItemsWithPatterns(_ text: String) async -> [BillItem] {
        let lines = text.components(separatedBy: .newlines)
        var items: [BillItem] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty lines and excluded patterns
            if trimmedLine.isEmpty || shouldExcludeLine(trimmedLine) {
                continue
            }
            
            // Try each pattern
            for pattern in itemPatterns {
                if let item = extractItemWithPattern(trimmedLine, pattern: pattern) {
                    items.append(item)
                    break
                }
            }
        }
        
        return items
    }
    
    private func shouldExcludeLine(_ line: String) -> Bool {
        for pattern in excludePatterns {
            if line.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        return false
    }
    
    private func extractItemWithPattern(_ line: String, pattern: String) -> BillItem? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let range = NSRange(location: 0, length: line.utf16.count)
        
        if let match = regex.firstMatch(in: line, options: [], range: range) {
            // Extract components based on pattern groups
            var itemName = ""
            var price: Double = 0.0
            var quantity = 1
            
            // Different patterns have different group structures
            if match.numberOfRanges >= 3 {
                if let nameRange = Range(match.range(at: 1), in: line) {
                    itemName = String(line[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                if let priceRange = Range(match.range(at: 2), in: line) {
                    let priceString = String(line[priceRange])
                    price = Double(priceString) ?? 0.0
                }
                
                // Check for quantity in group 3 (for quantity patterns)
                if match.numberOfRanges >= 4 {
                    if let quantityRange = Range(match.range(at: 2), in: line) {
                        quantity = Int(String(line[quantityRange])) ?? 1
                    }
                    if let priceRange = Range(match.range(at: 3), in: line) {
                        let priceString = String(line[priceRange])
                        price = Double(priceString) ?? 0.0
                    }
                }
            }
            
            if !itemName.isEmpty && price > 0 {
                return BillItem(name: itemName, price: price, quantity: quantity)
            }
        }
        
        return nil
    }
    
    // MARK: - Step 4: AI Fallback Processing
    private func performAIFallback(_ text: String) async -> [BillItem] {
        // This would integrate with an AI service like OpenAI, Claude, or Deepseek
        // For now, we'll implement a more sophisticated local parsing
        
        var items: [BillItem] = []
        
        // Use advanced natural language processing techniques
        items.append(contentsOf: extractItemsWithNLP(text))
        
        // If still no items, try fuzzy matching
        if items.isEmpty {
            items.append(contentsOf: extractItemsWithFuzzyMatching(text))
        }
        
        // TODO: Integrate with actual AI service
        // items.append(contentsOf: await callAIService(text))
        
        return items
    }
    
    private func extractItemsWithNLP(_ text: String) -> [BillItem] {
        var items: [BillItem] = []
        let lines = text.components(separatedBy: .newlines)
        
        // More flexible parsing using price detection and context
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Look for price patterns anywhere in the line
            if let price = extractPriceFromLine(trimmedLine) {
                // Get potential item name from current line or previous lines
                if let itemName = extractItemNameNearPrice(lines, currentIndex: index, priceLine: trimmedLine) {
                    items.append(BillItem(name: itemName, price: price))
                }
            }
        }
        
        return items
    }
    
    private func extractPriceFromLine(_ line: String) -> Double? {
        let pricePattern = #"\$?(\d+\.?\d{0,2})"#
        
        if let regex = try? NSRegularExpression(pattern: pricePattern),
           let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: line.utf16.count)),
           let priceRange = Range(match.range(at: 1), in: line) {
            
            let priceString = String(line[priceRange])
            let price = Double(priceString) ?? 0.0
            
            // Filter out unlikely prices (too small or too large)
            if price >= 0.50 && price <= 999.99 {
                return price
            }
        }
        
        return nil
    }
    
    private func extractItemNameNearPrice(_ lines: [String], currentIndex: Int, priceLine: String) -> String? {
        // Try to extract item name from the same line first
        let cleanedLine = priceLine.replacingOccurrences(of: #"\$?\d+\.?\d{0,2}"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanedLine.count > 2 && !shouldExcludeLine(cleanedLine) {
            return cleanedLine
        }
        
        // Look at previous lines for item name
        for i in stride(from: currentIndex - 1, through: max(0, currentIndex - 3), by: -1) {
            let previousLine = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            
            if previousLine.count > 2 && !shouldExcludeLine(previousLine) && extractPriceFromLine(previousLine) == nil {
                return previousLine
            }
        }
        
        return nil
    }
    
    private func extractItemsWithFuzzyMatching(_ text: String) -> [BillItem] {
        // Last resort: very permissive matching
        var items: [BillItem] = []
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Look for any number that could be a price
            if let regex = try? NSRegularExpression(pattern: #"(\d+\.?\d{0,2})"#),
               let match = regex.firstMatch(in: trimmed, range: NSRange(location: 0, length: trimmed.utf16.count)),
               let priceRange = Range(match.range(at: 1), in: trimmed) {
                
                let priceString = String(trimmed[priceRange])
                if let price = Double(priceString), price >= 1.0 && price <= 100.0 {
                    let itemName = trimmed.replacingOccurrences(of: priceString, with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if itemName.count > 2 {
                        items.append(BillItem(name: itemName, price: price))
                    }
                }
            }
        }
        
        return items
    }
    
    // MARK: - Utility Methods
    func clearResults() {
        extractedItems = []
        processingError = nil
        currentStep = .preprocessing
        processingProgress = 0.0
    }
}

// MARK: - Processing Errors
enum ReceiptProcessingError: LocalizedError {
    case imageProcessingFailed
    case textRecognitionFailed
    case noItemsFound
    case aiServiceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Failed to process the receipt image"
        case .textRecognitionFailed:
            return "Failed to recognize text from the receipt"
        case .noItemsFound:
            return "No items could be extracted from the receipt"
        case .aiServiceUnavailable:
            return "AI fallback service is currently unavailable"
        }
    }
}

// MARK: - Processing Statistics
struct ProcessingStats {
    let totalLinesProcessed: Int
    let itemsExtracted: Int
    let processingTime: TimeInterval
    let methodUsed: String
    let confidenceScore: Double
}

extension ReceiptProcessingService {
    func getProcessingStats() -> ProcessingStats {
        return ProcessingStats(
            totalLinesProcessed: 0, // TODO: Track this
            itemsExtracted: extractedItems.count,
            processingTime: 0, // TODO: Track this
            methodUsed: currentStep == .aiFallback ? "AI Fallback" : "Pattern Matching",
            confidenceScore: extractedItems.isEmpty ? 0.0 : 0.8 // TODO: Calculate real confidence
        )
    }
} 