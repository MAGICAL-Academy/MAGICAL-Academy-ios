//
//  AssistantGenerator.swift
//  MAGICAL Academy
//
//  Created by arash parnia on 11/9/23.
//
import os.log
import Foundation

class AssistantGenerator {
    var chatGPTService: AssistantService
    var difficulty: Int
    var age: Int
    private var startTime: Date?
    private var endTime: Date?
    private let logger = Logger()
    
    init(difficulty: Int = 1, age: Int = 4) {
        self.chatGPTService = AssistantService()
        self.difficulty = difficulty
        self.age = age
    }
    
 
    
    func generateAndStoreThreadId(completion: @escaping (Result<String, Error>) -> Void) {
        // Check if a thread ID already exists in UserDefaults
        if let savedThreadId = UserDefaults.standard.string(forKey: "ThreadId") {
            completion(.success(savedThreadId))
        } else {
            
            // Create an instance of AssistantThreadManager
            let assistantManager = AssistantThreadManager(apiKey: AssistantService.fetchAPIKey(), assistantId: "asst_T7HClKQYmKUNOJmxlKW79XWQ")

            // Define the initial messages for the thread
            let messages = [
                [
                    "role": "user",
                    "content": """
                        Create an arithmetic exercise suitable for a \(self.age)-year-old child.
                        The difficulty level should start at \(self.difficulty).
                        """
                ]
            ]

            // Initialize the thread with messages
            assistantManager.initializeThreadWithMessages(messages: messages) { result in
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
        let messages = [
            [
                "role": "user",
                "content": """
                    Create an arithmetic exercise suitable for a \(self.age)-year-old child.
                    Use the setting of '\(place)' and include a character who is a '\(character)'.
                    The difficulty level is \(self.difficulty). Provide the exercise and wait for a response to give the answer.
                    """
            ]
        ]

        chatGPTService.runAssistant(with: messages) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let (threadId, runId)):
                    completion(threadId, runId)
                case .failure(_):
                    completion("", "")
                }
            }
        }
    }




    
    
    func checkStatus(runId: String, threadId: String, completion: @escaping (String) -> Void) {
        // Call the fetchRunStatus method on chatGPTService
        chatGPTService.fetchRunStatus(runId: runId, threadId: threadId) { status, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion("failed")
                } else {
                    completion(status)
                }
            }
        }
    }

    // Function to fetch the latest message for a thread
    func getLatestAssistantMessage(threadId: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Assuming you have a method in your chatGPTService to fetch messages for a thread
        chatGPTService.fetchMessagesForThread(threadId: threadId) { result in
            switch result {
            case .success(let messages):
                // Successfully fetched messages, parse them into Message objects
                if let assistantMessage = messages["assistant"] {
                    completion(.success(assistantMessage))
                } else {
                    // No messages from the assistant found
                    completion(.failure(NSError(domain: "YourAppErrorDomain", code: 0, userInfo: nil)))
                }
                
            case .failure(let error):
                // Handle the error if fetching messages fails
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
}

