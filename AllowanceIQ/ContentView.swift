//
//  ContentView.swift
//  AllowanceIQ
//
//  Created by Brian Homer Jr on 10/20/25.
//

import SwiftUI
import Combine

class DataManager: ObservableObject {
    @Published var children: [Child] = []
    
    private let storageKey = "allowance-tracker-data"
    
    init() {
        loadData()
    }
    
    func loadData() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Child].self, from: data) else {
            children = []
            return
        }
        children = decoded
    }
    
    func saveData() {
        if let encoded = try? JSONEncoder().encode(children) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    func addChild(name: String, birthYear: Int, isTithingEnabled: Bool) {
        let newChild = Child(
            id: UUID().uuidString,
            name: name,
            birthYear: birthYear,
            balance: 0,
            transactions: [],
            isTithingEnabled: isTithingEnabled
        )
        print(newChild)
        children.append(newChild)
        saveData()
    }
    
    func deleteChild(id: String) {
        children.removeAll { $0.id == id }
        saveData()
    }
    
    func addTransaction(childId: String, type: Transaction.TransactionType, amount: Double, note: String) {
        guard let index = children.firstIndex(where: { $0.id == childId }) else { return }

        let transaction = Transaction(
            id: UUID().uuidString,
            type: type,
            amount: amount,
            note: note,
            date: Date()
        )

        let change = type == .deposit ? amount : -amount
        children[index].balance += change
        children[index].transactions.append(transaction)

        if type == .deposit && children[index].isTithingEnabled {
            let tithingAmount = amount * 0.10
            children[index].tithingBalance += tithingAmount
        }

        saveData()
    }

    func payTithing(for childId: String) {
        guard let index = children.firstIndex(where: { $0.id == childId }) else { return }
        let tithingAmount = children[index].tithingBalance
        guard tithingAmount > 0 else { return }

        let transaction = Transaction(
            id: UUID().uuidString,
            type: .withdrawal,
            amount: tithingAmount,
            note: "Tithing payment",
            date: Date()
        )
        
        children[index].balance -= tithingAmount
        children[index].transactions.append(transaction)
        children[index].tithingBalance = 0
        saveData()
    }

    
    var sortedChildren: [Child] {
        children.sorted { $0.birthYear > $1.birthYear }
    }
}

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
