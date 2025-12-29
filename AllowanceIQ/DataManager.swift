//
//  DataManager.swift
//  AllowanceIQ
//
//  Created by Brian Homer Jr on 12/13/25.
//

import SwiftUI
import Combine
import WatchConnectivity

class DataManager: ObservableObject {
    @Published var children: [Child] = []
    
    private let appGroupID = "group.juniors-homers.allowanceiq"

    init() {
        ConnectivityProvider.shared.dataManager = self
        loadData()
        // Listen for iCloud changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(icloudDataChanged),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )
    }

    func loadData() {
        // First try iCloud
        let store = NSUbiquitousKeyValueStore.default
        if let data = store.data(forKey: "children"),
           let decoded = try? JSONDecoder().decode([Child].self, from: data) {
            children = decoded
        } else {
            children = []
        }
    }

    func saveData() {
        if let encoded = try? JSONEncoder().encode(children) {
            // Save to iCloud
            let store = NSUbiquitousKeyValueStore.default
            store.set(encoded, forKey: "children")
            store.synchronize()

            // Send to Watch
            if WCSession.default.isReachable {
                WCSession.default.sendMessage(["children": encoded], replyHandler: nil) { error in
                    print("Error sending data:", error.localizedDescription)
                }
            } else {
                WCSession.default.transferUserInfo(["children": encoded])
            }
        }
    }

    @objc private func icloudDataChanged(_ notification: Notification) {
        loadData() // reload when iCloud pushes changes
    }
    
    func addChild(name: String, birthYear: Int, isTithingEnabled: Bool, isSavingsEnabled: Bool = false, savingsPercentage: Double) {
        let newChild = Child(
            id: UUID().uuidString,
            name: name,
            birthYear: birthYear,
            balance: 0,
            transactions: [],
            isTithingEnabled: isTithingEnabled,
            isSavingsEnabled: isSavingsEnabled,
            savingsPercentage: savingsPercentage * 0.01
        )
        children.append(newChild)
        saveData()
    }
    
    func deleteChild(id: String) {
        children.removeAll { $0.id == id }
        saveData()
    }
    
    func updateChild(id: String, birthYear: Int, isTithingEnabled: Bool, isSavingsEnabled: Bool, savingsPercentage: Double) {
        if let index = children.firstIndex(where: { $0.id == id }) {
            children[index].birthYear = birthYear
            children[index].isTithingEnabled = isTithingEnabled
            children[index].isSavingsEnabled = isSavingsEnabled
            children[index].savingsPercentage = savingsPercentage * 0.01
            saveData()
        }
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
        
        if type == .deposit && children[index].isSavingsEnabled {
            let savingAmount = amount * children[index].savingsPercentage
            children[index].savingsBalance += savingAmount
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
        var totalSavingsPaid = 0.0
        
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
                case .savingsDeposit:
                    newBalance -= transaction.amount
                    totalSavingsPaid += transaction.amount
            }
        }
        
        let calculatedTithing = totalDeposits * 0.10
        let newTithingBalance = max(0, calculatedTithing - totalTithingPaid)
        let calculatedSavings = totalDeposits * children[childIndex].savingsPercentage
        let newSavingsBalance = max(0, calculatedSavings - totalSavingsPaid)
        
        children[childIndex].balance = newBalance
        children[childIndex].tithingBalance = newTithingBalance
        children[childIndex].savingsBalance = newSavingsBalance
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
    
    func paySavings(for childId: String) {
        guard let childIndex = children.firstIndex(where: { $0.id == childId }) else { return }
        
        let amountPaid = children[childIndex].savingsBalance
        guard amountPaid > 0 else { return }
        
        let transaction = Transaction(
            id: UUID().uuidString,
            type: .savingsDeposit,
            amount: amountPaid,
            note: "Savings deposit",
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
