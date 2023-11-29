//
//  StoryCardView.swift
//  MAGICAL Academy
//
//  Created by arash parnia on 11/16/23.
//

import SwiftUI

struct StoryCardView: View {
    let story: String

    var body: some View {
        Text(story)
            .padding()
            .background(Color.gray)
            .shadow(color: .gray, radius: 5, x: 5, y: 5)  // Add shadow for 3D effect
            .cornerRadius(10)
            .foregroundColor(.white)
    }
}

