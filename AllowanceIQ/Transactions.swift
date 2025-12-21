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
        case tithingPayment
        case savingsDeposit
    }
}
