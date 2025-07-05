import SwiftUI

struct WebCoopView: View {
    @StateObject private var viewModel = WebCoopViewModel()
    let sessionId: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacing) {
                // Header
                ContentCard(title: "Select Your Items", icon: "cart") {
                    VStack(spacing: Theme.spacing) {
                        Text("Total Bill: \(viewModel.formatCurrency(viewModel.bill.finalTotal))")
                            .font(.headline)
                        
                        if viewModel.bill.taxAmount > 0 {
                            Text("Including \(Int(viewModel.bill.taxAmount))% Tax")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if viewModel.bill.tipAmount > 0 {
                            Text("Including \(Int(viewModel.bill.tipAmount))% Tip")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Name Input
                ContentCard(title: "Your Name", icon: "person") {
                    TextField("Enter your name", text: $viewModel.participantName)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.words)
                }
                
                // Items Selection
                ContentCard(title: "Available Items", icon: "list.bullet") {
                    VStack(spacing: Theme.spacing) {
                        ForEach(viewModel.availableItems) { item in
                            ItemSelectionRow(item: item, isSelected: viewModel.selectedItems.contains(item), formatCurrency: viewModel.formatCurrency) {
                                viewModel.toggleItem(item)
                            }
                        }
                    }
                }
                
                // Selected Items Summary
                if !viewModel.selectedItems.isEmpty {
                    ContentCard(title: "Your Selection", icon: "checkmark.circle") {
                        VStack(spacing: Theme.spacing) {
                            ForEach(viewModel.selectedItems) { item in
                                HStack {
                                    Text(item.name)
                                    Spacer()
                                    Text(viewModel.formatCurrency(item.price))
                                }
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Subtotal")
                                    .font(.headline)
                                Spacer()
                                Text(viewModel.formatCurrency(viewModel.selectedSubtotal))
                                    .font(.headline)
                            }
                            
                            if viewModel.bill.taxAmount > 0 {
                                HStack {
                                    Text("Tax")
                                    Spacer()
                                    Text(viewModel.formatCurrency(viewModel.selectedTax))
                                }
                            }
                            
                            if viewModel.bill.tipAmount > 0 {
                                HStack {
                                    Text("Tip")
                                    Spacer()
                                    Text(viewModel.formatCurrency(viewModel.selectedTip))
                                }
                            }
                            
                            HStack {
                                Text("Total")
                                    .font(.headline)
                                Spacer()
                                Text(viewModel.formatCurrency(viewModel.selectedTotal))
                                    .font(.headline)
                                    .foregroundColor(Theme.success)
                            }
                        }
                    }
                }
                
                // Submit Button
                Button {
                    Task {
                        await viewModel.submitSelection()
                    }
                } label: {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Text("Submit Selection")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isSubmitting || viewModel.participantName.isEmpty || viewModel.selectedItems.isEmpty)
                .frame(maxWidth: .infinity)
                .padding()
            }
            .padding()
        }
        .alert("Success", isPresented: $viewModel.showingSuccessAlert) {
            Button("OK") { }
        } message: {
            Text("Your selection has been submitted successfully!")
        }
        .alert("Error", isPresented: $viewModel.showingErrorAlert) {
            Button("Try Again") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .task {
            await viewModel.loadSession(id: sessionId)
        }
    }
}

struct ItemSelectionRow: View {
    let item: BillItem
    let isSelected: Bool
    let formatCurrency: (Double) -> String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.headline)
                    Text(formatCurrency(item.price))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Theme.success : .secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
} 


#Preview{
    
}
