//
//  MAGICAL_AcademyApp.swift
//  MAGICAL Academy
//
//  Created by arash parnia on 11/2/23.
//

import SwiftUI

@main
struct MAGICAL_Academy: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
