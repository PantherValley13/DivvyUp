import SwiftUI

struct SplitResultView: View {
    @EnvironmentObject private var billViewModel: BillViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacing) {
                // Summary Card
                ContentCard(title: "Bill Summary", icon: "doc.text") {
                    VStack(spacing: Theme.spacing) {
                        HStack {
                            Text("Subtotal")
                            Spacer()
                            Text(billViewModel.formatCurrency(billViewModel.bill.subtotal))
                        }
                        
                        if billViewModel.bill.taxAmount > 0 {
                            HStack {
                                Text("Tax (\(Int(billViewModel.bill.taxAmount))%)")
                                Spacer()
                                Text(billViewModel.formatCurrency(billViewModel.bill.taxTotal))
                            }
                        }
                        
                        if billViewModel.bill.tipAmount > 0 {
                            HStack {
                                Text("Tip (\(Int(billViewModel.bill.tipAmount))%)")
                                Spacer()
                                Text(billViewModel.formatCurrency(billViewModel.bill.tipTotal))
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Total")
                                .font(.headline)
                            Spacer()
                            Text(billViewModel.formatCurrency(billViewModel.bill.finalTotal))
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
                            ForEach(billViewModel.bill.items.filter { $0.assignedTo == participant.id }) { item in
                                HStack {
                                    Text(item.name)
                                        .font(.subheadline)
                                    Spacer()
                                    Text(billViewModel.formatCurrency(item.price))
                                        .font(.subheadline)
                                }
                            }
                            
                            if !billViewModel.bill.items.filter({ $0.assignedTo == participant.id }).isEmpty {
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
                        }
                    }
                }
                
                // Action Buttons
                VStack(spacing: Theme.spacing) {
                    Button {
                        // Save bill to history
                        billViewModel.saveBill()
                        dismiss()
                    } label: {
                        Label("Save to History", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
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
    }
} 