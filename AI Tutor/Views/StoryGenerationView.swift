import SwiftUI

struct StoryGenerationView: View {
    // Properties to hold the incoming arguments
    var selectedScenario: String
    var selectedCharacter: String
    var selectedAttire: String
    
    @State private var storyPrompt: String = ""
    @State private var userAnswer: String = ""
    @State private var correctAnswer: Int?
    @State private var difficulty: Int = 1
    @State private var age: Int = 4
    @State private var answerOptions: [String] = []
    @State private var isAnswerCorrect: Bool? = nil
    
    // Initialize the ExerciseGenerator with the API key
    private var exerciseGenerator: ExerciseGenerator
    
    init(selectedScenario: String, selectedCharacter: String, selectedAttire: String) {
        // Initialize all the @State properties first
        self.storyPrompt = ""
        self.userAnswer = ""
        self.correctAnswer = nil
        self.difficulty = 1
        self.age = 4

        // Now, all properties of `self` are initialized, so we can use `self`
        self.selectedScenario = selectedScenario
        self.selectedCharacter = selectedCharacter
        self.selectedAttire = selectedAttire

        // Since all properties are initialized, you can now initialize exerciseGenerator
        self.exerciseGenerator = ExerciseGenerator(apiKey: "your-api-key", difficulty: 1, age: 4)
    }

    
    var body: some View {
        VStack {
            Text("Math Story Exercise")
                .font(.largeTitle)
            
            Text(storyPrompt)
                .padding()
            
            // Displaying multiple choice options
            ForEach(answerOptions, id: \.self) { option in
                Button(action: {
                    checkAnswer(selectedOption: option)
                }) {
                    HStack {
                        Text(option)
                        Spacer()
                        Text(emojiForOption(option))
                    }
                    .padding()
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .onAppear {
            fetchNewStoryPrompt()
        }
        .alert(isPresented: .constant(isAnswerCorrect != nil), content: {
            if isAnswerCorrect == true {
                return Alert(title: Text("Correct!"), message: Text("Great job!"), dismissButton: .default(Text("Next"), action: fetchNewStoryPrompt))
            } else {
                return Alert(title: Text("Oops!"), message: Text("Try again."), dismissButton: .default(Text("OK")))
            }
        })
    }
    
    // Function to generate emoji for each option
    private func emojiForOption(_ option: String) -> String {
        let emojis = ["🍎", "🍌", "🍇", "🍉"]
        if let index = answerOptions.firstIndex(of: option) {
            return emojis[index % emojis.count]
        }
        return "❓"
    }
    
    // Function to check the answer
    private func checkAnswer(selectedOption: String) {
        guard let selectedAnswer = Int(selectedOption), let correctAnswer = correctAnswer else { return }
        exerciseGenerator.startTimer()
        isAnswerCorrect = exerciseGenerator.evaluatePerformance(userAnswer: selectedAnswer, correctAnswer: correctAnswer)
        difficulty = exerciseGenerator.difficulty
    }
    
    private func fetchNewStoryPrompt() {
        // Use the customPrompt to generate the exercise
        exerciseGenerator.generateExercise { prompt in
            DispatchQueue.main.async {
                self.storyPrompt = prompt
                self.generateAnswerOptions()
            }
        }
    }
    
    // Generate multiple choice answers
    private func generateAnswerOptions() {
        // Fetch the correct answer
        exerciseGenerator.getSolution(for: storyPrompt) { solution in
            DispatchQueue.main.async {
                self.correctAnswer = solution
                // Generate the answer options once the correct answer is fetched
                if let correct = solution {
                    let incorrectOptions = (1...3).map { _ in Int.random(in: 1...10) }.filter { $0 != correct }
                    self.answerOptions = incorrectOptions.map { String($0) }
                    self.answerOptions.append(String(correct))
                    self.answerOptions.shuffle()
                }
            }
        }
    }
}

// Preview for SwiftUI Canvas
struct StoryGenerationView_Previews: PreviewProvider {
    static var previews: some View {
        StoryGenerationView(selectedScenario: "Park", selectedCharacter: "Wizard", selectedAttire: "Cape")
    }
}
