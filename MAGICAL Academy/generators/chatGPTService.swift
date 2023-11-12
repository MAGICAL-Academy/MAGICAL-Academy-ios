//
//  AssistantThreadManager.swift
//  MAGICAL Academy
//
//  Created by arash parnia on 11/10/23.
//
import Foundation

class ChatGPTService {
    private let apiKey: String
    private let assistantId: String = "asst_T7HClKQYmKUNOJmxlKW79XWQ"
    private let session: URLSession
    private let logger = Logger()
    
    init(session: URLSession = .shared) {
        self.apiKey = ChatGPTService.fetchAPIKey()
        self.session = session
    }
    static func fetchAPIKey() -> String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let secrets = NSDictionary(contentsOfFile: path),
              let apiKey = secrets["CHAT_GPT_API_KEY"] as? String else {
            fatalError("API Key not found. Ensure you have Secrets.plist with the CHAT_GPT_API_KEY key.")
        }
        return apiKey
    }
    private func logHeaders(_ headers: [AnyHashable: Any]) {
        logger.log("HTTP Response Headers:")
        headers.forEach { header in
            let keyString = String(describing: header.key)
            let valueString = String(describing: header.value)
            logger.log("\(keyString): \(valueString)")
        }
    }
     func initializeThreadWithMessages(messages: [[String: String]], completion: @escaping (Result<String, Error>) -> Void) {
        // Call createThreadAndRun and handle the Result
        let createThreadResult = createThreadAndRun(with: messages)

        switch createThreadResult {
        case .success(let (threadId, runId)):
            // Store the thread ID in UserDefaults
            UserDefaults.standard.set(threadId, forKey: "ThreadId")
            self.logger.log("ThreadId stored in UserDefaults: \(threadId)", level: .debug)
            self.logger.log("runId is: \(runId)", level: .debug)
            
            // Check the thread's run status in the background
            self.checkRunStatus(runId: runId, threadId: threadId) { result in
                switch result {
                case .success:
                    UserDefaults.standard.set(true, forKey: "RunFinished")
                    self.logger.log("Run status checked and marked as finished.", level: .debug)
                    completion(.success(threadId))
                case .failure(let error):
                    self.logger.log("Error checking run status: \(error)", level: .error)
                    completion(.failure(error))
                }
            }
            
        case .failure(let error):
            // Handle error if createThreadAndRun fails
            self.logger.log("Error creating thread: \(error)", level: .error)
            completion(.failure(error))
        }
    }

    private func createThreadAndRun(with messages: [[String: String]]) -> Result<(String, String), Error> {
        let url = URL(string: "https://api.openai.com/v1/threads/runs")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")

        let body: [String: Any] = [
            "assistant_id": assistantId,
            "thread": [
                "messages": messages
            ]
        ]

        do {
            let requestBody = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = requestBody
            logger.log("Request to create thread with messages: \(body)", level: .debug)
        } catch {
            return .failure(error)
        }

        let semaphore = DispatchSemaphore(value: 0)
        var threadId = ""
        var runId = ""

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                semaphore.signal()
                return
            }
            self.logger.log("data for createThread \(String(describing: data))", level: .debug)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                semaphore.signal()
                return
            }
            guard let data = data else {
                semaphore.signal()
                return
            }
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                if let jsonObject = jsonObject as? [String: Any], let id = jsonObject["id"] as? String {
                    threadId = jsonObject["thread_id"] as? String ?? ""
                    runId = id
                    self.logger.log("Thread created with threadId: \(threadId), runId: \(runId)", level: .debug)
                }
            } catch {
                semaphore.signal()
                return
            }
            semaphore.signal()
        }

        task.resume()
        semaphore.wait()

        if !threadId.isEmpty && !runId.isEmpty {
            return .success((threadId, runId))
        } else {
            return .failure(NSError(domain: "YourAppErrorDomain", code: 0, userInfo: nil))
        }
    }

    func checkRunStatus(runId: String, threadId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let statusCheckInterval: TimeInterval = 5.0

        self.logger.log("checkRunStatus for Thread \(threadId).", level: .debug)

        func checkStatus() {
            fetchRunStatus(runId: runId, threadId: threadId) { result, error in
                self.logger.log("checkRunStatus result for Thread \(threadId): \(result)", level: .debug)
                if let error = error {
                    self.logger.log("checkRunStatus failed with error: \(error.localizedDescription)", level: .error)
                    completion(.failure(error))
                    return
                }

                switch result {
                case "completed":
                    self.logger.log("checkRunStatus: Thread \(threadId) has succeeded.", level: .debug)
                    completion(.success(()))
                case "failed":
                    self.logger.log("checkRunStatus: Thread \(threadId) has failed.", level: .debug)
                    completion(.failure(NSError(domain: "YourAppErrorDomain", code: 0, userInfo: nil)))
                default:
                    self.logger.log("checkRunStatus: Thread \(threadId) is still running.", level: .debug)
                    DispatchQueue.global().asyncAfter(deadline: .now() + statusCheckInterval) {
                        checkStatus() // Recursive call to checkStatus after the interval
                    }
                }
            }
        }

        checkStatus() // Initial call to start checking the status
    }


    func fetchRunStatus(runId: String, threadId: String, completion: @escaping (String, Error?) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/threads/\(threadId)/runs/\(runId)")!
      
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")
       
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                self.logger.log("Error fetching run status: \(error.localizedDescription)", level: .error)
                completion("", error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                self.logger.log("No HTTPURLResponse received.", level: .error)
                completion("", URLError(.badServerResponse))
                return
            }
         
            self.logger.log("HTTP Status Code: \(httpResponse.statusCode)", level: .debug)

            if httpResponse.statusCode != 200 {
                self.logger.log("Bad server response: HTTP Status Code \(httpResponse.statusCode)", level: .error)
                completion("", URLError(.badServerResponse))
                return
            }
          
            guard let data = data else {
                self.logger.log("Data object is nil when fetching run status.", level: .error)
                completion("", URLError(.cannotParseResponse))
                return
            }
          
            // Print the raw server response
            if let rawResponseString = String(data: data, encoding: .utf8) {
                self.logger.log("Raw server response: \(rawResponseString)", level: .debug)
            }
           
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    self.logger.log("Received JSON response: \(jsonResponse)", level: .debug)
                    if let status = jsonResponse["status"] as? String {
                        self.logger.log("Run status: \(status)", level: .debug)
                        completion(status, nil)
                    } else {
                        self.logger.log("Status field not found in JSON response.", level: .error)
                        completion("", URLError(.cannotParseResponse))
                    }
                } else {
                    self.logger.log("Failed to cast JSON response to [String: Any].", level: .error)
                    completion("", URLError(.cannotParseResponse))
                }
            } catch {
                self.logger.log("JSON parsing error: \(error.localizedDescription)", level: .error)
                completion("", error)
            }
        }
        
      
        task.resume()
       
    }

    
    func getStatus(for threadId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/threads/\(threadId)/runs/latest")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")
        
        self.logger.log("Status check started for threadId \(threadId).", level: .debug)
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                self.logger.log("Status check failed with error: \(error)", level: .error)
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let badResponseError = URLError(.badServerResponse)
                self.logger.log("Status check failed with bad server response: ", level: .error)
                completion(.failure(badResponseError))
                return
            }
            
            guard let data = data else {
                let parseResponseError = URLError(.cannotParseResponse)
                self.logger.log("Status check failed with inability to parse response.", level: .error)
                completion(.failure(parseResponseError))
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                self.logger.log("Status check response data for threadId \(threadId): \(responseString)", level: .debug)
            } else {
                self.logger.log("Status check response data for threadId \(threadId) couldn't be converted to a string.", level: .error)
            }
            
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                if let jsonObject = jsonObject as? [String: Any], let status = jsonObject["status"] as? String {
                    self.logger.log("Status check for threadId \(threadId): Status = \(status)", level: .debug)
                    completion(.success(status))
                } else {
                    let parseResponseError = URLError(.cannotParseResponse)
                    self.logger.log("Status check failed with inability to parse JSON response.", level: .error)
                    completion(.failure(parseResponseError))
                }
            } catch {
                self.logger.log("Status check failed with JSON serialization error: \(error)", level: .error)
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    
    func addMessagesToThread(threadId: String, messages: [[String: String]], completion: @escaping (Result<Void, Error>) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/threads/\(threadId)/messages")!
        
        let dispatchGroup = DispatchGroup()
        var firstError: Error?
        
        for message in messages {
            dispatchGroup.enter()
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")
            do {
                let requestBody = try JSONSerialization.data(withJSONObject: message, options: [])
                request.httpBody = requestBody
            } catch {
                firstError = error
                dispatchGroup.leave()
                continue
            }
            
            let task = session.dataTask(with: request) { _, response, error in
                if let error = error {
                    if firstError == nil {
                        firstError = error
                    }
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    if firstError == nil {
                        firstError = URLError(.badServerResponse)
                    }
                }
                dispatchGroup.leave()
            }
            
            task.resume()
        }
        
        dispatchGroup.notify(queue: .main) {
                  if let error = firstError {
                      self.logger.log("Error adding messages to thread: \(error.localizedDescription)") // Debug message here
                      completion(.failure(error))
                  } else {
                      self.logger.log("Messages added to thread successfully.") // Debug message here
                      completion(.success(()))
                  }
              
        }
    }
    // Function to fetch messages for a thread
    func fetchMessagesForThread(threadId: String, completion: @escaping (Result<[String: String], Error>) -> Void) {
        logger.log("Starting to fetch messages for thread ID: \(threadId)")

        let url = URL(string: "https://api.openai.com/v1/threads/\(threadId)/messages")!
        logger.log("Constructed URL for fetching messages: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")

        logger.log("Set up request headers for message fetching")

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                self.logger.log("Fetch messages encountered an error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                self.logger.log("Received HTTP response status code: \(httpResponse.statusCode)")
            } else {
                self.logger.log("Failed to cast response to HTTPURLResponse")
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                self.logger.log("Bad server response when fetching messages")
                completion(.failure(URLError(.badServerResponse)))
                return
            }

            if let data = data {
                self.logger.log("Received data of size: \(data.count)")
                self.logger.log("HTTP Response Data: \(String(data: data, encoding: .utf8) ?? "Unable to decode data")") // Log the response data

                do {
                    let messageResponse = try JSONDecoder().decode(MessageResponse.self, from: data)
                    let messages = messageResponse.data
                    var messageDictionary = [String: String]()

                    for message in messages {
                        if let content = message.content.first?.text.value {
                            let role = message.role
                            messageDictionary[role] = content
                        }
                    }

                    self.logger.log("Successfully parsed messages with count: \(messageDictionary.count)")
                    completion(.success(messageDictionary))
                } catch {
                    self.logger.log("Failed to decode JSON response: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            } else {
                self.logger.log("No data received in response")
                completion(.failure(URLError(.cannotParseResponse)))
            }
        }

        logger.log("Resuming data task to fetch messages")
        task.resume()
    }

    func executeRun(threadId: String, completion: @escaping (Result<String, Error>) -> Void) {
        logger.log("Executing run for thread ID: \(threadId)")
        guard let url = URL(string: "https://api.openai.com/v1/threads/\(threadId)/runs") else {
            logger.log("Invalid URL for execution run.")
            completion(.failure(URLError(.badURL)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")
        
        let body: [String: Any] = ["assistant_id": assistantId]
        do {
            let requestBody = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = requestBody
            logger.log("Request body prepared for execution run: \(String(data: requestBody, encoding: .utf8) ?? "")")
        } catch {
            logger.log("Failed to serialize request body: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                self.logger.log("Execution run failed with error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                self.logger.log("Bad server response: response is not an HTTPURLResponse")
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            self.logger.log("Received HTTP status code: \(httpResponse.statusCode) for execution run.")
            self.logHeaders(httpResponse.allHeaderFields)
            
            if httpResponse.statusCode != 200 {
                self.logger.log("Bad server response: HTTP status code \(httpResponse.statusCode) for execution run.")
                if let data = data, let bodyString = String(data: data, encoding: .utf8) {
                    self.logger.log("Response body for error: \(bodyString)")
                }
                completion(.failure(URLError(.badServerResponse)))
                return
            }

            
            guard let data = data else {
                self.logger.log("No data received for execution run.")
                completion(.failure(URLError(.cannotParseResponse)))
                return
            }
            
            self.logger.log("Data received for execution run: \(String(data: data, encoding: .utf8) ?? "")")
            
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    self.logger.log("Successfully parsed JSON response for execution run.")
                    // Assuming the response structure matches the provided JSON, you might want to extract the "id" or other relevant information
                    if let runId = jsonObject["id"] as? String {
                        self.logger.log("Successfully retrieved run ID: \(runId) for execution run.")
                        completion(.success(runId))
                    } else {
                        self.logger.log("Failed to parse run ID from JSON response for execution run.")
                        completion(.failure(URLError(.cannotParseResponse)))
                    }
                } else {
                    self.logger.log("Failed to parse JSON response for execution run.")
                    completion(.failure(URLError(.cannotParseResponse)))
                }
            } catch {
                self.logger.log("JSON parsing error: \(error.localizedDescription) for execution run.")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }

    
    private func createThread(with messages: [[String: String]], completion: @escaping (Result<String, Error>) -> Void) {
        logger.log("Creating thread...")
        let url = URL(string: "https://api.openai.com/v1/threads")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta") // Add this line
        
        // Add the messages to the request body
        let body: [String: Any] = [
            "messages": messages
        ]
        
        do {
            let requestBody = try JSONSerialization.data(withJSONObject: body, options: [])
            request.httpBody = requestBody
            // Log the body of the request
            let requestBodyString = String(data: requestBody, encoding: .utf8) ?? "Invalid request body"
            logger.log("Request body: \(requestBodyString)")
        } catch {
            logger.log("Error serializing request body: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                self.logger.log("Thread creation failed with error: \(error.localizedDescription).")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                self.logger.log("No HTTP response received.")
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            self.logger.log("Received HTTP status code: \(httpResponse.statusCode).")
            
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                self.logger.log("Server response: \(responseString)")
            } else {
                self.logger.log("No response data received.")
            }
            
            if httpResponse.statusCode == 200, let data = data,
               let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let id = jsonObject["id"] as? String {
                self.logger.log("Thread created with ID: \(id).")
                completion(.success(id))
            } else {
                self.logger.log("Thread creation failed with bad server response or parsing error.")
                completion(.failure(URLError(.cannotParseResponse)))
            }
        }
        
        task.resume()
    }
    
    
    
    func generateSpeechFromText(text: String, completion: @escaping (Result<Data, Error>) -> Void) {
        // Define the API endpoint
        guard let url = URL(string: "https://api.openai.com/v1/audio/speech") else {
            completion(.failure(NSError(domain: "YourAppErrorDomain", code: 0, userInfo: nil)))
            return
        }

        // Define headers
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // Define the request payload
        let payload: [String: Any] = [
            "model": "tts-1",
            "input": text,
            "voice": "alloy",
            "response_format":"aac"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            completion(.failure(error))
            return
        }

        // Create a URLSession task to make the API request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(NSError(domain: "YourAppErrorDomain", code: 0, userInfo: nil)))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "YourAppErrorDomain", code: 0, userInfo: nil)))
                return
            }

            // Handle the response data
            completion(.success(data))
        }

        // Start the URLSession task
        task.resume()
    }

    
  

    struct ImageGenerationResponse: Decodable {
        let created: Int
        let data: [ImageData]
    }

    struct ImageData: Decodable {
        let url: String
    }

   
        func generateImages(prompt: String,completion: @escaping (Result<[String], Error>) -> Void) {
            // Define the request URL
            guard let url = URL(string: "https://api.openai.com/v1/images/generations") else {
                completion(.failure(NSError(domain: "YourAppErrorDomain", code: 0, userInfo: nil)))
                return
            }
            
            // Define headers
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Define the request payload
            let payload: [String: Any] = [
                "model": "dall-e-3",
                "prompt": prompt,
                "n": 1, // Number of images you want
                "size": "1024x1024",
                "style":"vivid"
            ]
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
            } catch {
                completion(.failure(error))
                return
            }
            
            // Create a URLSession task to make the API request
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    completion(.failure(NSError(domain: "YourAppErrorDomain", code: 0, userInfo: nil)))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(NSError(domain: "YourAppErrorDomain", code: 0, userInfo: nil)))
                    return
                }
                
                do {
                    // Decode the JSON response into your custom structs
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(ImageGenerationResponse.self, from: data)
                    let imageUrls = response.data.map { $0.url }
                    completion(.success(imageUrls))
                } catch {
                    completion(.failure(error))
                }
            }
            
            // Start the URLSession task
            task.resume()
        }
    

}
