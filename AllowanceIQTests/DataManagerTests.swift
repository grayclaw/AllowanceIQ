//
//  DataManagerTests.swift
//  AllowanceIQ
//
//  Created by Brian Homer Jr on 11/24/25.
//
//  Unit tests for DataManager
//

import XCTest
import Combine
@testable import AllowanceIQ

final class DataManagerTests: XCTestCase {
    var dataManager: DataManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        dataManager = DataManager()
        cancellables = []
        
        // Clear any existing data
        UserDefaults.standard.removeObject(forKey: "allowance-tracker-data")
        dataManager.children = []
    }
    
    override func tearDown() {
        dataManager = nil
        cancellables = nil
        UserDefaults.standard.removeObject(forKey: "allowance-tracker-data")
        super.tearDown()
    }
    
    // MARK: - Add Child Tests
    
    func testAddChild() {
        // Given
        let expectation = XCTestExpectation(description: "Child added")
        
        dataManager.$children
            .dropFirst()
            .sink { children in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        dataManager.addChild(name: "Alice", birthYear: 2015, isTithingEnabled: true)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(dataManager.children.count, 1)
        XCTAssertEqual(dataManager.children.first?.name, "Alice")
        XCTAssertEqual(dataManager.children.first?.birthYear, 2015)
        XCTAssertEqual(dataManager.children.first?.balance, 0)
        XCTAssertTrue(dataManager.children.first?.isTithingEnabled ?? false)
    }
    
    func testAddMultipleChildren() {
        // When
        dataManager.addChild(name: "Alice", birthYear: 2015, isTithingEnabled: true)
        dataManager.addChild(name: "Bob", birthYear: 2018, isTithingEnabled: false)
        
        // Then
        XCTAssertEqual(dataManager.children.count, 2)
        XCTAssertEqual(dataManager.children[0].name, "Alice")
        XCTAssertEqual(dataManager.children[1].name, "Bob")
    }
    
    // MARK: - Delete Child Tests
    
    func testDeleteChild() {
        // Given
        dataManager.addChild(name: "Alice", birthYear: 2015, isTithingEnabled: true)
        dataManager.addChild(name: "Bob", birthYear: 2018, isTithingEnabled: false)
        let aliceId = dataManager.children.first(where: { $0.name == "Alice" })!.id
        
        // When
        dataManager.deleteChild(id: aliceId)
        
        // Then
        XCTAssertEqual(dataManager.children.count, 1)
        XCTAssertEqual(dataManager.children.first?.name, "Bob")
    }
    
    func testDeleteNonExistentChild() {
        // Given
        dataManager.addChild(name: "Alice", birthYear: 2015, isTithingEnabled: true)
        let originalCount = dataManager.children.count
        
        // When
        dataManager.deleteChild(id: "non-existent-id")
        
        // Then
        XCTAssertEqual(dataManager.children.count, originalCount)
    }
    
    // MARK: - Transaction Tests
    
    func testAddDepositTransaction() {
        // Given
        dataManager.addChild(name: "Alice", birthYear: 2015, isTithingEnabled: false)
        let childId = dataManager.children.first!.id
        
        // When
        dataManager.addTransaction(childId: childId, type: .deposit, amount: 10.0, note: "Allowance")
        
        // Then
        let child = dataManager.children.first!
        XCTAssertEqual(child.balance, 10.0)
        XCTAssertEqual(child.transactions.count, 1)
        XCTAssertEqual(child.transactions.first?.type, .deposit)
        XCTAssertEqual(child.transactions.first?.amount, 10.0)
        XCTAssertEqual(child.transactions.first?.note, "Allowance")
    }
    
    func testAddWithdrawalTransaction() {
        // Given
        dataManager.addChild(name: "Alice", birthYear: 2015, isTithingEnabled: false)
        let childId = dataManager.children.first!.id
        dataManager.addTransaction(childId: childId, type: .deposit, amount: 20.0, note: "Initial")
        
        // When
        dataManager.addTransaction(childId: childId, type: .withdrawal, amount: 5.0, note: "Toy")
        
        // Then
        let child = dataManager.children.first!
        XCTAssertEqual(child.balance, 15.0)
        XCTAssertEqual(child.transactions.count, 2)
    }
    
    func testDepositWithTithing() {
        // Given
        dataManager.addChild(name: "Alice", birthYear: 2015, isTithingEnabled: true)
        let childId = dataManager.children.first!.id
        
        // When
        dataManager.addTransaction(childId: childId, type: .deposit, amount: 100.0, note: "Allowance")
        
        // Then
        let child = dataManager.children.first!
        XCTAssertEqual(child.balance, 100.0)
        XCTAssertEqual(child.tithingBalance, 10.0)
        XCTAssertEqual(child.netBalance, 90.0)
    }
    
    func testWithdrawalDoesNotAffectTithing() {
        // Given
        dataManager.addChild(name: "Alice", birthYear: 2015, isTithingEnabled: true)
        let childId = dataManager.children.first!.id
        dataManager.addTransaction(childId: childId, type: .deposit, amount: 100.0, note: "Allowance")
        
        // When
        dataManager.addTransaction(childId: childId, type: .withdrawal, amount: 20.0, note: "Toy")
        
        // Then
        let child = dataManager.children.first!
        XCTAssertEqual(child.balance, 80.0)
        XCTAssertEqual(child.tithingBalance, 10.0)
    }
    
    // MARK: - Tithing Tests
    
    func testPayTithing() {
        // Given
        dataManager.addChild(name: "Alice", birthYear: 2015, isTithingEnabled: true)
        let childId = dataManager.children.first!.id
        dataManager.addTransaction(childId: childId, type: .deposit, amount: 100.0, note: "Allowance")
        
        // When
        dataManager.payTithing(for: childId)
        
        // Then
        let child = dataManager.children.first!
        XCTAssertEqual(child.balance, 90.0)
        XCTAssertEqual(child.tithingBalance, 0.0)
        
        // Verify tithing payment transaction was added
        let tithingTransaction = child.transactions.first(where: { $0.note == "Tithing payment" })
        XCTAssertNotNil(tithingTransaction)
        XCTAssertEqual(tithingTransaction?.type, .withdrawal)
        XCTAssertEqual(tithingTransaction?.amount, 10.0)
    }
    
    func testPayTithingWithZeroBalance() {
        // Given
        dataManager.addChild(name: "Alice", birthYear: 2015, isTithingEnabled: true)
        let childId = dataManager.children.first!.id
        
        // When
        dataManager.payTithing(for: childId)
        
        // Then
        let child = dataManager.children.first!
        XCTAssertEqual(child.balance, 0.0)
        XCTAssertEqual(child.tithingBalance, 0.0)
        XCTAssertEqual(child.transactions.count, 0)
    }
    
    // MARK: - Sorted Children Tests
    
    func testSortedChildren() {
        // Given
        dataManager.addChild(name: "Alice", birthYear: 2015, isTithingEnabled: true)
        dataManager.addChild(name: "Bob", birthYear: 2018, isTithingEnabled: false)
        dataManager.addChild(name: "Charlie", birthYear: 2012, isTithingEnabled: true)
        
        // When
        let sorted = dataManager.sortedChildren
        
        // Then
        XCTAssertEqual(sorted.count, 3)
        XCTAssertEqual(sorted[0].name, "Bob") // 2018 - youngest
        XCTAssertEqual(sorted[1].name, "Alice") // 2015
        XCTAssertEqual(sorted[2].name, "Charlie") // 2012 - oldest
    }
    
    // MARK: - Persistence Tests
    
    func testSaveAndLoadData() {
        // Given
        dataManager.addChild(name: "Alice", birthYear: 2015, isTithingEnabled: true)
        let childId = dataManager.children.first!.id
        dataManager.addTransaction(childId: childId, type: .deposit, amount: 50.0, note: "Test")
        
        // When
        let newDataManager = DataManager()
        
        // Then
        XCTAssertEqual(newDataManager.children.count, 1)
        XCTAssertEqual(newDataManager.children.first?.name, "Alice")
        XCTAssertEqual(newDataManager.children.first?.balance, 50.0)
        XCTAssertEqual(newDataManager.children.first?.transactions.count, 1)
    }
    
    // MARK: - Edge Cases
    
    func testNegativeBalance() {
        // Given
        dataManager.addChild(name: "Alice", birthYear: 2015, isTithingEnabled: false)
        let childId = dataManager.children.first!.id
        
        // When
        dataManager.addTransaction(childId: childId, type: .withdrawal, amount: 10.0, note: "Overdraft")
        
        // Then
        let child = dataManager.children.first!
        XCTAssertEqual(child.balance, -10.0)
    }
    
    func testMultipleDepositsAccumulateTithing() {
        // Given
        dataManager.addChild(name: "Alice", birthYear: 2015, isTithingEnabled: true)
        let childId = dataManager.children.first!.id
        
        // When
        dataManager.addTransaction(childId: childId, type: .deposit, amount: 50.0, note: "Week 1")
        dataManager.addTransaction(childId: childId, type: .deposit, amount: 50.0, note: "Week 2")
        
        // Then
        let child = dataManager.children.first!
        XCTAssertEqual(child.balance, 100.0)
        XCTAssertEqual(child.tithingBalance, 10.0)
    }
    
    // MARK: - Complete Workflow Tests
    
    func testCompleteAllowanceWorkflow() {
        // Scenario: Parent adds child, gives weekly allowance, child makes purchase
        
        // Add child
        dataManager.addChild(name: "Sarah", birthYear: 2014, isTithingEnabled: true)
        let childId = dataManager.children.first!.id
        
        // Week 1 allowance
        dataManager.addTransaction(childId: childId, type: .deposit, amount: 10.0, note: "Week 1 allowance")
        
        var child = dataManager.children.first!
        XCTAssertEqual(child.balance, 10.0)
        XCTAssertEqual(child.tithingBalance, 1.0)
        XCTAssertEqual(child.netBalance, 9.0)
        
        // Week 2 allowance
        dataManager.addTransaction(childId: childId, type: .deposit, amount: 10.0, note: "Week 2 allowance")
        
        child = dataManager.children.first!
        XCTAssertEqual(child.balance, 20.0)
        XCTAssertEqual(child.tithingBalance, 2.0)
        XCTAssertEqual(child.netBalance, 18.0)
        
        // Child buys toy
        dataManager.addTransaction(childId: childId, type: .withdrawal, amount: 15.0, note: "LEGO set")
        
        child = dataManager.children.first!
        XCTAssertEqual(child.balance, 5.0)
        XCTAssertEqual(child.tithingBalance, 2.0) // Tithing unchanged by withdrawal
        XCTAssertEqual(child.netBalance, 3.0)
        XCTAssertEqual(child.transactions.count, 3)
    }
    
    func testMultipleChildrenIndependentBalances() {
        // Add multiple children
        dataManager.addChild(name: "Alex", birthYear: 2015, isTithingEnabled: true)
        dataManager.addChild(name: "Sam", birthYear: 2017, isTithingEnabled: false)
        
        let alexId = dataManager.children.first(where: { $0.name == "Alex" })!.id
        let samId = dataManager.children.first(where: { $0.name == "Sam" })!.id
        
        // Alex gets $20
        dataManager.addTransaction(childId: alexId, type: .deposit, amount: 20.0, note: "Allowance")
        
        // Sam gets $15
        dataManager.addTransaction(childId: samId, type: .deposit, amount: 15.0, note: "Allowance")
        
        // Verify independent balances
        let alex = dataManager.children.first(where: { $0.name == "Alex" })!
        let sam = dataManager.children.first(where: { $0.name == "Sam" })!
        
        XCTAssertEqual(alex.balance, 20.0)
        XCTAssertEqual(alex.tithingBalance, 2.0)
        XCTAssertEqual(sam.balance, 15.0)
        XCTAssertEqual(sam.tithingBalance, 0.0) // Tithing disabled
    }
    
    func testTithingLifecycle() {
        // Complete tithing workflow
        
        dataManager.addChild(name: "Emma", birthYear: 2016, isTithingEnabled: true)
        let childId = dataManager.children.first!.id
        
        // Multiple deposits accumulate tithing
        dataManager.addTransaction(childId: childId, type: .deposit, amount: 50.0, note: "Birthday")
        dataManager.addTransaction(childId: childId, type: .deposit, amount: 30.0, note: "Chores")
        
        var child = dataManager.children.first!
        XCTAssertEqual(child.balance, 80.0)
        XCTAssertEqual(child.tithingBalance, 8.0)
        
        // Pay tithing
        dataManager.payTithing(for: childId)
        
        child = dataManager.children.first!
        XCTAssertEqual(child.balance, 72.0)
        XCTAssertEqual(child.tithingBalance, 0.0)
        
        // Verify tithing payment transaction
        let tithingTransaction = child.transactions.last!
        XCTAssertEqual(tithingTransaction.note, "Tithing payment")
        XCTAssertEqual(tithingTransaction.type, .withdrawal)
        XCTAssertEqual(tithingTransaction.amount, 8.0)
        
        // New deposits after paying tithing
        dataManager.addTransaction(childId: childId, type: .deposit, amount: 40.0, note: "More allowance")
        
        child = dataManager.children.first!
        XCTAssertEqual(child.balance, 112.0)
        XCTAssertEqual(child.tithingBalance, 4.0) // Fresh tithing balance
    }
    
    func testPersistenceAcrossInstances() {
        // Create and save data
        dataManager.addChild(name: "Oliver", birthYear: 2013, isTithingEnabled: true)
        let childId = dataManager.children.first!.id
        dataManager.addTransaction(childId: childId, type: .deposit, amount: 100.0, note: "Gift")
        dataManager.addTransaction(childId: childId, type: .withdrawal, amount: 25.0, note: "Game")
        
        // Create new instance (simulating app restart)
        let newDataManager = DataManager()
        
        // Verify data persisted
        XCTAssertEqual(newDataManager.children.count, 1)
        
        let oliver = newDataManager.children.first!
        XCTAssertEqual(oliver.name, "Oliver")
        XCTAssertEqual(oliver.balance, 75.0)
        XCTAssertEqual(oliver.tithingBalance, 10.0)
        XCTAssertEqual(oliver.transactions.count, 2)
    }
    
    func testTransactionHistory() {
        // Verify transaction ordering and history
        
        dataManager.addChild(name: "Sophia", birthYear: 2015, isTithingEnabled: false)
        let childId = dataManager.children.first!.id
        
        // Add transactions with delays to ensure different timestamps
        dataManager.addTransaction(childId: childId, type: .deposit, amount: 10.0, note: "First")
        Thread.sleep(forTimeInterval: 0.1)
        
        dataManager.addTransaction(childId: childId, type: .deposit, amount: 20.0, note: "Second")
        Thread.sleep(forTimeInterval: 0.1)
        
        dataManager.addTransaction(childId: childId, type: .withdrawal, amount: 5.0, note: "Third")
        
        let child = dataManager.children.first!
        let transactions = child.transactions
        
        // Verify transactions are in chronological order
        XCTAssertEqual(transactions.count, 3)
        XCTAssertEqual(transactions[0].note, "First")
        XCTAssertEqual(transactions[1].note, "Second")
        XCTAssertEqual(transactions[2].note, "Third")
        
        // Verify running balance
        XCTAssertEqual(child.balance, 25.0) // 10 + 20 - 5
    }
    
    func testDeleteChildRemovesAllData() {
        // Verify complete cleanup on delete
        
        dataManager.addChild(name: "Liam", birthYear: 2018, isTithingEnabled: true)
        let childId = dataManager.children.first!.id
        
        // Add some transactions
        dataManager.addTransaction(childId: childId, type: .deposit, amount: 50.0, note: "Money")
        dataManager.addTransaction(childId: childId, type: .deposit, amount: 30.0, note: "More money")
        
        XCTAssertEqual(dataManager.children.count, 1)
        XCTAssertEqual(dataManager.children.first!.transactions.count, 2)
        
        // Delete child
        dataManager.deleteChild(id: childId)
        
        // Verify everything is gone
        XCTAssertEqual(dataManager.children.count, 0)
        
        // Verify persistence
        let newDataManager = DataManager()
        XCTAssertEqual(newDataManager.children.count, 0)
    }
    
    func testNegativeBalanceScenario() {
        // Child spends more than they have
        
        dataManager.addChild(name: "Mia", birthYear: 2014, isTithingEnabled: false)
        let childId = dataManager.children.first!.id
        
        dataManager.addTransaction(childId: childId, type: .deposit, amount: 10.0, note: "Initial")
        dataManager.addTransaction(childId: childId, type: .withdrawal, amount: 25.0, note: "Expensive toy")
        
        let child = dataManager.children.first!
        XCTAssertEqual(child.balance, -15.0)
        XCTAssertEqual(child.netBalance, -15.0)
        
        // Repay debt
        dataManager.addTransaction(childId: childId, type: .deposit, amount: 20.0, note: "Repayment")
        
        let updatedChild = dataManager.children.first!
        XCTAssertEqual(updatedChild.balance, 5.0)
    }
    
    func testSortingWithMultipleChildren() {
        // Add children in random order
        dataManager.addChild(name: "Middle", birthYear: 2016, isTithingEnabled: true)
        dataManager.addChild(name: "Youngest", birthYear: 2020, isTithingEnabled: true)
        dataManager.addChild(name: "Oldest", birthYear: 2012, isTithingEnabled: true)
        dataManager.addChild(name: "Second", birthYear: 2014, isTithingEnabled: true)
        
        let sorted = dataManager.sortedChildren
        
        // Verify sorting by birth year (youngest first)
        XCTAssertEqual(sorted[0].name, "Youngest") // 2020
        XCTAssertEqual(sorted[1].name, "Middle")   // 2016
        XCTAssertEqual(sorted[2].name, "Second")   // 2014
        XCTAssertEqual(sorted[3].name, "Oldest")   // 2012
    }
    
    func testConcurrentTransactions() {
        // Simulate multiple quick transactions
        
        dataManager.addChild(name: "Noah", birthYear: 2017, isTithingEnabled: true)
        let childId = dataManager.children.first!.id
        
        // Rapid transactions
        for i in 1...10 {
            dataManager.addTransaction(childId: childId, type: .deposit, amount: Double(i), note: "Transaction \(i)")
        }
        
        let child = dataManager.children.first!
        XCTAssertEqual(child.transactions.count, 10)
        
        // Verify total: 1+2+3+4+5+6+7+8+9+10 = 55
        XCTAssertEqual(child.balance, 55.0)
        
        // Verify tithing: 10% of 55 = 5.5
        XCTAssertEqual(child.tithingBalance, 5.5)
    }
    
    func testChildAgeCalculation() {
        let currentYear = Calendar.current.component(.year, from: Date())
        
        dataManager.addChild(name: "Teen", birthYear: currentYear - 13, isTithingEnabled: false)
        dataManager.addChild(name: "Baby", birthYear: currentYear - 1, isTithingEnabled: false)
        dataManager.addChild(name: "Adult", birthYear: currentYear - 19, isTithingEnabled: false)
        
        let teen = dataManager.children.first(where: { $0.name == "Teen" })!
        let baby = dataManager.children.first(where: { $0.name == "Baby" })!
        let adult = dataManager.children.first(where: { $0.name == "Adult" })!
        
        XCTAssertEqual(teen.age, 13)
        XCTAssertEqual(baby.age, 1)
        XCTAssertEqual(adult.age, 19)
    }
    
    func testMixedTithingAndNonTithing() {
        // One child with tithing, one without
        
        dataManager.addChild(name: "WithTithing", birthYear: 2015, isTithingEnabled: true)
        dataManager.addChild(name: "WithoutTithing", birthYear: 2016, isTithingEnabled: false)
        
        let withId = dataManager.children.first(where: { $0.name == "WithTithing" })!.id
        let withoutId = dataManager.children.first(where: { $0.name == "WithoutTithing" })!.id
        
        // Same amount to both
        dataManager.addTransaction(childId: withId, type: .deposit, amount: 100.0, note: "Money")
        dataManager.addTransaction(childId: withoutId, type: .deposit, amount: 100.0, note: "Money")
        
        let withTithing = dataManager.children.first(where: { $0.name == "WithTithing" })!
        let withoutTithing = dataManager.children.first(where: { $0.name == "WithoutTithing" })!
        
        // Both have same balance
        XCTAssertEqual(withTithing.balance, 100.0)
        XCTAssertEqual(withoutTithing.balance, 100.0)
        
        // But different net balances
        XCTAssertEqual(withTithing.netBalance, 90.0)
        XCTAssertEqual(withoutTithing.netBalance, 100.0)
        
        // And different tithing balances
        XCTAssertEqual(withTithing.tithingBalance, 10.0)
        XCTAssertEqual(withoutTithing.tithingBalance, 0.0)
    }
}
