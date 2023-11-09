//
//  ScenarioSelectionView.swift
//  MAGICAL Academy
//
//  Created by arash parnia on 11/6/23.
//

import SwiftUI

struct Scenario: GridItemViewModel {
    var displayName: String
    var imageName: String
}

struct ScenarioSelectionView: View {
    @Binding var selectedScenario: String?
    var completion: () -> Void
    
    let scenarios = [
        Scenario(displayName: "Farm", imageName: "Farm"),
        Scenario(displayName: "Zoo", imageName: "Zoo"),
        Scenario(displayName: "Beach", imageName: "Beach"),
        Scenario(displayName: "Playground", imageName: "Playground"),
        Scenario(displayName: "Forest", imageName: "Forest"),
        Scenario(displayName: "Castle", imageName: "Castle"),
        Scenario(displayName: "SpaceStation", imageName: "SpaceStation"),
       
    ]

    var body: some View {
        ScrollableGridView(items: scenarios) { scenario in
            ScenarioView(scenario: scenario, selectedScenario: $selectedScenario, completion: completion)
        }
    }
}

struct ScenarioView: View {
    let scenario: Scenario
    @Binding var selectedScenario: String?
    var completion: () -> Void

    var body: some View {
        Button(action: {
            self.selectedScenario = scenario.displayName
            self.completion()
        }) {
            ZStack(alignment: .bottom) {
                Image(scenario.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
                TextOverlayView(text: scenario.displayName)
            }
        }
        .buttonStyle(PlainButtonStyle()) // To remove button default styling if needed
    }
}


// Preview for SwiftUI Canvas
struct ScenarioSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide a constant value for the binding and a dummy completion closure
        ScenarioSelectionView(selectedScenario: .constant(nil), completion: {})
    }
}
