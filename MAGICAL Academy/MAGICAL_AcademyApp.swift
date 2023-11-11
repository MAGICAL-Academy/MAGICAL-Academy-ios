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
    private let logger = Logger()
    var body: some Scene {
        WindowGroup {
            MainView()
                .onAppear {
                    print("check")
                    print("check")
                    print("check")
                    print("check")
                    print(UserDefaults.standard.string(forKey: "ThreadId"))
                    print("check")
                    print("check")
                    // Check if a thread ID exists in UserDefaults
                    if UserDefaults.standard.string(forKey: "ThreadId") == nil {
                        // Create a background queue for the initial setup
                        DispatchQueue.global().async {
                            // Create an instance of AssistantGenerator and call generateAndStoreThreadId
                            let assistantGenerator = AssistantGenerator(difficulty: 1, age: 4)
                            assistantGenerator.generateAndStoreThreadId { result in
                                switch result {
                                case .success(let newThreadId):
                                    // Thread ID generated and stored successfully
                                    UserDefaults.standard.set(newThreadId, forKey: "ThreadId")
                                    print(newThreadId)
                                    print(newThreadId)
                                    print(newThreadId)
                                    print(newThreadId)
                                    print(newThreadId)
                                    print(newThreadId)
                                    print(newThreadId)
                                    print(newThreadId)
                                    logger.log("ThreadId generated. \(newThreadId)", level: .debug)
                                case .failure(let error):
                                    // Handle the error if thread ID generation fails
                                    print("Error generating thread ID: \(error)")
                                }
                            }
                        }
                    }
                }
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
