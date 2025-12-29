//
//  AllownaceIQApp.swift
//  AllownaceIQ Watch App
//
//  Created by Brian Homer Jr on 12/6/25.
//

import SwiftUI

@main
struct AllownaceIQWatchApp: App {
    init() {
        ConnectivityProvider.shared.startSession()
    }

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(DataManager())
        }
    }
}
