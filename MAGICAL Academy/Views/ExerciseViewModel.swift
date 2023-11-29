import Foundation

class ExerciseViewModel: ObservableObject {
    @Published var currentExercise: ExerciseContentResponse?
    @Published var questions: [Question] = []
    @Published var selectedOptions: [Int: Int] = [:]  // Store selected answers

    private var currentQuestionIndex = 0
    private var currentDifficulty = 1  // Initial difficulty level
    private let maxDifficulty = 5  // Maximum difficulty level
    private let api = MagicalAcademyAPI()
    private let selectedScenario: String
    private let selectedCharacter: String

    struct Question: Hashable { // Conform to Hashable
           let exercise: String
           let answer: Int
           var options: [String] = []
           
           // Implement the Hashable protocol's hash(into:) method
           func hash(into hasher: inout Hasher) {
               hasher.combine(exercise)
               hasher.combine(answer)
               // You can combine more properties if needed
           }
           
           // Implement the == operator to compare instances for equality
           static func ==(lhs: Question, rhs: Question) -> Bool {
               return lhs.exercise == rhs.exercise && lhs.answer == rhs.answer
               // Compare more properties if needed
           }
       }

    init(selectedScenario: String, selectedCharacter: String) {
        self.selectedScenario = selectedScenario
        self.selectedCharacter = selectedCharacter
    }

    func fetchExercise() {
        // Update difficulty level based on user progress
        if currentDifficulty < maxDifficulty {
            currentDifficulty += 1
        }
        
        api.generateExerciseContent(age: "4", difficulty: String(currentDifficulty), scenario: selectedScenario, character: selectedCharacter) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let exerciseResponse):
                    self.currentExercise = exerciseResponse
                    self.generateNextQuestion()
                case .failure(let error):
                    print("API Error in fetchExercise: \(error)")
                }
            }
        }
    }

    private var duplicateQuestionCount = 0
    private let maxDuplicateCount = 2  // Maximum times a duplicate is allowed

    func generateNextQuestion() {
        if let exerciseResponse = currentExercise {
            let exercise = exerciseResponse.content.exercise
            if let answer = Int(exerciseResponse.content.answer.trimmingCharacters(in: .whitespacesAndNewlines)) {
                let options = self.generateOptionsForQuestion(exercise: exercise, answer: answer)
                let newQuestion = Question(exercise: exercise, answer: answer, options: options)
                
                // Check if the new question is not a duplicate
                if !questions.contains(where: { $0.exercise == newQuestion.exercise }) {
                    self.questions.append(newQuestion)
                    self.currentQuestionIndex = self.questions.count - 1
                    duplicateQuestionCount = 0  // Reset duplicate count
                } else {
                    duplicateQuestionCount += 1
                    if duplicateQuestionCount > maxDuplicateCount {
                        // Stop generating questions and notify that it's finished
                        print("No more unique questions available. Finished!")
                        return
                    }
                }
            } else {
                print("Error: Invalid data received in generateNextQuestion")
                print(exerciseResponse)
            }
        } else {
            print("Error: Invalid exercise data format received")
        }
    }


    private func generateOptionsForQuestion(exercise: String, answer: Int) -> [String] {
        var options: [Int] = [answer]

        while options.count < 3 { // Ensure a total of 3 options (including the correct answer)
            let randomOffset = Int.random(in: -10...10)
            let incorrectOption = answer + randomOffset
            if !options.contains(incorrectOption) {
                options.append(incorrectOption)
            }
        }

        options.shuffle()
        return options.map { String($0) }
    }


    func saveAnswer(for questionIndex: Int, answer: Int) {
        selectedOptions[questionIndex] = answer
        fetchExercise() // Fetch the next exercise after the user answers the current question
    }
}
