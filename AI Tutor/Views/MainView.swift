import SwiftUI

struct MainView: View {
    @State private var selectedStage = 0
    @State private var selectedScenario: String?
    @State private var selectedCharacter: String?
    @State private var selectedAttire: String?
    @State private var showGeneratedImageView = false

    var body: some View {
        VStack {
            switch selectedStage {
            case 0:
                ScenarioSelectionView(selectedScenario: $selectedScenario) {
                    self.selectedStage += 1
                }
            case 1:
                CharacterSelectionView(selectedCharacter: $selectedCharacter) {
                    self.selectedStage += 1
                }
            case 2:
                AttireSelectionView(selectedAttire: $selectedAttire) {
                    self.selectedStage = 3
                    self.showGeneratedImageView = true
                }
            default:
                EmptyView()
            }
        }
        .sheet(isPresented: $showGeneratedImageView) {
            if let scenario = selectedScenario, let character = selectedCharacter, let attire = selectedAttire {
                GenerateImageView(selectedPlace: scenario, selectedCharacter: character, selectedAttire: attire)
            }
        }
    }
}



struct ScenarioSelectionView: View {
    @Binding var selectedScenario: String?
    var completion: () -> Void

    let scenarios = ["Farm", "Zoo", "Beach", "Playground", "Forest", "Castle", "SpaceStation"]

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                // Vertical scrolling for portrait orientation
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible())], spacing: 20) {
                        scenarioButtons
                    }
                }
            } else {
                // Horizontal scrolling for landscape orientation
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 20) {
                        scenarioButtons
                    }
                }
            }
        }
    }

    var scenarioButtons: some View {
        ForEach(scenarios, id: \.self) { scenario in
            scenarioButton(scenario)
        }
    }

    @ViewBuilder
    func scenarioButton(_ scenario: String) -> some View {
        Button(action: {
            self.selectedScenario = scenario
            self.completion()
        }) {
            GeometryReader { geometry in
                ZStack(alignment: Alignment(horizontal: .center, vertical: .bottom)) {
                    Image(scenario)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()

                    Text(scenario)
                        .foregroundColor(.white)
                        .padding(5)
                        .frame(width: geometry.size.width * 0.3)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(5)
                        .padding(.bottom, 10)
                }
            }
            .frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 200 : UIScreen.main.bounds.width)
        }
        .cornerRadius(8)
        .shadow(radius: 3)
    }
}




struct CharacterSelectionView: View {
    @Binding var selectedCharacter: String?
    var completion: () -> Void

    let characters = ["Astronaut", "Scientist", "Superhero"]

    var body: some View {
        VStack {
            // Your Character Selection UI
            ForEach(characters, id: \.self) { character in
                Button(action: {
                    self.selectedCharacter = character
                    self.completion()
                }) {
                    // Your Character Button UI
                    Text(character)
                }
            }
        }
    }
}

struct AttireSelectionView: View {
    @Binding var selectedAttire: String?
    var completion: () -> Void

    let attires = ["Spacesuit", "Lab Coat", "Cape"]
    var body: some View {
        VStack {
            // Your Attire Selection UI
            ForEach(attires, id: \.self) { attire in
                Button(action: {
                    self.selectedAttire = attire
                    self.completion()
                }) {
                    // Your Attire Button UI
                    Text(attire)
                }
            }
        }
    }
}

import SwiftUI

struct GeneratedScenarioView: View {
    var selectedScenario: String?
    var selectedCharacter: String?
    var selectedAttire: String?

    var body: some View {
        VStack {
            // Display the selections
            Text("Selected Scenario: \(selectedScenario ?? "None")")
            Text("Selected Character: \(selectedCharacter ?? "None")")
            Text("Selected Attire: \(selectedAttire ?? "None")")

            // Button to navigate to GenerateImageView
            NavigationLink(destination: GenerateImageView(selectedPlace: selectedScenario ?? "",
                                                         selectedCharacter: selectedCharacter ?? "",
                                                         selectedAttire: selectedAttire ?? "")) {
                Text("Generate Image")
            }
        }
    }
}

// Make sure this struct is in the same module as GenerateImageView
struct MainViewPreviews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
