import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var billViewModel: BillViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var settings: AppSettings
    @State private var showingDefaultParticipants = false
    
    private let currencyCodes = ["USD", "EUR", "GBP", "CAD", "AUD", "JPY"]
    
    init() {
        _settings = State(initialValue: StorageService.shared.loadSettings())
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Default Values Section
                Section("Default Values") {
                    HStack {
                        Text("Tax")
                        Spacer()
                        TextField("Tax %", value: $settings.defaultTaxPercentage, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Tip")
                        Spacer()
                        TextField("Tip %", value: $settings.defaultTipPercentage, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                // Currency Section
                Section("Currency") {
                    Picker("Currency", selection: $settings.currencyCode) {
                        ForEach(currencyCodes, id: \.self) { code in
                            Text(code).tag(code)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Rounding Section
                Section("Rounding") {
                    Picker("Round Totals", selection: $settings.roundingMode) {
                        Text("None").tag(AppSettings.RoundingMode.none)
                        Text("Up").tag(AppSettings.RoundingMode.up)
                        Text("Down").tag(AppSettings.RoundingMode.down)
                        Text("Nearest").tag(AppSettings.RoundingMode.nearest)
                    }
                    .pickerStyle(.segmented)
                }
                
                // History Section
                Section("History") {
                    Toggle("Save Bill History", isOn: $settings.saveHistory)
                }
                
                // Default Participants Section
                Section("Default Participants") {
                    Button {
                        showingDefaultParticipants = true
                    } label: {
                        HStack {
                            Text("Manage Default Participants")
                            Spacer()
                            Text("\(settings.defaultParticipants.count)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Reset Section
                Section {
                    Button(role: .destructive) {
                        settings = AppSettings()
                    } label: {
                        Text("Reset to Defaults")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        billViewModel.settings = settings
                        billViewModel.saveSettings()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingDefaultParticipants) {
                DefaultParticipantsView(participants: $settings.defaultParticipants)
            }
        }
    }
}

// MARK: - Default Participants View
struct DefaultParticipantsView: View {
    @Binding var participants: [Participant]
    @Environment(\.dismiss) private var dismiss
    @State private var newParticipantName = ""
    @State private var selectedColorIndex = 0
    
    private let participantColors: [Color] = [
        .blue, .green, .orange, .purple, .pink, .red, .yellow, .mint, .teal, .indigo
    ]
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(participants) { participant in
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
                        }
                    }
                    .onDelete { indexSet in
                        participants.remove(atOffsets: indexSet)
                    }
                    
                    HStack {
                        TextField("New Participant", text: $newParticipantName)
                        
                        Picker("Color", selection: $selectedColorIndex) {
                            ForEach(participantColors.indices, id: \.self) { index in
                                Circle()
                                    .fill(participantColors[index])
                                    .frame(width: 24, height: 24)
                                    .tag(index)
                            }
                        }
                        
                        Button {
                            addParticipant()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                        .disabled(newParticipantName.isEmpty)
                    }
                }
            }
            .navigationTitle("Default Participants")
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
    
    private func addParticipant() {
        let colorName = participantColors[selectedColorIndex].description
        let participant = Participant(name: newParticipantName, colorName: colorName)
        participants.append(participant)
        newParticipantName = ""
    }
} 