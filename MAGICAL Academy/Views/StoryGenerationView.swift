import SwiftUI
import Combine
//import AVFoundation // Import AVFoundation for audio playback

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
    @State private var latestAnswer: Int? = nil
//    @State private var audioPlayer: AVAudioPlayer? // Audio player instance
    @State private var isReplayButtonVisible: Bool = false
    @State private var imageURL: URL?
    @State private var isExerciseGenerated = false
   

    // Initialize the ExerciseGenerator with the API key
    private var assistantGenerator: AssistantGenerator

    // Timer to check the status periodically
    let checkStatusTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    init(selectedScenario: String, selectedCharacter: String) {
        self.selectedScenario = selectedScenario
        self.selectedCharacter = selectedCharacter
        self.assistantGenerator = AssistantGenerator(difficulty: 1, age: 4)
    }

    var body: some View {
        VStack {       
            // Display the image above the text
            if let imageURL = imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 200) // Adjust the size as needed
                    case .failure:
                        Text("Image load failed")
                    @unknown default:
                        Text("Unknown state")
                    }
                }
            }           
            Text("Math Story Exercise")
                .font(.largeTitle)
                .foregroundColor(.rainbow)

            Text(storyPrompt)
                .font(.title)
                .bold()
                .padding()
                .multilineTextAlignment(.center)
                .foregroundColor(.blue)

            ForEach(answerOptions, id: \.self) { option in
                Button(action: {
                    checkAnswer(selectedOption: option)
                }) {
                    HStack {
                        Text(option)
                            .font(.headline)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                            .foregroundColor(.white)
                        Spacer()
                        Text(option)
                            .font(.headline)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(10)
                            .foregroundColor(.white)
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
                .font(.system(size: 24))
                .foregroundColor(.rainbow)
                .multilineTextAlignment(.center)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .foregroundColor(.yellow)
                )

            if isReplayButtonVisible {
                Button(action: {
//                    if let audioPlayer = audioPlayer {
//                        audioPlayer.play()
//                    }
                }) {
                    Text("Replay")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .foregroundColor(.white)
                }
            }

            Spacer()
        }
        .onAppear {
            generateExercise()
        }
        .onReceive(checkStatusTimer) { _ in
            if isExerciseGenerated {
                           checkAssistantStatus()
                       }
        }
        .alert(isPresented: .constant(isAnswerCorrect != nil)) {
            if isAnswerCorrect == true {
                return Alert(title: Text("Correct!"), message: Text("Great job!"), dismissButton: .default(Text("Next"), action: generateExercise))
            } else {
                return Alert(title: Text("Oops!"), message: Text("Try again."), dismissButton: .default(Text("OK")))
            }
        }
        .onDisappear {
            cancellables.forEach { $0.cancel() }
        }
    }

    private func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.progress = min(1.0, self.progress + 0.001)
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
        progress = 0.0
    }

    private func checkAssistantStatus() {
        _ = runId
        let currentThreadId = threadId

        // Check if you have already received a result
        guard !isCheckingStatus else {
            // If isCheckingStatus is true, it means you are already checking status, so return
            return
        }

        isCheckingStatus = true
        self.assistantGenerator.getExercise(threadId: currentThreadId!) { [self] result in
            switch result {
            case .success((let exercise, let result)):
                // Update UI with the extracted values
                DispatchQueue.main.async {
                    self.latestMessage = exercise
                    self.latestAnswer = result
                }
                
                // Stop further checks
                self.isCheckingStatus = false
            case .failure(let error):
                print("Error fetching exercise: \(error)")
                print("Error fetching exercise: \(error.localizedDescription)")
                
                // Allow future checks
                self.isCheckingStatus = false
            }
        }
    }



    private func checkAnswer(selectedOption: String) {
        guard let selectedAnswer = Int(selectedOption.filter("0123456789".contains)),
              let correctNumber = correctAnswer else { return }

        assistantGenerator.startTimer()

        isAnswerCorrect = assistantGenerator.evaluatePerformance(userAnswer: selectedAnswer, correctAnswer: correctNumber)

        difficulty = assistantGenerator.difficulty

        assistantGenerator.stopTimer()
    }

    private func generateExercise() {
           assistantGenerator.generateExercise(place: selectedScenario, character: selectedCharacter) { threadId, runId in
               DispatchQueue.main.async {
                   self.threadId = threadId
                   self.runId = runId
                   // Set isExerciseGenerated to true when exercise is generated
                   self.isExerciseGenerated = true
               }
           }
       }
    
//    private func playAudioFromText(_ text: String) {
//        self.assistantGenerator.generateSpeechFromText(text: text)  { result in
//            switch result {
//            case .success(let audioData):
//                // Call the playAudio function with the audio data
//                
//                self.playAudio(data: audioData)
//            case .failure(let error):
//                print("Error generating speech: \(error)")
//            }
//        }
//    }
//    private func playAudio(data: Data) {
//        do {
//            // Initialize the audio player with the ACC audio data
//            audioPlayer = try AVAudioPlayer(data: data)
//
//            // Play the audio
//            audioPlayer?.play()
//        } catch {
//            print("Error playing audio: \(error)")
//        }
//    }
    // Function to generate the image and update the imageURL
      func generateImage() {
          // Call your generateImageFromText function here with the text
          // Update the imageURL in the completion handler
          self.assistantGenerator.generateImageFromText(text: self.latestMessage) { result in
              switch result {
              case .success(let imageUrls):
                  if let imageUrl = imageUrls.first {
                      self.imageURL = URL(string: imageUrl)
                 
                  }
              case .failure(let error):
                  print("Image generation failed: \(error)")
              }
          }
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

