//
//  ContentView.swift
//  AllowanceIQ
//
//  Created by Brian Homer Jr on 10/20/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var selectedChildId: String?
    
    var body: some View {
        NavigationStack {
            if let childId = selectedChildId,
               let child = dataManager.children.first(where: { $0.id == childId }) {
                ChildDetailView(child: child, onBack: { selectedChildId = nil })
            } else {
                HomeView(onSelectChild: { id in selectedChildId = id })
            }
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var showingAddChild = false
    
    let onSelectChild: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("AllowanceIQ")
                    .font(.title)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: { showingAddChild = true }) {
                    Label("Add Child", systemImage: "plus")
                        .font(.body)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(.systemBackground))
            
            ScrollView {
                if dataManager.sortedChildren.isEmpty {
                    VStack(spacing: 16) {
                        Text("No children added yet")
                            .font(.title3)
                            .foregroundColor(.primary)
                        
                        Button("Add Your First Child") {
                            showingAddChild = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 80)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 16) {
                        ForEach(dataManager.sortedChildren) { child in
                            ChildCard(child: child, onTap: { onSelectChild(child.id) })
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .sheet(isPresented: $showingAddChild) {
            AddChildView()
                .environmentObject(dataManager)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DataManager())
}
