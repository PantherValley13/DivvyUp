//
//  ContentView.swift
//  DivvyUp
//
//  Created by Darius Church on 7/4/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var ocrService = OCRService()
    @StateObject private var supabaseService = SupabaseService()
    @State private var currentBill = Bill()
    @State private var selectedTab = 0
    @State private var showingCameraOCR = false
    @State private var savedBills: [Bill] = []
    
    var body: some View {
        TabView(selection: $selectedTab) {
            homeTab
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            cameraOCRTab
                .tabItem {
                    Label("Scan", systemImage: "camera")
                }
                .tag(1)
            
            galleryUploadTab
                .tabItem {
                    Label("Gallery", systemImage: "photo")
                }
                .tag(2)
            
            assignmentTab
                .tabItem {
                    Label("Assign", systemImage: "person.2")
                }
                .tag(3)
            
            billsHistoryTab
                .tabItem {
                    Label("History", systemImage: "clock")
                }
                .tag(4)
        }
        .onAppear {
            Theme.configureNavigationBarAppearance()
            Task {
                await loadSavedBills()
            }
        }
    }
    
    private var homeTab: some View {
        ScrollView {
            VStack(spacing: Theme.spacing * 1.5) {
                // Welcome Section
                ContentCard(title: "Welcome to DivvyUp", icon: "hand.wave") {
                    Text("Split bills effortlessly with friends and family")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Quick Actions
                ContentCard(title: "Quick Actions", icon: "bolt") {
                    quickActionsSection
                }
                
                // Current Bill Preview
                ContentCard(title: "Current Bill", icon: "receipt") {
                    currentBillPreview
                }
                
                // Recent Activity
                ContentCard(title: "Recent Activity", icon: "clock") {
                    recentActivitySection
                }
            }
            .padding()
        }
        .background(Theme.backgroundGradient)
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: Theme.spacing) {
            ActionButton(
                icon: "camera.viewfinder",
                title: "Scan Receipt",
                subtitle: "Use camera to scan and extract items",
                isLoading: ocrService.isProcessing
            ) {
                showingCameraOCR = true
            }
            
            ActionButton(
                icon: "photo.on.rectangle",
                title: "Upload Photo",
                subtitle: "Choose from gallery",
                style: Theme.SecondaryButtonStyle()
            ) {
                selectedTab = 2
            }
            
            ActionButton(
                icon: "person.2.rectangle.stack",
                title: "Assign Items",
                subtitle: "Split items between participants",
                style: Theme.SecondaryButtonStyle()
            ) {
                selectedTab = 3
            }
        }
    }
    
    private var currentBillPreview: some View {
        Group {
            if currentBill.items.isEmpty {
                EmptyStateView(
                    icon: "receipt",
                    title: "No items yet",
                    message: "Start by scanning a receipt or uploading a photo",
                    actionTitle: "Scan Receipt",
                    action: { showingCameraOCR = true }
                )
            } else {
                VStack(spacing: Theme.spacing) {
                    ForEach(currentBill.items.prefix(3)) { item in
                        HStack {
                            Text(item.name)
                                .font(.subheadline)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("$\(item.price, specifier: "%.2f")")
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(Theme.success)
                        }
                    }
                    
                    if currentBill.items.count > 3 {
                        Text("... and \(currentBill.items.count - 3) more items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Subtotal")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("$\(currentBill.subtotal, specifier: "%.2f")")
                            .font(.headline)
                            .bold()
                            .foregroundColor(Theme.success)
                    }
                    
                    HStack(spacing: Theme.spacing) {
                        Button("Save Bill") {
                            Task {
                                await saveBill()
                            }
                        }
                        .buttonStyle(Theme.PrimaryButtonStyle())
                        
                        Button("Clear") {
                            withAnimation {
                                currentBill = Bill()
                                ocrService.clearItems()
                            }
                        }
                        .buttonStyle(Theme.SecondaryButtonStyle())
                    }
                    .padding(.top, 8)
                }
            }
        }
    }
    
    private var recentActivitySection: some View {
        Group {
            if ocrService.recognizedText.isEmpty {
                EmptyStateView(
                    icon: "text.viewfinder",
                    title: "No recent scans",
                    message: "Your recent OCR scans will appear here",
                    actionTitle: "",
                    action: {}
                )
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Last OCR Scan:")
                        .font(.subheadline)
                        .bold()
                    
                    Text(ocrService.recognizedText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(5)
                        .padding()
                        .background(Theme.secondary)
                        .cornerRadius(Theme.cornerRadius)
                }
            }
        }
    }
    
    private var cameraOCRTab: some View {
        VStack(spacing: Theme.spacing) {
            Text("Scan Receipt")
                .font(.largeTitle)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            ActionButton(
                icon: "camera.viewfinder",
                title: "Start Scanning",
                subtitle: "Use your camera to scan receipts",
                isLoading: ocrService.isProcessing
            ) {
                showingCameraOCR = true
            }
            .padding(.horizontal)
            
            if ocrService.isProcessing {
                VStack(spacing: Theme.spacing) {
                    ProgressView(value: ocrService.processingProgress)
                    
                    Text(ocrService.currentProcessingStep)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(ocrService.processingProgress * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Theme.secondary)
                .cornerRadius(Theme.cornerRadius)
                .padding(.horizontal)
            }
            
            if !ocrService.extractedItems.isEmpty {
                ContentCard(title: "Extracted Items", icon: "list.bullet") {
                    extractedItemsPreview
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .background(Theme.backgroundGradient)
        .sheet(isPresented: $showingCameraOCR) {
            CameraOCRView(ocrService: ocrService)
        }
    }
    
    private var extractedItemsPreview: some View {
        VStack(spacing: Theme.spacing) {
            ForEach(ocrService.extractedItems) { item in
                HStack {
                    Text(item.name)
                        .font(.subheadline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text("$\(item.price, specifier: "%.2f")")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(Theme.success)
                }
            }
        }
    }
    
    private func saveBill() async {
        guard SupabaseConfig.isConfigured else {
            print("Supabase not configured")
            return
        }
        
        do {
            try await supabaseService.saveBill(currentBill)
            await loadSavedBills()
        } catch {
            print("Error saving bill: \(error)")
        }
    }
    
    private func loadSavedBills() async {
        guard SupabaseConfig.isConfigured else {
            return
        }
        
        do {
            savedBills = try await supabaseService.loadAllBills()
        } catch {
            print("Error loading bills: \(error)")
        }
    }
    
    private var galleryUploadTab: some View {
        GalleryUploadView(ocrService: ocrService)
    }
    
    private var assignmentTab: some View {
        if currentBill.items.isEmpty {
            AnyView(
                VStack(spacing: 20) {
                    Image(systemName: "person.2.rectangle.stack")
                        .font(.system(size: 64))
                        .foregroundColor(.gray)
                    
                    Text("No Items to Assign")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("Start by scanning a receipt or uploading a photo to extract items for assignment")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Scan Receipt") {
                        selectedTab = 1
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            )
        } else {
            AnyView(ItemAssignmentView(bill: $currentBill))
        }
    }
    
    private var billsHistoryTab: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Header with refresh button
                HStack {
                    Text("Bills History")
                        .font(.largeTitle)
                        .bold()
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await loadSavedBills()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                    }
                    .disabled(supabaseService.isLoading)
                }
                .padding(.horizontal)
                
                // Configuration status
                if !SupabaseConfig.isConfigured {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        
                        Text("Supabase Not Configured")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text("Update SupabaseConfig.swift with your project credentials to enable database features")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Spacer()
                } else if supabaseService.isLoading {
                    ProgressView("Loading bills...")
                        .padding()
                    Spacer()
                } else if savedBills.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "tray")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)
                        
                        Text("No Saved Bills")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Bills you save will appear here")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    
                    Spacer()
                } else {
                    // Bills list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(savedBills) { bill in
                                BillHistoryRowView(
                                    bill: bill,
                                    onLoad: { bill in
                                        currentBill = bill
                                        selectedTab = 0 // Switch to home tab
                                    },
                                    onDelete: { bill in
                                        Task {
                                            await deleteBill(bill)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Error handling
                if let error = supabaseService.error {
                    VStack(spacing: 8) {
                        Text("Error: \(error.localizedDescription)")
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        
                        Button("Dismiss") {
                            supabaseService.clearError()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func deleteBill(_ bill: Bill) async {
        guard SupabaseConfig.isConfigured else {
            return
        }
        
        do {
            try await supabaseService.deleteBill(id: bill.id)
            await loadSavedBills()
        } catch {
            print("Error deleting bill: \(error)")
        }
    }
}

// MARK: - Bill History Row View
struct BillHistoryRowView: View {
    let bill: Bill
    let onLoad: (Bill) -> Void
    let onDelete: (Bill) -> Void
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bill from \(dateFormatter.string(from: bill.date))")
                        .font(.headline)
                    
                    Text("\(bill.items.count) items • \(bill.participants.count) participants")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text("$\(bill.finalTotal, specifier: "%.2f")")
                    .font(.headline)
                    .bold()
                    .foregroundColor(.green)
            }
            
            HStack {
                Button("Load Bill") {
                    onLoad(bill)
                }
                .buttonStyle(.borderedProminent)
                .font(.caption)
                
                Spacer()
                
                Button("Delete") {
                    onDelete(bill)
                }
                .buttonStyle(.bordered)
                .font(.caption)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    ContentView()
}
