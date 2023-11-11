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
                    logger.log("App onAppear called.", level: .debug)
                    UserDefaults.standard.set(nil, forKey: "ThreadId")
                    // Check if a thread ID exists in UserDefaults
                    if let existingThreadId = UserDefaults.standard.string(forKey: "ThreadId") {
                        logger.log("Thread ID already exists: \(existingThreadId)", level: .debug)
                    } else {
                        // Create a background queue for the initial setup
                        DispatchQueue.global().async {
                            logger.log("Dispatch started.", level: .debug)
                            
                            // Create an instance of AssistantGenerator and call generateAndStoreThreadId
                            let assistantGenerator = AssistantGenerator(difficulty: 1, age: 4)
                            assistantGenerator.generateAndStoreThreadId { result in
                                switch result {
                                case .success(let newThreadId):
                                    // Thread ID generated and stored successfully
                                    UserDefaults.standard.set(newThreadId, forKey: "ThreadId")
                                    logger.log("ThreadId generated: \(newThreadId)", level: .debug)
                                case .failure(let error):
                                    // Handle the error if thread ID generation fails
                                    logger.log("Error generating thread ID: \(error)", level: .error)
                                }
                            }
                            
                            logger.log("Dispatch in progress.", level: .debug)
                        }
                    }
                }
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
