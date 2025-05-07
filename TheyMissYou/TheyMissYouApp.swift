//
//  TheyMissYouApp.swift
//  TheyMissYou
//
//  Created by Xcode on 4/14/25.
//

import SwiftUI
import FirebaseCore

@main
struct TheyMissYouApp: App {
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
