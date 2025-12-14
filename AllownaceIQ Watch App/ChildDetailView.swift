//
//  Untitled.swift
//  AllowanceIQ
//
//  Created by Brian Homer Jr on 12/13/25.
//

import SwiftUI

struct WatchChildDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    let child: Child
    
    var sortedTransactions: [Transaction] {
        child.transactions.sorted(by: { $0.date > $1.date })
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading) {
                    Text("Balance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(child.netBalance))
                        .font(.title2)
                        .foregroundColor(child.netBalance >= 0 ? .green : .red)
                }
                
                if child.isTithingEnabled && child.tithingBalance > 0 {
                    VStack(alignment: .leading) {
                        Text("Tithing Due")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(child.tithingBalance))
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Section("Recent Transactions") {
                ForEach(Array(sortedTransactions.prefix(10))) { transaction in
                    WatchTransactionRow(transaction: transaction)
                }
            }
        }
        .navigationTitle(child.name)
    }
}

struct WatchTransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(transaction.note)
                    .font(.caption)
                Spacer()
                Text("\(transaction.type == .deposit ? "+" : "-")\(formatCurrency(transaction.amount))")
                    .font(.caption)
                    .foregroundColor(transaction.type == .deposit ? .green : .red)
            }
            Text(formatDate(transaction.date))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
