//
//  AllowanceIQApp.swift
//  AllowanceIQ
//
//  Created by Brian Homer Jr on 11/24/25.
//

import SwiftUI
import CoreData

@main
struct AllowanceIQApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
