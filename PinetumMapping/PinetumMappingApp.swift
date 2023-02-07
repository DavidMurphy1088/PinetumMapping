//
//  PinetumMappingApp.swift
//  PinetumMapping
//
//  Created by David Murphy on 2/7/23.
//

import SwiftUI

@main
struct PinetumMappingApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
