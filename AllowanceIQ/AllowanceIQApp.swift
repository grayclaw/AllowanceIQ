//
//  AllowanceIQApp.swift
//  AllowanceIQ
//
//  Created by Brian Homer Jr on 11/24/25.
//

import SwiftUI

@main
struct AllowanceIQApp: App {
    @StateObject private var dataManager = DataManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
        }
    }
}
