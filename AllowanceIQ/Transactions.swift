//
//  Transactions.swift
//  AllowanceIQ
//
//  Created by Brian Homer Jr on 11/20/25.
//

import SwiftUI

struct Transaction: Identifiable, Codable {
    let id: String
    let type: TransactionType
    let amount: Double
    let note: String
    let date: Date
    
    enum TransactionType: String, Codable {
        case deposit
        case withdrawal
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("\(transaction.type == .deposit ? "+" : "-")\(formatCurrency(transaction.amount))")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(transaction.type == .deposit ? Color("OtherGreen") : .red)
                
                Text(transaction.type.rawValue.uppercased())
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            Text(transaction.note)
                .font(.body)
                .foregroundColor(.primary)
            
            Text(formatDate(transaction.date))
                .font(.subheadline)
                .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white, lineWidth: 1)
        )
    }
}

// MARK: - Transaction Form View

struct TransactionFormView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    
    let childId: String
    
    @State private var type: Transaction.TransactionType = .deposit
    @State private var amount = ""
    @State private var note = ""
    
    var isValid: Bool {
        guard let amountValue = Double(amount),
              amountValue > 0,
              !note.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }
        return true
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Transaction Type", selection: $type) {
                        Text("Deposit").tag(Transaction.TransactionType.deposit)
                        Text("Withdrawal").tag(Transaction.TransactionType.withdrawal)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Transaction Type")
                }
                
                Section {
                    TextField("0.00", text: $amount)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Amount")
                }
                
                Section {
                    TextField("e.g., Weekly allowance, Toy purchase", text: $note)
                } header: {
                    Text("Note")
                }
            }
            .navigationTitle("New Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Transaction") {
                        if isValid, let amountValue = Double(amount) {
                            dataManager.addTransaction(
                                childId: childId,
                                type: type,
                                amount: amountValue,
                                note: note.trimmingCharacters(in: .whitespaces)
                            )
                            dismiss()
                        }
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}
