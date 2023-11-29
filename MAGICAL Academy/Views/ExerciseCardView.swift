import SwiftUI
struct ExerciseCardView: View {
    let question: ExerciseViewModel.Question
    var optionSelected: (Int) -> Void
    @State private var selectedOption: String?
    var colorIndex: Int

    private let cardColors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    
    var body: some View {
        VStack {
            Text(question.exercise)
                .padding()
                .background(cardColors[colorIndex % cardColors.count])
                .cornerRadius(10)
                .foregroundColor(.white)
                .shadow(color: .gray, radius: 5, x: 5, y: 5)
                .rotation3DEffect(
                    .degrees(1),
                    axis: (x: 1.0, y: 0.0, z: 0.0)
                )

            if let selectedOption = selectedOption {
                Text(selectedOption)
                    .padding()
                    .background(cardColors[colorIndex % cardColors.count])
                    .cornerRadius(10)
                    .foregroundColor(.white)
                    .shadow(color: .gray, radius: 5, x: 5, y: 5)
            } else {
                ForEach(question.options, id: \.self) { option in
                    Button(action: {
                        self.selectedOption = option
                        optionSelected(Int(option)!)
                    }) {
                        Text(option)
                            .padding()
                            .background(Color.gray)
                            .cornerRadius(10)
                            .foregroundColor(.white)
                            .shadow(color: .gray, radius: 5, x: 5, y: 5)
                    }
                    .padding(.horizontal)
                    .id(UUID()) // Use UUID as the identifier
                }
            }
        }.onAppear {
            // ...
        }
    }
}
