import SwiftUI
import UniformTypeIdentifiers

// MARK: - Item Assignment View
struct ItemAssignmentView: View {
    @Binding var bill: Bill
    @State private var draggedItem: BillItem?
    @State private var showingAddParticipant = false
    @State private var newParticipantName = ""
    @State private var selectedColorIndex = 0
    @State private var showingSplitResults = false
    
    private let participantColors: [Color] = [
        .blue, .green, .orange, .purple, .pink, .red, .yellow, .mint, .teal, .indigo
    ]
    
    // MARK: - Computed Properties
    
    private var unassignedItems: [BillItem] {
        bill.items.filter { $0.assignedTo == nil }
    }
    
    // MARK: - Helper Methods
    
    private func itemsForParticipant(_ participant: Participant) -> [BillItem] {
        bill.items.filter { $0.assignedTo == participant.id }
    }
    
    private func participantName(for id: UUID) -> String {
        bill.participants.first { $0.id == id }?.name ?? "Unknown"
    }
    
    private func totalForParticipant(_ participant: Participant) -> Double {
        bill.totalForParticipant(participant)
    }
    
    private func removeParticipant(_ participant: Participant) {
        // Unassign items before removing participant
        for index in bill.items.indices {
            if bill.items[index].assignedTo == participant.id {
                bill.items[index].assignedTo = nil
            }
        }
        bill.participants.removeAll { $0.id == participant.id }
    }
    
    private func addParticipant() {
        guard !newParticipantName.isEmpty else { return }
        
        let colorName = participantColors[selectedColorIndex].description
        let participant = Participant(name: newParticipantName, colorName: colorName)
        
        withAnimation {
            bill.participants.append(participant)
        }
        
        // Reset form
        newParticipantName = ""
        selectedColorIndex = 0
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacing) {
                // Participants Section
                ContentCard(title: "Participants", icon: "person.2") {
                    participantsSection
                }
                
                // Unassigned Items Section
                if !unassignedItems.isEmpty {
                    ContentCard(title: "Unassigned Items", icon: "tray") {
                        unassignedItemsSection
                    }
                }
                
                // Assigned Items Section
                ForEach(bill.participants) { participant in
                    if !itemsForParticipant(participant).isEmpty {
                        ContentCard(
                            title: participant.name,
                            icon: "person.circle"
                        ) {
                            participantItemsSection(participant)
                        }
                    }
                }
                
                // Summary Section
                if !bill.participants.isEmpty {
                    ContentCard(title: "Summary", icon: "chart.pie") {
                        summarySection
                    }
                }
            }
            .padding()
        }
        .background(Theme.backgroundGradient)
        .sheet(isPresented: $showingAddParticipant) {
            addParticipantSheet
        }
        .navigationDestination(isPresented: $showingSplitResults) {
            SplitResultView()
        }
        .onChange(of: bill.items) { _ in
            // Check if all items are assigned
            if !unassignedItems.isEmpty && bill.participants.isEmpty {
                showingSplitResults = false
            } else if unassignedItems.isEmpty && !bill.participants.isEmpty {
                showingSplitResults = true
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Split") {
                    showingSplitResults = true
                }
                .disabled(unassignedItems.isEmpty || bill.participants.isEmpty)
            }
        }
    }
    
    // MARK: - View Components
    
    private var participantsSection: some View {
        VStack(spacing: Theme.spacing) {
            // Participant list
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.spacing) {
                    ForEach(bill.participants) { participant in
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
            
            if bill.participants.isEmpty {
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
                .fill(Color(participant.colorName))
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
        .shadow(color: Color(participant.colorName).opacity(0.3), radius: 5, x: 0, y: 2)
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
        .onDrop(of: [.text], delegate: ParticipantDropDelegate(
            bill: $bill,
            participant: participant,
            draggedItem: $draggedItem
        ))
    }
    
    private func itemRow(_ item: BillItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                
                if let assignedTo = item.assignedTo {
                    Text("Assigned to \(participantName(for: assignedTo))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("$\(item.price, specifier: "%.2f")")
                .font(.subheadline)
                .bold()
                .foregroundColor(Theme.success)
        }
        .padding()
        .background(Theme.secondary)
        .cornerRadius(Theme.cornerRadius)
    }
    
    private var summarySection: some View {
        VStack(spacing: Theme.spacing) {
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
                
                Text("$\(bill.subtotal, specifier: "%.2f")")
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


 