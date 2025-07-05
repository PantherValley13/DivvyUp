import SwiftUI
import UniformTypeIdentifiers

// MARK: - Item Assignment View
struct ItemAssignmentView: View {
    @EnvironmentObject private var billViewModel: BillViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var draggedItem: BillItem?
    @State private var showingAddParticipant = false
    @State private var newParticipantName = ""
    @State private var selectedColorIndex = 0
    @State private var showingSplitResults = false
    
    private let participantColors: [Color] = [
        Color(.systemBlue),
        Color(.systemGreen),
        Color(.systemOrange),
        Color(.systemPurple),
        Color(.systemPink),
        Color(.systemRed),
        Color(.systemYellow),
        Color(.systemTeal),
        Color(.systemIndigo),
        Color(.systemGray)
    ]
    
    // MARK: - Computed Properties
    
    private var unassignedItems: [BillItem] {
        billViewModel.bill.items.filter { $0.assignedTo == nil }
    }
    
    // MARK: - Helper Methods
    
    private func itemsForParticipant(_ participant: Participant) -> [BillItem] {
        billViewModel.bill.items.filter { $0.assignedTo == participant.id }
    }
    
    private func participantName(for id: UUID) -> String {
        billViewModel.bill.participants.first { $0.id == id }?.name ?? "Unknown"
    }
    
    private func totalForParticipant(_ participant: Participant) -> Double {
        billViewModel.bill.totalForParticipant(participant)
    }
    
    private func removeParticipant(_ participant: Participant) {
        // Unassign items before removing participant
        for index in billViewModel.bill.items.indices {
            if billViewModel.bill.items[index].assignedTo == participant.id {
                billViewModel.bill.items[index].assignedTo = nil
            }
        }
        billViewModel.bill.participants.removeAll { $0.id == participant.id }
    }
    
    private func colorNameForIndex(_ index: Int) -> String {
        switch index {
        case 0: return "blue"
        case 1: return "green"
        case 2: return "orange"
        case 3: return "purple"
        case 4: return "pink"
        case 5: return "red"
        case 6: return "yellow"
        case 7: return "teal"
        case 8: return "indigo"
        case 9: return "gray"
        default: return "blue"
        }
    }
    
    private func addParticipant() {
        guard !newParticipantName.isEmpty else { return }
        
        let colorName = colorNameForIndex(selectedColorIndex)
        let participant = Participant(name: newParticipantName, colorName: colorName)
        
        withAnimation {
            billViewModel.bill.participants.append(participant)
        }
        
        // Reset form
        newParticipantName = ""
        selectedColorIndex = 0
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.spacing) {
                    participantsSection
                    
                    // Tax and Tip Section
                    ContentCard(title: "Tax & Tip", icon: "percent") {
                        VStack(spacing: Theme.spacing) {
                            HStack {
                                Text("Tax")
                                Spacer()
                                TextField("Tax %", value: Binding(
                                    get: { billViewModel.bill.taxAmount },
                                    set: { billViewModel.updateTaxAmount($0) }
                                ), format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                Text("%")
                            }
                            
                            HStack {
                                Text("Tip")
                                Spacer()
                                TextField("Tip %", value: Binding(
                                    get: { billViewModel.bill.tipAmount },
                                    set: { billViewModel.updateTipAmount($0) }
                                ), format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                Text("%")
                            }
                        }
                    }
                    
                    // Items Section
                    ContentCard(title: "Items", icon: "list.bullet") {
                        ForEach(billViewModel.bill.items) { item in
                            itemRow(item)
                        }
                    }
                    
                    // Split Button
                    Button {
                        if billViewModel.canSplit {
                            billViewModel.splitBill()
                            dismiss()
                        } else {
                            billViewModel.showingSplitError = true
                        }
                    } label: {
                        if billViewModel.canSplit {
                            Label("Split Bill", systemImage: "arrow.triangle.branch")
                                .frame(maxWidth: .infinity)
                        } else {
                            Label("Cannot Split Yet", systemImage: "exclamationmark.triangle")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!billViewModel.canSplit)
                }
                .padding()
            }
            .navigationTitle("Assign Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Cannot Split Bill", isPresented: $billViewModel.showingSplitError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(billViewModel.splitError ?? "Unknown error")
            }
            .sheet(isPresented: $showingAddParticipant, onDismiss: {
                // Reset form on dismiss
                newParticipantName = ""
                selectedColorIndex = 0
            }) {
                addParticipantSheet
            }
        }
    }
    
    // MARK: - View Components
    
    private var participantsSection: some View {
        VStack {
            // Participant list
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.spacing) {
                    ForEach(billViewModel.bill.participants) { participant in
                        participantCard(participant)
                    }
                    
                    // Add participant button
                    Button(action: { showingAddParticipant = true }) {
                        VStack(spacing: 8) {
                            Image(systemName: "person.badge.plus")
                                .font(.title2)
                            Text("Add")
                                .font(.caption)
                        }
                        .frame(width: 80, height: 100)
                        .background(Theme.secondary)
                        .cornerRadius(Theme.cornerRadius)
                    }
                }
                .padding(.horizontal, 4)
            }
            
