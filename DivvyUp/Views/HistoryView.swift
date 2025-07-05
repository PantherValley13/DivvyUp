import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var billViewModel: BillViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedBill: Bill?
    
    var body: some View {
        NavigationView {
            Group {
                if billViewModel.savedBills.isEmpty {
                    EmptyStateView(
                        icon: "clock.arrow.circlepath",
                        title: "No Bill History",
                        message: "Your saved bills will appear here",
                        actionTitle: "Scan New Bill"
                    ) {
                        dismiss()
                    }
                } else {
                    List {
                        ForEach(billViewModel.savedBills.indices, id: \.self) { index in
                            let bill = billViewModel.savedBills[index]
                            BillHistoryRow(bill: bill)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedBill = bill
                                }
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { index in
                                billViewModel.deleteBill(at: index)
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedBill) { bill in
                BillDetailView(bill: bill)
            }
        }
    }
}

// MARK: - Bill History Row
struct BillHistoryRow: View {
    let bill: Bill
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date and Total
            HStack {
                Text(formattedDate)
                    .font(.headline)
                
                Spacer()
                
                Text(formattedTotal)
                    .font(.headline)
                    .foregroundColor(Theme.success)
            }
            
            // Participants
            if !bill.participants.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(bill.participants) { participant in
                            ParticipantTag(participant: participant)
                        }
                    }
                }
            }
            
            // Items Count
            Text("\(bill.items.count) items")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
    
    private var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSNumber(value: bill.finalTotal)) ?? "$\(bill.finalTotal)"
    }
}

// MARK: - Participant Tag
struct ParticipantTag: View {
    let participant: Participant
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(participant.color)
                .frame(width: 8, height: 8)
            
            Text(participant.name)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Bill Detail View
struct BillDetailView: View {
    let bill: Bill
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Items Section
                Section("Items") {
                    ForEach(bill.items) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name)
                                
                                if let assignedTo = item.assignedTo,
                                   let participant = bill.participants.first(where: { $0.id == assignedTo }) {
                                    Text("Assigned to \(participant.name)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Text("$\(item.price, specifier: "%.2f")")
                                .foregroundColor(Theme.success)
                        }
                    }
                }
                
                // Participants Section
                Section("Participants") {
                    ForEach(bill.participants) { participant in
                        HStack {
                            Circle()
                                .fill(Color(participant.colorName))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Text(participant.name.prefix(1).uppercased())
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                )
                            
                            Text(participant.name)
                            
                            Spacer()
                            
                            Text("$\(totalForParticipant(participant), specifier: "%.2f")")
                                .foregroundColor(Theme.success)
                        }
                    }
                }
                
                // Summary Section
                Section("Summary") {
                    HStack {
                        Text("Subtotal")
                        Spacer()
                        Text("$\(bill.subtotal, specifier: "%.2f")")
                    }
                    
                    HStack {
                        Text("Tax")
                        Spacer()
                        Text("$\(bill.taxAmount, specifier: "%.2f")")
                    }
                    
                    HStack {
                        Text("Tip")
                        Spacer()
                        Text("$\(bill.tipAmount, specifier: "%.2f")")
                    }
                    
                    HStack {
                        Text("Total")
                            .font(.headline)
                        Spacer()
                        Text("$\(bill.finalTotal, specifier: "%.2f")")
                            .font(.headline)
                            .foregroundColor(Theme.success)
                    }
                }
            }
            .navigationTitle("Bill Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func totalForParticipant(_ participant: Participant) -> Double {
        bill.items
            .filter { $0.assignedTo == participant.id }
            .reduce(0) { $0 + $1.price }
    }
} 