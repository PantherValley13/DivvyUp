import SwiftUI
import CoreImage.CIFilterBuiltins

struct PaymentQRView: View {
    let participant: Participant
    let amount: Double
    @EnvironmentObject private var billViewModel: BillViewModel
    @Environment(\.dismiss) private var dismiss
    @AppStorage("paymentUsername") private var paymentUsername = ""
    @State private var selectedService = PaymentService.venmo
    @State private var showingUsernamePrompt = false
    
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.spacing) {
                    // Payment Info Card
                    ContentCard(title: "Payment Details", icon: "dollarsign.circle") {
                        VStack(spacing: Theme.spacing) {
                            Text(participant.name)
                                .font(.headline)
                            
                            Text(billViewModel.formatCurrency(amount))
                                .font(.title)
                                .foregroundColor(Theme.success)
                            
                            Picker("Payment Service", selection: $selectedService) {
                                ForEach(PaymentService.allCases) { service in
                                    Label(service.displayName, systemImage: service.iconName)
                                        .tag(service)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.vertical)
                        }
                    }
                    
                    // QR Code Card
                    if !paymentUsername.isEmpty {
                        ContentCard(title: "Scan to Pay", icon: "qrcode") {
                            VStack(spacing: Theme.spacing) {
                                if let qrCode = generateQRCode(for: selectedService.paymentURL(username: paymentUsername, amount: amount)) {
                                    Image(uiImage: qrCode)
                                        .interpolation(.none)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 200, height: 200)
                                }
                                
                                Text("Scan with your camera app to open \(selectedService.displayName)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                ShareLink(
                                    item: selectedService.paymentURL(username: paymentUsername, amount: amount)
                                ) {
                                    Label("Share Payment Link", systemImage: "square.and.arrow.up")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.vertical)
                        }
                    } else {
                        ContentCard(title: "Set Up Payments", icon: "person.badge.key") {
                            VStack(spacing: Theme.spacing) {
                                Text("Set up your payment username to generate QR codes")
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.secondary)
                                
                                Button {
                                    showingUsernamePrompt = true
                                } label: {
                                    Label("Set Payment Username", systemImage: "plus.circle")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Payment QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !paymentUsername.isEmpty {
                        Button {
                            showingUsernamePrompt = true
                        } label: {
                            Label("Edit Username", systemImage: "pencil")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Payment Username", isPresented: $showingUsernamePrompt) {
                TextField("Username", text: $paymentUsername)
                Button("Cancel", role: .cancel) { }
                Button("Save") { }
            } message: {
                Text("Enter your username for payment services (without the @ symbol)")
            }
        }
    }
    
    private func generateQRCode(for url: URL) -> UIImage? {
        filter.message = Data(url.absoluteString.utf8)
        
        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }
        return nil
    }
}

enum PaymentService: String, CaseIterable, Identifiable {
    case venmo
    case cashApp
    case paypal
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .venmo: return "Venmo"
        case .cashApp: return "Cash App"
        case .paypal: return "PayPal"
        }
    }
    
    var iconName: String {
        switch self {
        case .venmo: return "dollarsign.circle"
        case .cashApp: return "dollarsign.square"
        case .paypal: return "creditcard"
        }
    }
    
    func paymentURL(username: String, amount: Double) -> URL {
        let encodedUsername = username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? username
        let amountString = String(format: "%.2f", amount)
        
        switch self {
        case .venmo:
            return URL(string: "venmo://paycharge?txn=pay&recipients=\(encodedUsername)&amount=\(amountString)")!
        case .cashApp:
            return URL(string: "https://cash.app/\(encodedUsername)/\(amountString)")!
        case .paypal:
            return URL(string: "https://paypal.me/\(encodedUsername)/\(amountString)")!
        }
    }
} 