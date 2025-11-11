//
//  ASAM_LOC_1_0App.swift
//  ASAM_LOC_1.0
//
//  Created by Kevin Dial on 11/11/25.
//

import SwiftUI
import SwiftData

@main
struct ASAM_LOC_1_0App: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
