import SwiftUI
import CoreData

// Assuming DataItem remains the same but will fetch from Core Data
struct DataItem: Identifiable {
    let id: UUID
    var item: String
    var items: [String]
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

// ContentView_ modifications
struct ContentView_: View {
    @Environment(\.managedObjectContext) var viewContext
    @FetchRequest(
        entity: CardEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CardEntity.name, ascending: true)]
    ) var cards: FetchedResults<CardEntity>

    @State private var selectionStates: [UUID: Bool] = [:]

    private func convertToDataItem(cardEntity: CardEntity) -> DataItem {
        let contentEntities = cardEntity.hasCardContent?.hasContent?.allObjects as? [ContentEntity] ?? []
        let items = contentEntities.compactMap { $0.text } // Assuming text represents the items
        let contentView = AnyView(VStack {
            ForEach(contentEntities, id: \.id) { contentEntity in
                switch contentEntity.type {
                case "text":
                    Text(contentEntity.text ?? "")
                case "image":
                    // Replace with actual image view
                    Text("Image Placeholder")
                case "audio":
                    // Replace with actual audio view
                    Text("Audio Placeholder")
                default:
                    EmptyView()
                }
            }
        })

        return DataItem(
            id: cardEntity.id ?? UUID(),
            item: cardEntity.name ?? "Unknown",
            items: items,
            content: contentView
        )
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
                ForEach(cards, id: \.id) { cardEntity in
                    let dataItem = convertToDataItem(cardEntity: cardEntity)
                    let index = cards.firstIndex(where: { $0.id == cardEntity.id })!
                    let isPreviousCardSelected = index == 0 || selectionStates[cards[max(0, index - 1)].id ?? UUID(), default: false]

                    CardView(isPreviousCardSelected: .constant(isPreviousCardSelected), isSelected: bindingForSelectionState(of: dataItem), items: dataItem.items)
                }
            }
        }
    }
}

struct ContentView__Previews: PreviewProvider {
    static var previews: some View {
        ContentView_()
    }
}
