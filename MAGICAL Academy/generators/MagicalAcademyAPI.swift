import Foundation

struct ExerciseContentResponse: Codable {
    let content: Content

    struct Content: Codable {
        let exercise: String
        let answer: String
    }

    enum CodingKeys: String, CodingKey {
        case content
    }
}


class MagicalAcademyAPI {
    /// Enumeration to represent API-related errors.
    enum APIError: Error {
        case invalidURL
        case responseError
        case parsingError
        case unknownError
    }

    /// Access token for the API.
    let apiAccessToken: String

    /**
     Initializes the MagicalAcademyAPI with API access token.

     */
    init() {
        self.apiAccessToken = MagicalAcademyAPI.fetchAPIKey()
    }

    /**
     Fetches the API access key from Secrets.plist.

     - Returns: The API access key.
     - Throws: A fatalError if the key is not found in Secrets.plist.
     */
    static func fetchAPIKey() -> String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let secrets = NSDictionary(contentsOfFile: path),
              let apiKey = secrets["MAGICAL_ACADEMY_API_KEY"] as? String else {
            fatalError("API Key not found. Ensure you have Secrets.plist with the MAGICAL_ACADEMY_API_KEY key.")
        }
        return apiKey
    }

    /**
     Calls the specific exercise generation API.

     - Parameters:
        - age: The age for exercise content generation.
        - difficulty: The difficulty level for exercise content generation.
        - scenario: The scenario for exercise content generation.
        - character: The character for exercise content generation.
        - completionHandler: A completion handler with the generated exercise content.
     */
    func generateExerciseContent(
        age: String,
        difficulty: String,
        scenario: String,
        character: String,
        completionHandler: @escaping (Result<ExerciseContentResponse, Error>) -> Void
    ) {
        let apiUrlString = "https://api.magical-academy.com/content/generate-content?service_type=GoogleGenerativeAI&content_type=exercise"
        let headers = [
            "accept": "application/json",
            "access_token": apiAccessToken,
            "Content-Type": "application/json"
        ]
        let requestBody: [String: Any] = [
            "age": age,
            "difficulty": difficulty,
            "scenario": scenario,
            "character": character
        ]

        let url = URL(string: apiUrlString)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completionHandler(.failure(error))
            return
        }

        sendRequest(request: request) { result in
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    let content = try decoder.decode(ExerciseContentResponse.self, from: data)
                    completionHandler(.success(content))
                } catch let error {
                    print("Error decoding exercise content: \(error)")
                    completionHandler(.failure(error))
                }

            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }

    /**
     Sends a URLRequest to the API and handles the response.

     - Parameters:
        - request: The URLRequest to send.
        - completionHandler: A completion handler with the API response.
     */
    private func sendRequest(request: URLRequest, completionHandler: @escaping (Result<Data, Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                completionHandler(.failure(error ?? APIError.unknownError))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
                completionHandler(.failure(APIError.responseError))
                return
            }

            guard let data = data else {
                completionHandler(.failure(APIError.parsingError))
                return
            }

            completionHandler(.success(data))
        }
        task.resume()
    }

    // Additional utility functions or extensions can be added here.
}
