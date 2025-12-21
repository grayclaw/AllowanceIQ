//
//  TransactionViews.swift
//  AllowanceIQ
//
//  Created by Brian Homer Jr on 12/13/25.
//

import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction
    let onTap: () -> Void
    var transactionStyle: (type: String, sign: String, color: Color) {
        switch transaction.type {
        case .deposit:
            return ("DEPOSIT", "+", Color("OtherGreen"))
        case .savingsDeposit:
            return ("SAVINGS DEPOSIT", "", .primary)
        case .tithingPayment:
            return ("TITHING PAYMENT", "-", .red)
        default:
            return (transaction.type.rawValue.uppercased(), "-", .red)
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("\(transactionStyle.sign)\(formatCurrency(transaction.amount))")
                        .font(.body)
                        .fontWeight(.bold)
                        .foregroundColor(transactionStyle.color)
                    Text(transactionStyle.type)
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
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Transaction Form View

struct TransactionFormView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    
    let childId: String
    let editingTransaction: Transaction?
    
    @State private var type: Transaction.TransactionType = .deposit
    @State private var amount = ""
    @State private var note = ""
    
    init(childId: String, editingTransaction: Transaction? = nil) {
        self.childId = childId
        self.editingTransaction = editingTransaction
        
        if let transaction = editingTransaction {
            _type = State(initialValue: transaction.type)
            _amount = State(initialValue: String(format: "%.2f", transaction.amount))
            _note = State(initialValue: transaction.note)
        }
    }
    
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
                    .disabled(editingTransaction?.type == .tithingPayment)
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
                    Text("Description")
                }
                
                if editingTransaction != nil {
                    Section {
                        Button(role: .destructive) {
                            dataManager.deleteTransaction(childId: childId, transactionId: editingTransaction!.id)
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Transaction")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(editingTransaction == nil ? "New Transaction" : "Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editingTransaction == nil ? "Add Transaction" : "Save") {
                        if isValid, let amountValue = Double(amount) {
                            if let transaction = editingTransaction {
                                dataManager.updateTransaction(
                                    childId: childId,
                                    transactionId: transaction.id,
                                    type: type,
                                    amount: amountValue,
                                    note: note.trimmingCharacters(in: .whitespaces)
                                )
                            } else {
                                dataManager.addTransaction(
                                    childId: childId,
                                    type: type,
                                    amount: amountValue,
                                    note: note.trimmingCharacters(in: .whitespaces)
                                )
                            }
                            dismiss()
                        }
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}
