import SwiftUI

// MARK: - Item Assignment View
struct ItemAssignmentView: View {
    @Binding var bill: Bill
    @State private var draggedItem: BillItem?
    @State private var showingAddParticipant = false
    @State private var newParticipantName = ""
    
    private let participantColors: [String] = ["blue", "green", "red", "orange", "purple", "pink", "teal", "indigo"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Add Participant Button
            HStack {
                Text("Assign Items")
                    .font(.largeTitle)
                    .bold()
                
                Spacer()
                
                Button(action: {
                    showingAddParticipant = true
                }) {
                    Image(systemName: "person.badge.plus")
                        .font(.title2)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Participants Section
                    participantsSection
                    
                    // Unassigned Items Section
                    unassignedItemsSection
                    
                    // Bill Summary
                    billSummarySection
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingAddParticipant) {
            addParticipantSheet
        }
    }
    
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Participants")
                .font(.headline)
                .padding(.horizontal)
            
            if bill.participants.isEmpty {
                // Empty state
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 100)
                    .overlay(
                        VStack {
                            Image(systemName: "person.2.badge.plus")
                                .font(.title)
                                .foregroundColor(.gray)
                            Text("Add participants to start assigning items")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
                    .padding(.horizontal)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(bill.participants) { participant in
                        ParticipantCardView(
                            participant: participant,
                            bill: $bill,
                            draggedItem: $draggedItem
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var unassignedItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Unassigned Items")
                    .font(.headline)
                
                Spacer()
                
                Text("Drag items to participants")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            
            if unassignedItems.isEmpty {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.1))
                    .frame(height: 60)
                    .overlay(
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("All items assigned!")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                    )
                    .padding(.horizontal)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(unassignedItems) { item in
                        ItemCardView(item: item, bill: $bill)
                            .draggable(item) {
                                ItemDragPreview(item: item)
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var billSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bill Summary")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                ForEach(bill.participants) { participant in
                    HStack {
                        Circle()
                            .fill(participant.color)
                            .frame(width: 12, height: 12)
                        
                        Text(participant.name)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("$\(bill.totalForParticipant(participant.id), specifier: "%.2f")")
                            .font(.subheadline)
                            .bold()
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                
                HStack {
                    Text("Total Bill")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("$\(bill.finalTotal, specifier: "%.2f")")
                        .font(.headline)
                        .bold()
                }
                .padding(.horizontal)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 2)
            .padding(.horizontal)
        }
    }
    
    private var addParticipantSheet: some View {
        NavigationView {
            Form {
                Section("New Participant") {
                    TextField("Name", text: $newParticipantName)
                        .textFieldStyle(.roundedBorder)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                        ForEach(participantColors, id: \.self) { colorName in
                            Circle()
                                .fill(Color(colorName))
                                .frame(width: 40, height: 40)
                                .onTapGesture {
                                    addParticipant(colorName: colorName)
                                }
                        }
                    }
                }
            }
            .navigationTitle("Add Participant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingAddParticipant = false
                        newParticipantName = ""
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addParticipant(colorName: availableColor)
                    }
                    .disabled(newParticipantName.isEmpty)
                }
            }
        }
    }
    
    private var unassignedItems: [BillItem] {
        bill.items.filter { $0.assignedTo.isEmpty }
    }
    
    private var availableColor: String {
        let usedColors = Set(bill.participants.map { $0.colorName })
        return participantColors.first { !usedColors.contains($0) } ?? "blue"
    }
    
    private func addParticipant(colorName: String) {
        let participant = Participant(name: newParticipantName, colorName: colorName)
        bill.participants.append(participant)
        showingAddParticipant = false
        newParticipantName = ""
    }
}

// MARK: - Participant Card View
struct ParticipantCardView: View {
    let participant: Participant
    @Binding var bill: Bill
    @Binding var draggedItem: BillItem?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(participant.color)
                    .frame(width: 20, height: 20)
                
                Text(participant.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Text("$\(bill.totalForParticipant(participant.id), specifier: "%.2f")")
                    .font(.caption)
                    .bold()
            }
            
            // Assigned items
            if !assignedItems.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(assignedItems) { item in
                        HStack {
                            Text(item.name)
                                .font(.caption)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("$\(item.pricePerPerson, specifier: "%.2f")")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .onTapGesture {
                            unassignItem(item)
                        }
                    }
                }
            } else {
                Text("No items assigned")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .italic()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(participant.color.opacity(0.1))
        .cornerRadius(12)
        .dropDestination(for: BillItem.self) { items, location in
            assignItems(items)
            return true
        }
    }
    
    private var assignedItems: [BillItem] {
        bill.items.filter { $0.assignedTo.contains(participant.id) }
    }
    
    private func assignItems(_ items: [BillItem]) {
        for item in items {
            if let index = bill.items.firstIndex(where: { $0.id == item.id }) {
                bill.items[index].assignedTo = [participant.id]
            }
        }
    }
    
    private func unassignItem(_ item: BillItem) {
        if let index = bill.items.firstIndex(where: { $0.id == item.id }) {
            bill.items[index].assignedTo.removeAll()
        }
    }
}

// MARK: - Item Card View
struct ItemCardView: View {
    let item: BillItem
    @Binding var bill: Bill
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.name)
                    .font(.subheadline)
                    .bold()
                    .lineLimit(2)
                
                Spacer()
                
                Text("$\(item.price, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
            
            if item.quantity > 1 {
                Text("Qty: \(item.quantity)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 1)
    }
}

// MARK: - Item Drag Preview
struct ItemDragPreview: View {
    let item: BillItem
    
    var body: some View {
        VStack {
            Text(item.name)
                .font(.caption)
                .bold()
            Text("$\(item.price, specifier: "%.2f")")
                .font(.caption)
                .foregroundColor(.green)
        }
        .padding(8)
        .background(Color.white)
        .cornerRadius(6)
        .shadow(radius: 2)
    }
}


