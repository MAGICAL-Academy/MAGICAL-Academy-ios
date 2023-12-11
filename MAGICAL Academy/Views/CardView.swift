import SwiftUI

// DataItem struct remains the same
struct DataItem: Identifiable {
    let id = UUID()
    var item: String
    var items: [String] // Each card's specific items
    var content: AnyView
}

// CardContentView remains the same
struct CardContentView<Content: View>: View {
    let content: Content

    var body: some View {
        content
    }
}

// Updated CardView to collapse and show the selected item
struct CardView: View {
    @Binding var isPreviousCardSelected: Bool
    @Binding var isSelected: Bool
    @State private var selectedItem: String?
    let items: [String]

    var body: some View {
        VStack {
            if !isSelected {
                List(items, id: \.self) { item in
                    Text(item)
                        .onTapGesture {
                            if isPreviousCardSelected {
                                selectedItem = item
                                isSelected = true
                            }
                        }
                }
            } else if let selectedItem = selectedItem {
                // Show only the selected item
                Text(selectedItem).bold()
            }
        }
        .frame(width: 300, height: isSelected ? 50 : 200)
        .padding()
        .background(Color.white)
        .cornerRadius(10)
    }
}

// ContentView_ updates to manage selection status
struct ContentView_: View {
    let data: [DataItem] = [
        DataItem(item: "Item 1", items: ["Subitem 1.1", "Subitem 1.2"], content: AnyView(Image("image1"))),
        DataItem(item: "Item 2", items: ["Subitem 2.1", "Subitem 2.2"], content: AnyView(Text("This is a text content")))
    ]

    @State private var selectionStates: [UUID: Bool]

    init() {
        var initialStates: [UUID: Bool] = [:]
        for item in data {
            initialStates[item.id] = false
        }
        _selectionStates = State(initialValue: initialStates)
    }

    private func bindingForSelectionState(of item: DataItem) -> Binding<Bool> {
        return Binding<Bool>(
            get: { self.selectionStates[item.id, default: false] },
            set: { self.selectionStates[item.id] = $0 }
        )
    }

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 10) {
                ForEach(data) { item in
                    let index = data.firstIndex(where: { $0.id == item.id })!
                    let isPreviousCardSelected = index == 0 || selectionStates[data[max(0, index - 1)].id, default: false]
                    
                    CardView(isPreviousCardSelected: .constant(isPreviousCardSelected), isSelected: bindingForSelectionState(of: item), items: item.items)
                }
            }
        }
    }
}

// Previews
struct ContentView__Previews: PreviewProvider {
    static var previews: some View {
        ContentView_()
    }
}
