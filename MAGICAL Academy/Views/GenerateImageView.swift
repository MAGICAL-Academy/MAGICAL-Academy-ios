import SwiftUI
import OpenAIKit
import Foundation

struct GenerateImageView: View {
    @State private var generatedImage: UIImage?
    @State private var isLoading = false  // Add a loading state
    
    private var openAI: OpenAIKit!

    var selectedPlace: String
    var selectedCharacter: String
    var selectedAttire: String
    var apiKey: String = ""
    init(selectedPlace: String, selectedCharacter: String, selectedAttire: String) {
        self.selectedPlace = selectedPlace
        self.selectedCharacter = selectedCharacter
        self.selectedAttire = selectedAttire
        
        // Initialize the OpenAIKit with API Key
        
        if let receivedData = KeychainManager.load(key: "OPENAI_API_KEY") {
            let retrievedAPIKey = String(data: receivedData, encoding: .utf8)
            apiKey =  (retrievedAPIKey ?? "")
        }
        self.openAI = OpenAIKit(apiToken: apiKey)
    }

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Generating Image...")
            } else if let generatedImage = generatedImage {
                Image(uiImage: generatedImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Text("your key is " + apiKey)
            }
        }
        .onAppear(perform: generateImage)
        .navigationBarTitle("Generated Image", displayMode: .inline)
    }

    private func generateImage() {
        isLoading = true  // Start loading
        let prompt = "Create an image of a \(selectedCharacter) wearing \(selectedAttire) at a \(selectedPlace)."
        
        openAI.sendImagesRequest(prompt: prompt, size: .size512, n: 1) { result in
            switch result {
            case .success(let aiResult):
                if let urlString = aiResult.data.first?.url, let url = URL(string: urlString) {
                    downloadImage(from: url)
                }
            case .failure(let error):
                isLoading = false  // Stop loading on error
                print("Error generating image: \(error.localizedDescription)")
            }
        }
    }

    private func downloadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false  // Stop loading once data is fetched
                if let data = data, let image = UIImage(data: data) {
                    self.generatedImage = image
                }
            }
        }.resume()
    }
}


// Inline preview of the GenerateImageView
struct GenerateImageView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            GenerateImageView(selectedPlace: "Farm", selectedCharacter: "Dolphin", selectedAttire: "Mini skirt")
                .previewDisplayName("Loading State")
        }
        
        NavigationView {
            GenerateImageView(generatedImage: UIImage(systemName: "photo"), selectedPlace: "Beach", selectedCharacter: "Shark", selectedAttire: "Sunglasses")
                .previewDisplayName("Loaded State")
        }
    }
}

// Extension to allow for initializing with a predefined image for previews
extension GenerateImageView {
    init(generatedImage: UIImage?, selectedPlace: String, selectedCharacter: String, selectedAttire: String) {
        self._generatedImage = State(initialValue: generatedImage)
        self.selectedPlace = selectedPlace
        self.selectedCharacter = selectedCharacter
        self.selectedAttire = selectedAttire
    }
}