            if billViewModel.bill.participants.isEmpty {
                EmptyStateView(
                    icon: "person.2",
                    title: "No Participants",
                    message: "Add participants to start splitting the bill",
                    actionTitle: "Add Participant"
                ) {
                    showingAddParticipant = true
                }
            }
        }
    }
    
    private var unassignedItemsSection: some View {
        VStack(spacing: Theme.spacing) {
            ForEach(unassignedItems) { item in
                itemRow(item)
                    .onDrag {
                        draggedItem = item
                        return NSItemProvider(object: item.id.uuidString as NSString)
                    }
            }
        }
    }
    
    private func participantCard(_ participant: Participant) -> some View {
        VStack(spacing: 8) {
            Circle()
                .fill(participant.color)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(participant.name.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            Text(participant.name)
                .font(.caption)
                .lineLimit(1)
            
            Text("$\(totalForParticipant(participant), specifier: "%.2f")")
                .font(.caption2)
                .bold()
                .foregroundColor(Theme.success)
        }
        .frame(width: 80, height: 100)
        .background(Color(.systemBackground))
        .cornerRadius(Theme.cornerRadius)
        .shadow(color: participant.color.opacity(0.3), radius: 5, x: 0, y: 2)
        .contextMenu {
            Button(role: .destructive) {
                withAnimation {
                    removeParticipant(participant)
                }
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }
    
    private func participantItemsSection(_ participant: Participant) -> some View {
        VStack(spacing: Theme.spacing) {
            ForEach(itemsForParticipant(participant)) { item in
                itemRow(item)
                    .onDrag {
                        draggedItem = item
                        return NSItemProvider(object: item.id.uuidString as NSString)
                    }
            }
        }
    }
    
    private func itemRow(_ item: BillItem) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.headline)
                Text(billViewModel.formatCurrency(item.price))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            AssignmentMenu(item: item)
        }
        .padding(.vertical, 4)
        .id("\(item.id)-\(item.assignedTo?.uuidString ?? "none")") // Force view refresh when assignment changes
    }
    
    private var summarySection: some View {
        VStack(spacing: Theme.spacing) {
            ForEach(billViewModel.bill.participants) { participant in
                HStack {
                    Circle()
                        .fill(participant.color)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text(participant.name.prefix(1).uppercased())
                                .font(.caption2)
                                .foregroundColor(.white)
                        )
                    
                    Text(participant.name)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("$\(totalForParticipant(participant), specifier: "%.2f")")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(Theme.success)
                }
            }
            
            Divider()
                .padding(.vertical, 8)
            
            HStack {
                Text("Total")
                    .font(.headline)
                
                Spacer()
                
                Text("$\(billViewModel.bill.subtotal, specifier: "%.2f")")
                    .font(.headline)
                    .bold()
                    .foregroundColor(Theme.success)
            }
        }
    }
    
    private var addParticipantSheet: some View {
        NavigationView {
            VStack(spacing: Theme.spacing) {
                TextField("Participant Name", text: $newParticipantName)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                Text("Choose Color")
                    .font(.headline)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                    ForEach(participantColors.indices, id: \.self) { index in
                        Circle()
                            .fill(participantColors[index])
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: selectedColorIndex == index ? 3 : 0)
                            )
                            .shadow(radius: selectedColorIndex == index ? 4 : 0)
                            .onTapGesture {
                                selectedColorIndex = index
                            }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Add Participant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingAddParticipant = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addParticipant()
                        showingAddParticipant = false
                    }
                    .disabled(newParticipantName.isEmpty)
                }
            }
        }
    }
}

// MARK: - Drop Delegate
struct ParticipantDropDelegate: DropDelegate {
    @Binding var bill: Bill
    let participant: Participant
    @Binding var draggedItem: BillItem?
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedItem = draggedItem else { return false }
        
        withAnimation {
            if let index = bill.items.firstIndex(where: { $0.id == draggedItem.id }) {
                // If item was already assigned to this participant, unassign it
                if bill.items[index].assignedTo == participant.id {
                    bill.items[index].assignedTo = nil
                } else {
                    // Assign item to this participant
                    bill.items[index].assignedTo = participant.id
                }
            }
        }
        
        return true
    }
    
    func dropEntered(info: DropInfo) {
        // Add visual feedback if needed
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

struct ParticipantRow: View {
    let participant: Participant
    let items: [BillItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(participant.name)
                .font(.headline)
            
            if items.isEmpty {
                Text("No items assigned")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(items) { item in
                    Text(item.name)
                        .font(.subheadline)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddParticipantView: View {
    @Binding var isPresented: Bool
    @Binding var participantName: String
    let onAdd: (String) -> Void
    
    var body: some View {
        Form {
            TextField("Participant Name", text: $participantName)
        }
        .navigationTitle("Add Participant")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    isPresented = false
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    guard !participantName.isEmpty else { return }
                    onAdd(participantName)
                    isPresented = false
                }
                .disabled(participantName.isEmpty)
            }
        }
    }
}

struct AssignmentMenu: View {
    let item: BillItem
    @EnvironmentObject private var billViewModel: BillViewModel
    
    var body: some View {
        Menu {
            ForEach(billViewModel.bill.participants) { participant in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        billViewModel.assignItem(item, to: participant)
                    }
                } label: {
                    if item.assignedTo == participant.id {
                        Label(participant.name, systemImage: "checkmark")
                    } else {
                        Text(participant.name)
                    }
                }
            }
            
            if item.assignedTo != nil {
                Divider()
                Button(role: .destructive) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        billViewModel.assignItem(item, to: nil)
                    }
                } label: {
                    Label("Unassign", systemImage: "person.slash")
                }
            }
        } label: {
            Group {
                if let assignedTo = item.assignedTo,
                   let participant = billViewModel.bill.participants.first(where: { $0.id == assignedTo }) {
                    ParticipantBadge(participant: participant)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.secondary)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .id("\(item.id)-\(item.assignedTo?.uuidString ?? "none")-menu") // Force menu button refresh
        }
    }
}


 
#Preview {

}

