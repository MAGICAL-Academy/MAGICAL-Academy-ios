import SwiftUI
import UniformTypeIdentifiers
import CoreData

struct AddDataContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isDataLoading = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var searchText = ""

    var body: some View {
        VStack {
            Button("Load Stories") {
                loadStories()
            }

            if isDataLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }

            TextField("Search", text: $searchText)
                .padding()
                .border(Color.gray)

            List {
                ForEach(searchFilteredStories, id: \.self) { story in
                    VStack(alignment: .leading) {
                        Text("Setting: \(story.setting ?? "")")
                        Text("Hero: \(story.hero ?? "")")
                        Text("Villain: \(story.villain ?? "")")
                        Text("Story Type: \(story.story_type ?? "")")
                        Text("Content: \(story.content ?? "")")
                    }
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private var searchFilteredStories: [Story] {
        // Fetch and filter stories from Core Data based on the search text
        let request: NSFetchRequest<Story> = Story.fetchRequest()
        if !searchText.isEmpty {
            request.predicate = NSPredicate(format: "setting CONTAINS[c] %@ OR hero CONTAINS[c] %@ OR villain CONTAINS[c] %@ OR storyType CONTAINS[c] %@", searchText, searchText, searchText, searchText)
        }
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }

    private func loadStories() {
        isDataLoading = true
        guard let url = Bundle.main.url(forResource: "children_stories_final", withExtension: "json") else {
            alertMessage = "JSON file not found in the bundle."
            showAlert = true
            isDataLoading = false
            return
        }

        do {
            let data = try Data(contentsOf: url)
            if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                for jsonDict in jsonArray {
                    let newStory = Story(context: viewContext)
                    newStory.id = UUID()
                    newStory.setting = jsonDict["setting"] as? String
                    newStory.hero = jsonDict["hero"] as? String
                    newStory.villain = jsonDict["villain"] as? String
                    newStory.story_type = jsonDict["story_type"] as? String
                    newStory.content = jsonDict["content"] as? String
                }
                try viewContext.save()
                alertMessage = "Data successfully added."
            } else {
                alertMessage = "Failed to parse JSON."
            }
        } catch {
            alertMessage = "Error parsing JSON: \(error.localizedDescription)"
        }
        isDataLoading = false
        showAlert = true
    }
}

// Continue with your DocumentPicker implementation if needed
