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

    var body: some View {
        VStack {
            // Your Scenario Selection UI
            ForEach(scenarios, id: \.self) { scenario in
                Button(action: {
                    self.selectedScenario = scenario
                    self.completion()
                }) {
                    // Your Scenario Button UI
                    Text(scenario)
                }
            }
        }
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
