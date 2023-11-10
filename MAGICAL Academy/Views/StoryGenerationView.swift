import SwiftUI
import Combine

struct StoryGenerationView: View {
    // Properties to hold the incoming arguments
    var selectedScenario: String
    var selectedCharacter: String
    
    @State private var storyPrompt: String = ""
    @State private var userAnswer: String = ""
    @State private var correctAnswer: Int?
    @State private var difficulty: Int = 1
    @State private var age: Int = 4
    @State private var answerOptions: [String] = []
    @State private var isAnswerCorrect: Bool? = nil
    @State private var isCheckingStatus: Bool = false
    @State private var cancellables: Set<AnyCancellable> = []
    @State private var runId: String?
    @State private var threadId: String?

    
    // Initialize the ExerciseGenerator with the API key
    private var assistantGenerator: AssistantGenerator
    
    // Timer to check the status periodically
    let checkStatusTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    init(selectedScenario: String, selectedCharacter: String) {
        self.selectedScenario = selectedScenario
        self.selectedCharacter = selectedCharacter
        self.assistantGenerator = AssistantGenerator(difficulty: 1, age: 4)
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
                        // Use the option directly since it already contains an emoji
                        Text(option)
                    }
                    .padding()
                }
                .buttonStyle(.bordered)
            }
            
            if isCheckingStatus {
                ProgressView("Checking status...")
            }
            
            Spacer()
        }
        .onAppear {
            fetchNewStoryPrompt()
        }
        .onReceive(checkStatusTimer) { _ in
            checkAssistantStatus()
        }
        .alert(isPresented: .constant(isAnswerCorrect != nil), content: {
            if isAnswerCorrect == true {
                return Alert(title: Text("Correct!"), message: Text("Great job!"), dismissButton: .default(Text("Next"), action: fetchNewStoryPrompt))
            } else {
                return Alert(title: Text("Oops!"), message: Text("Try again."), dismissButton: .default(Text("OK")))
            }
        })
        .onDisappear {
            // Cancel the timer when the view disappears
            cancellables.forEach { $0.cancel() }
        }
    }
    
 



    private func checkAssistantStatus() {
        guard let currentRunId = runId, let currentThreadId = threadId else {
            print("Run ID or Thread ID is missing.")
            return
        }

        isCheckingStatus = true

        self.assistantGenerator.checkStatus(runId: currentRunId, threadId: currentThreadId) { status in
            DispatchQueue.main.async {
                if status == "completed" {
                    // Update your UI with the new data
                    // ...

                    isCheckingStatus = false
                    self.cancellables.forEach { $0.cancel() }
                } else if status == "failed" {
                    // Handle a failed status
                    // ...
                }
                // If status is still in progress, do nothing and let the timer call this method again
            }
        }
    }

    


    
    private func checkAnswer(selectedOption: String) {
        // Extract the numeric part from the selected option, ignoring any emoji or non-numeric characters.
       guard let selectedAnswer = Int(selectedOption.filter("0123456789".contains)),
             let correctNumber = correctAnswer else { return }

        // Start the timer when the user selects an answer (if not already started when the question is presented).
        assistantGenerator.startTimer()

        // Evaluate the performance and get a Boolean result indicating if the answer was correct.
        isAnswerCorrect = assistantGenerator.evaluatePerformance(userAnswer: selectedAnswer, correctAnswer: correctNumber)

        // Update the difficulty level based on the evaluation of the user's performance.
        difficulty = assistantGenerator.difficulty

        // Stop the timer after the performance evaluation.
        assistantGenerator.stopTimer()
    }


    private func fetchNewStoryPrompt() {
        // Use the ExerciseGenerator to generate the exercise
        assistantGenerator.generateExercise(place: selectedScenario, character: selectedCharacter) { threadId, runId in
            DispatchQueue.main.async {
                // Store the threadId and runId
                self.threadId = threadId
                self.runId = runId
                
//                self.generateAnswerOptions()
            }
        }
    }
    
    // Generate multiple choice answers with emojis
//    private func generateAnswerOptions() {
//        // Fetch the correct answer
//        assistantGenerator.getSolution(for: storyPrompt) { solution in
//            DispatchQueue.main.async {
//                self.correctAnswer = solution
//                
//                // Generate answer options with emojis
//                if let correct = solution {
//                    self.answerOptions = self.generateEmojiOptions(for: correct)
//                }
//            }
//        }
//    }
    
    private func generateEmojiOptions(for answer: Int) -> [String] {
        // Define a base emoji to use for all answers.
        let baseEmoji = "🍎" // You can modify this to change the emoji used.
        
        // Create a set of options, including the correct one.
        var options: Set<String> = ["\(answer) \(baseEmoji)"]
        while options.count < 4 {
            // Generate a random number to create additional options.
            let randomNum = Int.random(in: 1...10)
            // Avoid adding the correct answer as an option again.
            if randomNum != answer {
                options.insert("\(randomNum) \(baseEmoji)")
            }
        }
        
        return Array(options).shuffled()
    }

}

struct StoryGenerationView_Previews: PreviewProvider {
    static var previews: some View {
        StoryGenerationView(selectedScenario: "Park", selectedCharacter: "Wizard")
    }
}
