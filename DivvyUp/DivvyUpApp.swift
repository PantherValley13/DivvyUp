//
//  DivvyUpApp.swift
//  DivvyUp
//
//  Created by Darius Church on 7/4/25.
//

import SwiftUI

@main
struct DivvyUpApp: App {
    @StateObject private var billViewModel = BillViewModel()
    @State private var showingSettings = false
    @State private var showingHistory = false
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                BillScannerView()
                    .environmentObject(billViewModel)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                showingHistory = true
                            } label: {
                                Image(systemName: "clock.arrow.circlepath")
                            }
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showingSettings = true
                            } label: {
                                Image(systemName: "gear")
                            }
                        }
                    }
                    .sheet(isPresented: $showingSettings) {
                        SettingsView()
                            .environmentObject(billViewModel)
                    }
                    .sheet(isPresented: $showingHistory) {
                        HistoryView()
                            .environmentObject(billViewModel)
                    }
            }
        }
    }
}
