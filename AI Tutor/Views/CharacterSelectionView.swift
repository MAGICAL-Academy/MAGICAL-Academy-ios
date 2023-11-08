
//  CharacterSelectionView.swift
//  AI Tutor
//
//  Created by arash parnia on 11/6/23.
//

import SwiftUI

// This conforms to the GridItemViewModel protocol for the ScrollableGridView.
struct Character: GridItemViewModel {
    var displayName: String
    var imageName: String
}

struct CharacterSelectionView: View {
    @Binding var selectedCharacter: String?
    var completion: () -> Void
    
    let characters = [
        Character(displayName: "Conservationist", imageName: "Conservationist"),
        Character(displayName: "Botanist", imageName: "Botanist"),
        Character(displayName: "Fairy", imageName: "Fairy"),
        Character(displayName: "Farmer", imageName: "Farmer"),
        Character(displayName: "Knight", imageName: "Knight"),
        Character(displayName: "Photographer", imageName: "Photographer"),
        Character(displayName: "Pirate", imageName: "Pirate"),
        Character(displayName: "Scientist", imageName: "Scientist"),
        Character(displayName: "Surfer", imageName: "Surfer"),
        Character(displayName: "Veterinarian", imageName: "Veterinarian"),
        Character(displayName: "Zookeeper", imageName: "Zookeeper"),
        // ... add all the other characters here
    ]

    var body: some View {
        ScrollableGridView(items: characters) { character in
            CharacterView(character: character, selectedCharacter: $selectedCharacter, completion: completion)
        }
    }
}

struct CharacterView: View {
    let character: Character
    @Binding var selectedCharacter: String?
    var completion: () -> Void

    var body: some View {
        Button(action: {
            self.selectedCharacter = character.displayName
            self.completion()
        }) {
            ZStack(alignment: .bottom) {
                Image(character.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
                TextOverlayView(text: character.displayName)
            }
        }
        .buttonStyle(PlainButtonStyle()) // To remove button default styling if needed
    }
}


struct CharacterSelectionView_Previews: PreviewProvider {
    @State static var selectedCharacter: String? = nil // Create a state variable for the preview

    static var previews: some View {
        CharacterSelectionView(selectedCharacter: $selectedCharacter) { // Use the state variable as a binding
            // Completion closure can be empty if just for preview purposes
        }
    }
}
