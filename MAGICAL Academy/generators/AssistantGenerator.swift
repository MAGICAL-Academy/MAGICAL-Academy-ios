//
//  AssistantGenerator.swift
//  MAGICAL Academy
//
//  Created by arash parnia on 11/9/23.
//
import os.log
import Foundation
import AVFoundation

class AssistantGenerator {
    var chatGPTService: ChatGPTService
    var difficulty: Int
    var age: Int
    private var startTime: Date?
    private var endTime: Date?
    private let logger = Logger()
    
    init(difficulty: Int = 1, age: Int = 4) {
        self.chatGPTService = ChatGPTService()
        self.difficulty = difficulty
        self.age = age
    }
    
 
    
    func generateAndStoreThreadId(completion: @escaping (Result<String, Error>) -> Void) {
        // Check if a thread ID already exists in UserDefaults
        if let savedThreadId = UserDefaults.standard.string(forKey: "ThreadId") {
            completion(.success(savedThreadId))
        } else {
            

            // Define the initial messages for the thread
            let messages = [
                [
                    "role": "user",
                    "content": """
                        This will be read be read by the text to voice api and then played for the user. Do a short welcome message for the user.
                        """
                ]
            ]

            // Initialize the thread with messages
            chatGPTService.initializeThreadWithMessages(messages: messages) { result in
                switch result {
                case .success(let threadId):
                    completion(.success(threadId)) // Pass the threadId to .success
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }


    
    func generateExercise(place: String, character: String, completion: @escaping (String, String) -> Void) {
        let message = [
            "role": "user",
            "content": """
                Create an arithmetic exercise suitable for a \(self.age)-year-old child.
                Use the setting of '\(place)' and include a character who is a '\(character)'.
                The difficulty level is \(self.difficulty). Provide the exercise and the answer in json format.
                """
        ]

        // Retrieve the existing ThreadId from UserDefaults
        if let threadId = UserDefaults.standard.string(forKey: "ThreadId") {
            // Add the new message to the existing thread
            self.chatGPTService.addMessagesToThread(threadId: threadId, messages: [message]) { addMessagesResult in
                switch addMessagesResult {
                case .success:
                    // Execute the run for the existing thread
                    self.chatGPTService.executeRun(threadId: threadId) { createRunResult in
                        switch createRunResult {
                        case .success(let runId):
                            // Return the threadId and runId
                            completion(threadId, runId)
                        case .failure(_):
                            completion("", "")
                        }
                    }
                case .failure(_):
                    completion("", "")
                }
            }
        } else {
            // Handle the case where the ThreadId is not found in UserDefaults
            completion("", "")
        }
    }




    
    
    func checkStatus(runId: String, threadId: String, completion: @escaping (String) -> Void) {
        // Call the fetchRunStatus method on chatGPTService
        chatGPTService.fetchRunStatus(runId: runId, threadId: threadId) { status, error in
            DispatchQueue.main.async {
                if error != nil {
                    completion("failed")
                } else {
                    completion(status)
                }
            }
        }
    }

    func getExercise(threadId: String, completion: @escaping (Result<(exercise: String, result: Int), Error>) -> Void) {
        // Check the status of the latest run for the thread
        chatGPTService.getStatus(for: threadId) { statusResult in
            switch statusResult {
            case .success(let status):
                if status == "completed" {
                    // If the run is completed, fetch the latest message
                    self.chatGPTService.fetchLatestMessageForThread(threadId: threadId) { messageResult in
                        switch messageResult {
                        case .success(let message):
                            if let jsonData = message.data(using: .utf8),
                               let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
                               let jsonDict = jsonObject as? [String: Any],
                               let exercise = jsonDict["exercise"] as? String,
                               let answerStr = jsonDict["answer"] as? String,
                               let answer = Int(answerStr) {
                                completion(.success((exercise, answer)))
                            } else {
                                completion(.failure(NSError(domain: "YourAppErrorDomain", code: 0, userInfo: ["description": "Invalid format for 'messages' data"])))
                            }
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                } else {
                    // If the run is not completed, handle accordingly
                    completion(.failure(NSError(domain: "YourAppErrorDomain", code: 1, userInfo: ["description": "Run not completed"])))
                }
            case .failure(let error):
                // Handle the error if fetching run status fails
                completion(.failure(error))
            }
        }
    }








    
    
    func startTimer() {
        startTime = Date()
    }
    
    func stopTimer() {
        endTime = Date()
    }
    
    func getElapsedTime() -> TimeInterval? {
        guard let start = startTime, let end = endTime else { return nil }
        return end.timeIntervalSince(start)
    }
    
//    func getSolution(for problem: String, completion: @escaping (Int?) -> Void) {
//        let messages = [
//            [
//                "role": "user",
//                "content": "What is the answer to the problem?"
//            ],
//            [
//                "role": "system",
//                "content": problem
//            ]
//        ]
//        
//        chatGPTService.runAssistant(with: messages) { result in
//            DispatchQueue.main.async {
//                switch result {
//                case .success(let solutionText):
//                    let solution = self.extractNumber(from: solutionText)
//                    completion(solution)
//                case .failure(let error):
//                    print("Failed to get solution: \(error)")
//                    completion(nil)
//                }
//            }
//        }
//    }
    
    private func extractNumber(from text: String) -> Int? {
        // Extracts the first number found in the text using regex
        let regex = try! NSRegularExpression(pattern: "\\b\\d+\\b")
        let nsString = text as NSString
        let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
        
        guard let match = results.first else { return nil }
        return Int(nsString.substring(with: match.range))
    }
    
    func evaluatePerformance(userAnswer: Int, correctAnswer: Int) -> Bool {
        guard let elapsedTime = getElapsedTime() else { return false }
        let correctness = userAnswer == correctAnswer
        
        // Adjust difficulty based on the performance
        adjustDifficulty(correctness: correctness, timeTaken: elapsedTime)
        
        return correctness
    }
    
    
    func adjustDifficulty(correctness: Bool, timeTaken: TimeInterval) {
        // Define your thresholds for time taken
        let quickResponseTime = 60.0 // 1 minute
        let longResponseTime = 180.0 // 3 minutes
        
        if correctness && timeTaken < quickResponseTime {
            // If the answer is correct and the time taken is less than 1 minute, increase difficulty.
            difficulty += 1
        } else if !correctness || timeTaken > longResponseTime {
            // If the answer is incorrect, or the time taken is too long, decrease difficulty.
            difficulty = max(difficulty - 1, 1) // Ensure the difficulty doesn't go below 1.
        }
        // If the answer is correct and the time taken is reasonable, no change in difficulty.
    }
    
  

   
     func generateSpeechFromText(text: String, completion: @escaping (Result<Data, Error>) -> Void) {
         // Call the original function to generate speech
         self.chatGPTService.generateSpeechFromText(text: text) { result in
             switch result {
             case .success(let data):
                 // Handle success
                 completion(.success(data))
             case .failure(let error):
                 // Handle failure
                 completion(.failure(error))
             }
         }
     }
    
    func generateImageFromText(text: String, completion: @escaping (Result<[String], Error>) -> Void) {
        self.chatGPTService.generateImages(prompt: text) { result in
            switch result {
            case .success(let imageUrls):
                // Handle success by returning the image URLs
                completion(.success(imageUrls))
            case .failure(let error):
                // Handle failure
                completion(.failure(error))
            }
        }
    }

}

