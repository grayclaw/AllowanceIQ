//
//  ChildView.swift
//  AllowanceIQ
//
//  Created by Brian Homer Jr on 12/13/25.
//

import SwiftUI

struct ChildCard: View {
    let child: Child
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(child.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Balance")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Text(formatCurrency(child.netBalance))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(child.netBalance >= 0 ? Color("OtherGreen") : .red)
                    }
                }
                
                Text("\(child.transactions.count) transaction\(child.transactions.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Add Child View

struct AddChildView: View {
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var birthYear = ""
    @State private var isTithingEnabled: Bool = true
    
    var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }
    
    var isValid: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              let year = Int(birthYear),
              year >= 1900,
              year <= currentYear else {
            return false
        }
        return true
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Enter child's name", text: $name)
                } header: {
                    Text("Name")
                }
                
                Section {
                    TextField("e.g., \(currentYear - 10)", text: $birthYear)
                        .keyboardType(.numberPad)
                } header: {
                    Text("Birth Year")
                }
                
                Section {
                    Toggle("Enable Tithing", isOn: $isTithingEnabled)
                }
            }
            .navigationTitle("Add New Child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Child") {
                        if isValid, let year = Int(birthYear) {
                            dataManager.addChild(name: name.trimmingCharacters(in: .whitespaces), birthYear: year, isTithingEnabled: isTithingEnabled)
                            dismiss()
                        }
                    }
                    .disabled(!isValid)
                }
            }
        }
    }
}

// MARK: - Child Detail View

struct ChildDetailView: View {
    @EnvironmentObject var dataManager: DataManager
    let child: Child
    let onBack: () -> Void
    
    @State private var showingTransactionForm = false
    @State private var selectedTransaction: Transaction?
    @State private var showingDeleteAlert = false
    
    var sortedTransactions: [Transaction] {
        child.transactions.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back to All Children")
                            .fontWeight(.semibold)
                    }
                    .font(.body)
                }
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            
            ScrollView {
                VStack(spacing: 16) {
                    // Balance Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(child.name)
                                    .font(.title3)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Balance")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Text(formatCurrency(child.netBalance))
                                    .font(.title2)
                                    .foregroundColor(child.netBalance >= 0 ? Color("OtherGreen") : .red)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    if child.isTithingEnabled {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tithing Balance")
                                .font(.headline)
                            
                            HStack {
                                Text(formatCurrency(child.tithingBalance))
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                
                                Spacer()
                                
                                Button(action: {
                                    dataManager.payTithing(for: child.id)
                                }) {
                                    Label("Mark as Paid", systemImage: "checkmark.circle")
                                }
                                .disabled(child.tithingBalance == 0)
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    // Add Transaction Button
                    Button(action: { showingTransactionForm = true }) {
                        Label("New Transaction", systemImage: "plus")
                            .font(.body)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    // Transaction History
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Transaction History")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        if sortedTransactions.isEmpty {
                            Text("No transactions yet")
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(sortedTransactions) { transaction in
                                    TransactionRow(transaction: transaction) {
                                        selectedTransaction = transaction
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    // Remove Child Button
                    Button(action: { showingDeleteAlert = true }) {
                        Text("Remove Child")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .background(Color.red)
                    .cornerRadius(12)
                    .padding(.top, 40)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
        .sheet(isPresented: $showingTransactionForm) {
            TransactionFormView(childId: child.id)
                .environmentObject(dataManager)
        }
        .sheet(item: $selectedTransaction) { transaction in
            TransactionFormView(childId: child.id, editingTransaction: transaction)
                .environmentObject(dataManager)
        }
        .alert("Confirm Deletion", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                dataManager.deleteChild(id: child.id)
                onBack()
            }
        } message: {
            Text("Are you sure you want to remove \(child.name)? This will permanently delete all transaction history and cannot be undone.")
        }
    }
}
