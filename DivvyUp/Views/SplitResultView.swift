import SwiftUI

struct SplitResultView: View {
    let billViewModel: BillViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingCoopMode = false
    @State private var showingPaymentQR = false
    @State private var selectedParticipant: Participant?
    
    private func generateShareMessage() -> String {
        var message = "DivvyUp Split Details\n\n"
        let bill = billViewModel.bill
        message += "Total Bill: \(billViewModel.formatCurrency(bill.finalTotal))\n"
        
        // Add tax info if present
        if bill.taxAmount > 0 {
            message += "Including Tax (\(Int(bill.taxAmount))%)\n"
        }
        
        // Add tip info if present
        if bill.tipAmount > 0 {
            message += "Including Tip (\(Int(bill.tipAmount))%)\n"
        }
        
        message += "\nAmount per person:\n"
        
        // Add each participant's details
        for participant in bill.participants {
            let total = billViewModel.totalForParticipant(participant)
            message += "\n\(participant.name): \(billViewModel.formatCurrency(total))"
            
            // Add participant's items
            let items = billViewModel.itemsForParticipant(participant)
            if !items.isEmpty {
                message += "\nItems:"
                for item in items {
                    message += "\n- \(item.name): \(billViewModel.formatCurrency(item.price))"
                }
            }
            message += "\n"
        }
        
        return message
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacing) {
                // Summary Card
                ContentCard(title: "Bill Summary", icon: "doc.text") {
                    VStack(spacing: Theme.spacing) {
                        let bill = billViewModel.bill
                        
                        HStack {
                            Text("Subtotal")
                            Spacer()
                            Text(billViewModel.formatCurrency(bill.subtotal))
                        }
                        
                        if bill.taxAmount > 0 {
                            HStack {
                                Text("Tax (\(Int(bill.taxAmount))%)")
                                Spacer()
                                Text(billViewModel.formatCurrency(bill.taxTotal))
                            }
                        }
                        
                        if bill.tipAmount > 0 {
                            HStack {
                                Text("Tip (\(Int(bill.tipAmount))%)")
                                Spacer()
                                Text(billViewModel.formatCurrency(bill.tipTotal))
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Total")
                                .font(.headline)
                            Spacer()
                            Text(billViewModel.formatCurrency(bill.finalTotal))
                                .font(.headline)
                                .foregroundColor(Theme.success)
                        }
                    }
                }
                
                // Individual Splits
                ForEach(billViewModel.bill.participants) { participant in
                    ContentCard(title: participant.name, icon: "person") {
                        VStack(spacing: Theme.spacing) {
                            // Items
                            ForEach(billViewModel.itemsForParticipant(participant)) { item in
                                HStack {
                                    Text(item.name)
                                        .font(.subheadline)
                                    Spacer()
                                    Text(billViewModel.formatCurrency(item.price))
                                        .font(.subheadline)
                                }
                            }
                            
                            if !billViewModel.itemsForParticipant(participant).isEmpty {
                                Divider()
                            }
                            
                            // Total
                            HStack {
                                Text("Total Due")
                                    .font(.headline)
                                Spacer()
                                Text(billViewModel.formatCurrency(billViewModel.totalForParticipant(participant)))
                                    .font(.headline)
                                    .foregroundColor(Theme.success)
                            }
                            
                            // Payment QR Code Button
                            Button {
                                selectedParticipant = participant
                                showingPaymentQR = true
                            } label: {
                                Label("Show Payment QR", systemImage: "qrcode")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                
                // Action Buttons
                VStack(spacing: Theme.spacing) {
                    // Share Button
                    ShareLink(
                        item: generateShareMessage(),
                        subject: Text("DivvyUp Split Details"),
                        message: Text("Here's your split of the bill")
                    ) {
                        Label("Share Split Details", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    // Co-op Mode Button
                    Button {
                        showingCoopMode = true
                    } label: {
                        Label("Start Co-op Mode", systemImage: "person.2")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    // Save Button
                    Button {
                        billViewModel.saveBill()
                        dismiss()
                    } label: {
                        Label("Save to History", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .navigationTitle("Split Results")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCoopMode) {
            CoopModeView(bill: billViewModel.bill)
        }
        .sheet(item: $selectedParticipant) { participant in
            PaymentQRView(
                participant: participant,
                amount: billViewModel.totalForParticipant(participant)
            )
        }
    }
}


#Preview{
    
}
