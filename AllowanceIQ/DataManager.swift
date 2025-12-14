//
//  DataManager.swift
//  AllowanceIQ
//
//  Created by Brian Homer Jr on 12/13/25.
//

import SwiftUI
import Combine

class DataManager: ObservableObject {
    @Published var children: [Child] = []
    
    private let storageKey = "allowance-tracker-data"
    private let kvStore: NSUbiquitousKeyValueStore?
    private let useICloud: Bool
    
    init(useICloud: Bool = true) {
        // Check if iCloud KV Store is available by checking entitlements
        var canUseICloud = false
        var store: NSUbiquitousKeyValueStore?
        
        if useICloud {
            // Check if the ubiquity container identifier is set
            if let ubiquityIdentityToken = FileManager.default.ubiquityIdentityToken {
                store = NSUbiquitousKeyValueStore.default
                canUseICloud = true
                print("iCloud available with token: \(ubiquityIdentityToken)")
            } else {
                print("iCloud not available - no ubiquity token")
                canUseICloud = false
            }
        }
        
        self.useICloud = canUseICloud
        self.kvStore = store
        
        if canUseICloud, let kvStore = store {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(ubiquitousKeyValueStoreDidChange),
                name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                object: kvStore
            )
            kvStore.synchronize()
        }
        
        loadData()
    }
    
    func loadData() {
        // Try iCloud first if available
        if useICloud, let kvStore = kvStore,
           let data = kvStore.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Child].self, from: data) {
            children = decoded
            return
        }
        
        // Fall back to UserDefaults
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Child].self, from: data) {
            children = decoded
        } else {
            children = []
        }
    }
    
    func saveData() {
        if let encoded = try? JSONEncoder().encode(children) {
            // Save to iCloud if available
            if useICloud, let kvStore = kvStore {
                kvStore.set(encoded, forKey: storageKey)
                kvStore.synchronize()
            }
            // Always save to UserDefaults as backup
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    @objc private func ubiquitousKeyValueStoreDidChange(_ notification: Notification) {
        DispatchQueue.main.async {
            self.loadData()
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

    func updateTransaction(childId: String, transactionId: String, type: Transaction.TransactionType, amount: Double, note: String) {
        guard let childIndex = children.firstIndex(where: { $0.id == childId }) else { return }
        guard let transactionIndex = children[childIndex].transactions.firstIndex(where: { $0.id == transactionId }) else { return }
        
        let oldTransaction = children[childIndex].transactions[transactionIndex]
        
        let updatedTransaction = Transaction(
            id: transactionId,
            type: type,
            amount: amount,
            note: note,
            date: oldTransaction.date
        )
        
        children[childIndex].transactions[transactionIndex] = updatedTransaction
        recalculateChildFinances(childId: childId)
        saveData()
    }

    func deleteTransaction(childId: String, transactionId: String) {
        guard let childIndex = children.firstIndex(where: { $0.id == childId }) else { return }
        children[childIndex].transactions.removeAll { $0.id == transactionId }
        recalculateChildFinances(childId: childId)
        saveData()
    }

    private func recalculateChildFinances(childId: String) {
        guard let childIndex = children.firstIndex(where: { $0.id == childId }) else { return }
        
        var newBalance = 0.0
        var totalDeposits = 0.0
        var totalTithingPaid = 0.0
        
        for transaction in children[childIndex].transactions {
            switch transaction.type {
            case .deposit:
                newBalance += transaction.amount
                totalDeposits += transaction.amount
            case .withdrawal:
                newBalance -= transaction.amount
            case .tithingPayment:
                newBalance -= transaction.amount
                totalTithingPaid += transaction.amount
            }
        }
        
        let calculatedTithing = totalDeposits * 0.10
        let newTithingBalance = max(0, calculatedTithing - totalTithingPaid)
        
        children[childIndex].balance = newBalance
        children[childIndex].tithingBalance = newTithingBalance
    }

    func payTithing(for childId: String) {
        guard let childIndex = children.firstIndex(where: { $0.id == childId }) else { return }
        
        let amountPaid = children[childIndex].tithingBalance
        guard amountPaid > 0 else { return }
        
        let transaction = Transaction(
            id: UUID().uuidString,
            type: .tithingPayment,
            amount: amountPaid,
            note: "Tithing payment",
            date: Date()
        )
        
        children[childIndex].transactions.append(transaction)
        recalculateChildFinances(childId: childId)
        saveData()
    }
    
    var sortedChildren: [Child] {
        children.sorted { $0.age < $1.age }
    }
}
