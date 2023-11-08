
import Foundation

class ExerciseGenerator {
    var chatGPTService: ChatGPTService
    var difficulty: Int
    var age: Int
    private var startTime: Date?
    private var endTime: Date?
    
    init(apiKey: String, difficulty: Int = 1, age: Int = 4) {
        self.chatGPTService = ChatGPTService(apiKey: apiKey)
        self.difficulty = difficulty
        self.age = age
    }
    
    func generateExercise(completion: @escaping (String) -> Void) {
        let prompt = """
        You are a friendly math tutor specializing in teaching young children,
        specifically \(self.age)-year-olds, the basics of arithmetic in a fun and engaging way.
        Your goal is to create a simple and enjoyable arithmetic exercise
        that helps a \(self.age)-year-old understand age appropriate arithmetic.
        The exercise should involve arithmetic of two small numbers,
        and it should be framed in a playful scenario that would appeal to a young child's imagination.
        The problem will vary in difficulty but even the highest difficulty should be appropriate for a small child.
        Please set the difficulty to \(self.difficulty). Only reply with the problem itself and nothing else.
        """
        
        chatGPTService.fetchResponse(for: prompt) { result in
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
        let prompt = """
        Adjust difficulty based on correctness: \(correctness) and time taken: \(timeTaken).
        Current difficulty: \(self.difficulty).
        If the time is less than one minute that means we can move on to a higher difficulty \(self.difficulty + 1).
        If the time is really long even if the answer is correct we should stay with current difficulty.
        If the time is really long and the answer is wrong then we should go back one level of difficulty.
        """
        
        chatGPTService.fetchResponse(for: prompt) { result in
            switch result {
            case .success(let response):
                if let newDifficulty = self.extractNumber(from: response) {
                    self.difficulty = newDifficulty
                }
            case .failure(let error):
                print("Failed to adjust difficulty: \(error)")
            }
        }
    }
    
    func getSolution(for problem: String, completion: @escaping (Int?) -> Void) {
        let prompt = "Return only the numerical solution for the problem: \(problem)"
        
        chatGPTService.fetchResponse(for: prompt) { result in
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
