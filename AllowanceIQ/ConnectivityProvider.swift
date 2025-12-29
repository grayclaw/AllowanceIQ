//
//  ConnectivityProvider.swift
//  AllowanceIQ
//
//  Created by Brian Homer Jr on 12/27/25.
//

import WatchConnectivity
import Combine

class ConnectivityProvider: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = ConnectivityProvider()
    weak var dataManager: DataManager?

    @Published var children: [Child] = []

    private override init() {
        super.init()
        startSession()
    }

    func startSession() {
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // Receive data
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let data = message["children"] as? Data,
           let decoded = try? JSONDecoder().decode([Child].self, from: data) {
            DispatchQueue.main.async {
                self.children = decoded
                self.dataManager?.children = decoded   // 👈 update DataManager
            }
        }
    }

    // Required WCSessionDelegate methods (with conditional compilation)
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) { }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) { }
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    #endif

    func sessionReachabilityDidChange(_ session: WCSession) { }
}
