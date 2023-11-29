import SwiftUI

struct ExcerciseView: View {
    @StateObject private var viewModel: ExerciseViewModel

    init(selectedScenario: String, selectedCharacter: String) {
        _viewModel = StateObject(wrappedValue: ExerciseViewModel(selectedScenario: selectedScenario, selectedCharacter: selectedCharacter))
    }

    var body: some View {
        VStack {
            ScrollView {
                if let currentExercise = viewModel.currentExercise {
                    StoryCardView(story: currentExercise.content.exercise)
                }
                ForEach(Array(viewModel.questions.enumerated()), id: \.element) { index, question in
                    ExerciseCardView(
                        question: question,
                        optionSelected: { selectedOption in
                            viewModel.saveAnswer(for: index, answer: selectedOption)
                            viewModel.generateNextQuestion()
                        },
                        colorIndex: index
                    )
                    .frame(minWidth: 300, maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
        }
        .onAppear {
            viewModel.fetchExercise()
        }
    }
}

struct ExcerciseView_Previews: PreviewProvider {
    static var previews: some View {
        ExcerciseView(selectedScenario: "Farm", selectedCharacter: "Cow")
    }
}
