import SwiftUI
import VisionKit
import Vision

struct BillScannerView: View {
    @EnvironmentObject private var billViewModel: BillViewModel
    @State private var showingScanner = false
    @State private var showingAssignment = false
    @State private var showingTaxTip = false
    
    var body: some View {
        VStack {
            if billViewModel.bill.items.isEmpty {
                // Empty State
                EmptyStateView(
                    icon: "doc.text.viewfinder",
                    title: "No Bill Scanned",
                    message: "Scan a receipt to start splitting the bill with your friends",
                    actionTitle: "Scan Receipt"
                ) {
                    showingScanner = true
                }
                .padding()
            } else {
                // Bill Preview
                ScrollView {
                    VStack(spacing: Theme.spacing) {
                        // Items Section
                        ContentCard(title: "Items", icon: "list.bullet") {
                            ForEach(billViewModel.bill.items) { item in
                                HStack {
                                    Text(item.name)
                                        .font(.subheadline)
                                    
                                    Spacer()
                                    
                                    Text("$\(item.price, specifier: "%.2f")")
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundColor(Theme.success)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        
                        // Tax & Tip Section
                        if showingTaxTip {
                            ContentCard(title: "Tax & Tip", icon: "percent") {
                                VStack(spacing: Theme.spacing) {
                                    HStack {
                                        Text("Tax")
                                        Spacer()
                                        TextField("Tax %", value: $billViewModel.bill.taxAmount, format: .number)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 100)
                                            .keyboardType(.decimalPad)
                                    }
                                    
                                    HStack {
                                        Text("Tip")
                                        Spacer()
                                        TextField("Tip %", value: $billViewModel.bill.tipAmount, format: .number)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 100)
                                            .keyboardType(.decimalPad)
                                    }
                                    
                                    Divider()
                                    
                                    HStack {
                                        Text("Total")
                                            .font(.headline)
                                        Spacer()
                                        Text("$\(billViewModel.bill.finalTotal, specifier: "%.2f")")
                                            .font(.headline)
                                            .foregroundColor(Theme.success)
                                    }
                                }
                            }
                        }
                        
                        // Action Buttons
                        HStack(spacing: Theme.spacing) {
                            Button {
                                showingTaxTip.toggle()
                            } label: {
                                Label(
                                    showingTaxTip ? "Hide Tax & Tip" : "Add Tax & Tip",
                                    systemImage: "percent"
                                )
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button {
                                showingAssignment = true
                            } label: {
                                Label("Split Bill", systemImage: "person.2")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        
                        Button(role: .destructive) {
                            billViewModel.resetBill()
                        } label: {
                            Label("Start Over", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("DivvyUp")
        .toolbar {
            if !billViewModel.bill.items.isEmpty {
                Button {
                    showingScanner = true
                } label: {
                    Image(systemName: "doc.text.viewfinder")
                }
            }
        }
        .sheet(isPresented: $showingScanner) {
            ScannerView { result in
                switch result {
                case .success(let scan):
                    processTextObservations(scan)
                case .failure(let error):
                    billViewModel.handleScanningError(error)
                }
                showingScanner = false
            }
        }
        .sheet(isPresented: $showingAssignment) {
            NavigationView {
                ItemAssignmentView(bill: $billViewModel.bill)
                    .navigationTitle("Split Bill")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showingAssignment = false
                            }
                        }
                    }
            }
        }
        .alert("Scanning Error", isPresented: $billViewModel.showingScanningError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(billViewModel.scanningErrorMessage)
        }
    }
    
    private func processTextObservations(_ scan: VNDocumentCameraScan) {
        billViewModel.startScanning()
        
        // Process each page
        for pageIndex in 0..<scan.pageCount {
            let image = scan.imageOfPage(at: pageIndex)
            
            // Create a request handler
            guard let cgImage = image.cgImage else { continue }
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            // Create a text recognition request
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    billViewModel.handleScanningError(error)
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
                
                // Process each text observation
                for observation in observations {
                    billViewModel.processScanResult(observation)
                }
            }
            
            // Configure the request for optimal receipt scanning
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.minimumTextHeight = 0.01 // Detect smaller text
            request.customWords = ["TOTAL", "SUBTOTAL", "TAX", "TIP", "CASH", "CREDIT", "DEBIT", "VISA", "MASTERCARD", "AMEX"] // Common receipt words
            request.recognitionLanguages = ["en-US"] // Focus on English for better accuracy
            
            // Perform the request
            do {
                try requestHandler.perform([request])
            } catch {
                billViewModel.handleScanningError(error)
            }
        }
        
        billViewModel.finishScanning()
    }
}

// MARK: - Scanner View
struct ScannerView: UIViewControllerRepresentable {
    let completionHandler: (Result<VNDocumentCameraScan, Error>) -> Void
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let viewController = VNDocumentCameraViewController()
        viewController.delegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(completionHandler: completionHandler)
    }
    
    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let completionHandler: (Result<VNDocumentCameraScan, Error>) -> Void
        
        init(completionHandler: @escaping (Result<VNDocumentCameraScan, Error>) -> Void) {
            self.completionHandler = completionHandler
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            completionHandler(.success(scan))
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            completionHandler(.failure(error))
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            completionHandler(.failure(CancellationError()))
        }
    }
} 