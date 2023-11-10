//
//  StoryGenerationView.swift
//  MAGICAL Academy
//
//  Created by arash parnia on 11/10/23.
//


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
    @State private var progress: Double = 0.0 // Progress value for the animation
    @State private var progressTimer: Timer? // Store the timer in @State
    @State private var latestMessage: String = "" // Define a property to store the latest message

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
                   .foregroundColor(.rainbow) // Create a custom Color extension for rainbow colors

               Text(storyPrompt)
                   .font(.title)
                   .bold()
                   .padding()
                   .multilineTextAlignment(.center)
                   .foregroundColor(.blue) // Set the color as per your preference

               // Displaying multiple choice options
               ForEach(answerOptions, id: \.self) { option in
                   Button(action: {
                       checkAnswer(selectedOption: option)
                   }) {
                       HStack {
                           Text(option)
                               .font(.headline)
                               .padding()
                               .background(Color.green) // Set the background color
                               .cornerRadius(10) // Add some corner radius
                               .foregroundColor(.white) // Text color
                           Spacer()
                           // Use the option directly since it already contains an emoji
                           Text(option)
                               .font(.headline)
                               .padding()
                               .background(Color.purple) // Set the background color
                               .cornerRadius(10) // Add some corner radius
                               .foregroundColor(.white) // Text color
                       }
                   }
                   .buttonStyle(.bordered)
                   .padding(.horizontal)
               }

               if isCheckingStatus {
                   ProgressView("Checking status...", value: progress, total: 1.0)
                       .progressViewStyle(LinearProgressViewStyle())
                       .onAppear {
                           startProgressTimer()
                       }
                       .onDisappear {
                           stopProgressTimer()
                       }
               }

               Text(latestMessage)
                   .font(.system(size: 24)) // Large font size
                   .foregroundColor(.rainbow) // Rainbow colors
                   .multilineTextAlignment(.center)
                   .padding()
                   .background(
                       RoundedRectangle(cornerRadius: 20)
                           .foregroundColor(.yellow) // Set background color
                   )

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
    
 

    private func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if self.progress < 1.0 {
                self.progress += 0.005 // Adjust the step size as needed for the desired animation speed
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
        progress = 0.0
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
                    // Update progress to 1.0 when the task is completed
                    self.progress = 1.0

                    // Fetch messages for the thread
                    self.assistantGenerator.getLatestAssistantMessage(threadId: currentThreadId) { result in
                        switch result {
                        case .success(let messages):
                            // Update your UI with the latest message
                            self.latestMessage = String(messages)
                        case .failure(let error):
                            // Handle the error if fetching messages fails
                            print("Error fetching messages: \(error)")
                        }
                    }

                    // Update your UI with the new data
                    // ...

                    isCheckingStatus = false
                    self.cancellables.forEach { $0.cancel() }
                    self.checkStatusTimer.upstream.connect().cancel() // Stop the timer
                } else if status == "failed" {
                    // Handle a failed status
                    // ...
                }
            }
        }
    }

    // Function to check the user's answer
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

    // Function to fetch a new story prompt
    private func fetchNewStoryPrompt() {
        // Use the ExerciseGenerator to generate the exercise
        assistantGenerator.generateExercise(place: selectedScenario, character: selectedCharacter) { threadId, runId in
            DispatchQueue.main.async {
                // Store the threadId and runId
                self.threadId = threadId
                self.runId = runId
            }
        }
    }

    // Function to generate multiple choice answers with emojis
    // ...

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

extension Color {
    static var rainbow: Color {
        return Color(.sRGB, red: Double.random(in: 0...1), green: Double.random(in: 0...1), blue: Double.random(in: 0...1))
    }
}
