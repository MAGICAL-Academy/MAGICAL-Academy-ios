//
//  GenerateImage.swift
//  AI Tutor
//
//  Created by arash parnia on 11/5/23.
//

import Foundation
import UIKit

func getKey() -> String{
    let apiKey: String = ""
    if let apiKeyData = apiKey.data(using: .utf8) {
        let status = KeychainManager.save(key: "OPENAI_API_KEY", data: apiKeyData)
        print("Save status: \(status)")
    }

    
    if let receivedData = KeychainManager.load(key: "OPENAI_API_KEY") {
        let retrievedAPIKey = String(data: receivedData, encoding: .utf8)
//        print("Retrieved API Key: \(retrievedAPIKey ?? "None")")
        return  (retrievedAPIKey ?? "")
    }
    return ""
}
func generateImage(with prompt: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
    let YOUR_API_KEY  = getKey()
    let endpoint = "https://api.openai.com/v1/images/generations"
    var request = URLRequest(url: URL(string: endpoint)!)
    request.httpMethod = "POST"
    request.addValue("Bearer \(YOUR_API_KEY)", forHTTPHeaderField: "Authorization")
    
    let body: [String: Any] = [
        "prompt": prompt,
        "n": 1,  // Number of images to generate
        // Include any other parameters as per the API documentation
    ]
    
    let jsonData = try? JSONSerialization.data(withJSONObject: body)
    request.httpBody = jsonData
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let data = data else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
            return
        }
        
        do {
            // Parse JSON data and extract the image URL or direct image data
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            // Depending on the API's response structure, extract the image URL or data
            // For this example, let's assume we get a URL
            if let imageUrlString = json?["image_url"] as? String,
               let imageUrl = URL(string: imageUrlString) {
                // Download the image
                let imageData = try Data(contentsOf: imageUrl)
                if let image = UIImage(data: imageData) {
                    completion(.success(image))
                } else {
                    completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not create image"])))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

