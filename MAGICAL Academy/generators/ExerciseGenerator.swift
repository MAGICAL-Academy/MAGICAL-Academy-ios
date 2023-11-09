
import Foundation

class ExerciseGenerator {
    var chatGPTService: ChatGPTService
    var difficulty: Int
    var age: Int
    private var startTime: Date?
    private var endTime: Date?
    
    init( difficulty: Int = 1, age: Int = 4) {
        self.chatGPTService = ChatGPTService()
        self.difficulty = difficulty
        self.age = age
    }
    
    func generateExercise(completion: @escaping (String) -> Void) {
        let messages = [
            [
                "role": "system",
                "content": """
                    You are a friendly math tutor specializing in teaching young children,
                    specifically \(self.age)-year-olds, the basics of arithmetic in a fun and engaging way.
                    Your goal is to create a simple and enjoyable arithmetic exercise
                    that helps a \(self.age)-year-old understand age-appropriate arithmetic.
                    The exercise should involve arithmetic of two small numbers,
                    and it should be framed in a playful scenario that would appeal to a young child's imagination.
                    The problem will vary in difficulty but even the highest difficulty should be appropriate for a small child.
                    Please set the difficulty to \(self.difficulty). Only reply with the problem itself and nothing else.
                    """
            ]
        ]
        
        chatGPTService.fetchResponse(for: messages) { result in
            switch result {
            case .success(let problem):
                completion(problem)
            case .failure(let error):
                print("Failed to generate exercise: \(error)")
            }
        }
    }

    
    func startTimer() {
        startTime = Date()
    }
    
    func stopTimer() {
        endTime = Date()
    }
    
    func extractNumber(from text: String) -> Int? {
        // Extracts the first number found in the text using regex
        let regex = try! NSRegularExpression(pattern: "\\b\\d+\\b")
        let nsString = text as NSString
        let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
        
        guard let match = results.first else { return nil }
        return Int(nsString.substring(with: match.range))
    }
    
    func evaluatePerformance(userAnswer: Int, correctAnswer: Int) -> Bool {
        guard let endTime = endTime, let startTime = startTime else { return false }
        let timeTaken = endTime.timeIntervalSince(startTime)
        
        let correctness = userAnswer == correctAnswer
        
        // Adjust difficulty based on the performance
        adjustDifficulty(correctness: correctness, timeTaken: timeTaken)
        
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

    
    func getSolution(for problem: String, completion: @escaping (Int?) -> Void) {
        let messages = [
            [
                "role": "system",
                "content": "Return only the numerical solution for the problem."
            ],
            [
                "role": "user",
                "content": "\(problem)"
            ]
        ]
        
        chatGPTService.fetchResponse(for: messages) { result in
            switch result {
            case .success(let solutionText):
                let solution = self.extractNumber(from: solutionText)
                completion(solution)
            case .failure(let error):
                print("Failed to get solution: \(error)")
                completion(nil)
            }
        }
    }

}
