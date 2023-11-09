//
//  ScrollableGridView.swift
//  AI Tutor
//
//  Created by arash parnia on 11/6/23.
//

import SwiftUI

protocol GridItemViewModel {
    var displayName: String { get }
    var imageName: String { get }
}

struct ScrollableGridView<Item: GridItemViewModel, Content: View>: View {
    var items: [Item]
    var content: (Item) -> Content
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible())], spacing: 20) {
                        ForEach(items, id: \.displayName) { item in
                            self.content(item)
                        }
                    }
                }
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 20) {
                        ForEach(items, id: \.displayName) { item in
                            self.content(item)
                        }
                    }
                }
            }
        }
    }
}

