//
//  AI_TutorApp.swift
//  AI Tutor
//
//  Created by arash parnia on 11/2/23.
//

import SwiftUI

@main
struct AI_TutorApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
