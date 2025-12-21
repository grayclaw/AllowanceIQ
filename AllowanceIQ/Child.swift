//
//  Child.swift
//  AllowanceIQ
//
//  Created by Brian Homer Jr on 11/20/25.
//

import SwiftUI

struct Child: Identifiable, Codable {
    let id: String
    var name: String
    var birthYear: Int
    var balance: Double
    var transactions: [Transaction]
    var tithingBalance: Double = 0
    var isTithingEnabled: Bool = true
    var isSavingsEnabled: Bool = false
    var savingsPercentage: Double = 0
    var savingsBalance: Double = 0

    var age: Int {
        Calendar.current.component(.year, from: Date()) - birthYear
    }

    var netBalance: Double {
        balance - tithingBalance - savingsBalance
    }
}
