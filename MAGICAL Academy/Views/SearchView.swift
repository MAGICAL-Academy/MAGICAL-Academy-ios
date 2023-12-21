import SwiftUI
import CoreData

struct SearchDataContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var selectedSetting: String = "Select Setting"
    @State private var selectedHero: String = "Select Hero"
    @State private var selectedVillain: String = "Select Villain"
    @State private var selectedStoryType: String = "Select Story Type"

    @State private var settings: [String] = ["Select Setting"]
    @State private var heroes: [String] = ["Select Hero"]
    @State private var villains: [String] = ["Select Villain"]
    @State private var storyTypes: [String] = ["Select Story Type"]

    @State private var searchResult: Story?

    var body: some View {
        VStack {
            Picker("Select Setting", selection: $selectedSetting) {
                ForEach(settings, id: \.self) { setting in
                    Text(setting).tag(setting)
                }
            }

            Picker("Select Hero", selection: $selectedHero) {
                ForEach(heroes, id: \.self) { hero in
                    Text(hero).tag(hero)
                }
            }

            Picker("Select Villain", selection: $selectedVillain) {
                ForEach(villains, id: \.self) { villain in
                    Text(villain).tag(villain)
                }
            }

            Picker("Select Story Type", selection: $selectedStoryType) {
                ForEach(storyTypes, id: \.self) { storyType in
                    Text(storyType).tag(storyType)
                }
            }

            Button("Search") {
                searchStory()
            }
            .disabled(selectedSetting == "Select Setting" || selectedHero == "Select Hero" || selectedVillain == "Select Villain" || selectedStoryType == "Select Story Type")

            if let story = searchResult {
                Text("Setting: \(story.setting ?? "")")
                Text("Hero: \(story.hero ?? "")")
                Text("Villain: \(story.villain ?? "")")
                Text("Story Type: \(story.story_type ?? "")")
                Text("Content: \(story.content ?? "")")
            }
        }
        .onAppear {
                
            removeDuplicateStories()
                        
            fetchUniqueValues()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Confirmation"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }

    }

    private func fetchUniqueValues() {
        settings += fetchDistinctValues(for: "setting")
        heroes += fetchDistinctValues(for: "hero")
        villains += fetchDistinctValues(for: "villain")
        storyTypes += fetchDistinctValues(for: "story_type")
    }

    private func fetchDistinctValues(for key: String) -> [String] {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Story")
        request.resultType = .dictionaryResultType
        request.returnsDistinctResults = true
        request.propertiesToFetch = [key]

        do {
            let results = try viewContext.fetch(request) as? [[String: Any]]
            return results?.compactMap { $0[key] as? String } ?? []
        } catch {
            print("Fetch error: \(error)")
            return []
        }
    }

    private func searchStory() {
        let request: NSFetchRequest<Story> = Story.fetchRequest()
        request.predicate = NSPredicate(format: "setting == %@ AND hero == %@ AND villain == %@ AND story_type == %@", selectedSetting, selectedHero, selectedVillain, selectedStoryType)

        do {
            let results = try viewContext.fetch(request)
            searchResult = results.first
        } catch {
            print("Fetch error: \(error)")
        }
    }
    struct StoryAttributes: Hashable {
        let setting: String?
        let hero: String?
        let villain: String?
        let storyType: String?
    }
    @State private var showAlert = false
    @State private var alertMessage = ""

    private func removeDuplicateStories() {
        let request: NSFetchRequest<Story> = Story.fetchRequest()

        do {
            let stories = try viewContext.fetch(request)
            let groupedStories = Dictionary(grouping: stories) {
                StoryAttributes(
                    setting: $0.setting,
                    hero: $0.hero,
                    villain: $0.villain,
                    storyType: $0.story_type
                )
            }

            for (_, duplicates) in groupedStories {
                guard duplicates.count > 1 else { continue }

                for story in duplicates.dropFirst() {
                    viewContext.delete(story)
                }
            }

            try viewContext.save()
            showAlert = true
            if stories.count == 0 {
                alertMessage = "No duplicate stories found, and everything is unique."
            } else {
                alertMessage = "Duplicate stories removed, and everything is unique."
            }
        } catch {
            alertMessage = "Error occurred: \(error.localizedDescription)"
            showAlert = true
        }
    }



    
}


// Continue with your DocumentPicker implementation
