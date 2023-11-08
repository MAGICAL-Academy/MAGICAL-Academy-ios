//
//  ScenarioSelectionView.swift
//  AI Tutor
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
    
    let scenarios = ["Farm", "Zoo", "Beach", "Playground", "Forest", "Castle", "SpaceStation"]
    let scenarios = [
        Scenario(displayName: "Farm", imageName: "Farm"),
        // ... other scenarios
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
            ZStack {
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

struct TextOverlayView: View {
    var text: String

    var body: some View {
        Text(text)
            .foregroundColor(.white)
            .padding(5)
            .background(Color.black.opacity(0.5))
            .cornerRadius(5)
            .padding(.bottom, 10)
    }
}

