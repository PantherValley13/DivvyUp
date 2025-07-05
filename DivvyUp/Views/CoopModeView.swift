import SwiftUI

struct CoopModeView: View {
    let bill: Bill
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CoopModeViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.spacing) {
                    // QR Code Section
                    ContentCard(title: "Share Link", icon: "qrcode") {
                        VStack(spacing: Theme.spacing) {
                            if let qrCode = viewModel.qrCode {
                                Image(uiImage: qrCode)
                                    .interpolation(.none)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 200, height: 200)
                            } else {
                                ProgressView()
                                    .frame(width: 200, height: 200)
                            }
                            
                            Text("Scan this QR code or share the link below to let others submit their orders")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            if let url = viewModel.coopURL {
                                ShareLink("Share Link", item: url)
                                    .buttonStyle(.bordered)
                            }
                        }
                    }
                    
                    // Participants Section
                    ContentCard(title: "Participants", icon: "person.2") {
                        VStack(spacing: Theme.spacing) {
                            ForEach(viewModel.participants) { participant in
                                HStack {
                                    Circle()
                                        .fill(participant.color)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Text(participant.name.prefix(1).uppercased())
                                                .foregroundColor(.white)
                                                .font(.caption)
                                        )
                                    
                                    VStack(alignment: .leading) {
                                        Text(participant.name)
                                            .font(.headline)
                                        
                                        if let items = viewModel.participantItems[participant.id] {
                                            Text("\(items.count) items selected")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        } else {
                                            Text("Waiting for submission...")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if viewModel.participantItems[participant.id] != nil {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding()
                                .background(Theme.secondary)
                                .cornerRadius(Theme.cornerRadius)
                            }
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: Theme.spacing) {
                        Button {
                            viewModel.finalizeSplit()
                            dismiss()
                        } label: {
                            Label("Finalize Split", systemImage: "checkmark.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!viewModel.canFinalize)
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
            .navigationTitle("Co-op Mode")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.setupCoopSession(for: bill)
        }
    }
} 