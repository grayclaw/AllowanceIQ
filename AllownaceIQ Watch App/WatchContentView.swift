//
//  ContentView.swift
//  AllownaceIQ Watch App
//
//  Created by Brian Homer Jr on 12/6/25.
//

import SwiftUI
import Combine

struct WatchContentView: View {
    @StateObject private var dataManager = DataManager()
    
    var body: some View {
        NavigationView {
            List {                
                Section {
                    if dataManager.sortedChildren.isEmpty {
                        Text("No children yet")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(dataManager.sortedChildren) { child in
                            NavigationLink(destination: WatchChildDetailView(child: child)
                                .environmentObject(dataManager)) {
                                WatchChildRow(child: child)
                            }
                        }
                    }
                }
            }
            .navigationTitle("AllowanceIQ")
        }
    }
}

struct WatchChildRow: View {
    let child: Child
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(child.name)
                .font(.headline)
            Text(formatCurrency(child.netBalance))
                .font(.title3)
                .foregroundColor(child.netBalance >= 0 ? .green : .red)
        }
    }
}

#Preview {
    WatchContentView()
}
