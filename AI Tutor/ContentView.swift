//
//  ContentView.swift
//  AI Tutor
//
//  Created by arash parnia on 11/2/23.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

   

        @State private var selectedScenario: String?
        let scenarios = ["Farm", "Zoo", "Beach", "Playground", "Forest", "Castle", "SpaceStation"]  // Assume these are the names of your image assets as well

        var body: some View {
            NavigationView {
                VStack {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(), GridItem(), GridItem()]) {
                            ForEach(scenarios, id: \.self) { scenario in
                                Button(action: {
                                    self.selectedScenario = scenario
                                }) {
                                    VStack {
                                        Image(scenario)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 100, height: 100)
                                        Text(scenario)
                                    }
                                    .padding()
                                }
                            }
                        }
                    }
                    
                }
                Text("Select an item")
            }
        }

  
    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
