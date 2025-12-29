//
//  Transactions.swift
//  AllowanceIQ
//
//  Created by Brian Homer Jr on 11/20/25.
//

import SwiftUI
import Foundation

struct Transaction: Identifiable, Codable {
    enum TransactionType: String, Codable {
        case deposit
        case withdrawal
        case tithingPayment
        case savingsDeposit
    }

    let id: String
    var type: TransactionType
    var amount: Double
    var note: String
    var date: Date
}

