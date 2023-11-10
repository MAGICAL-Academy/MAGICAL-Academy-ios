//
//  AssistantService.swift
//  MAGICAL Academy
//
//  Created by arash parnia on 11/9/23.
//

import Foundation
import os.log

class AssistantService {
    private let apiKey: String
    private let session: URLSession
    private let assistantId: String = "asst_T7HClKQYmKUNOJmxlKW79XWQ"
    private let logger = Logger()
    private var timer: Timer?
    
    init(session: URLSession = .shared) {
        self.apiKey = AssistantService.fetchAPIKey()
        self.session = session
        logger.log("AssistantService initialized.")
    }
    
    private static func fetchAPIKey() -> String {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let secrets = NSDictionary(contentsOfFile: path),
              let apiKey = secrets["CHAT_GPT_API_KEY"] as? String else {
            fatalError("API Key not found. Ensure you have Secrets.plist with the CHAT_GPT_API_KEY key.")
        }
        return apiKey
    }
    
    func runAssistant(with messages: [[String: String]], completion: @escaping (Result<(String, String), Error>) -> Void) {
        logger.log("runAssistant started.", level: .debug)

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
            logger.log("Request body prepared for combined thread/run execution.", level: .debug)
        } catch {
            logger.log("Failed to serialize request body: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                self.logger.log("Assistant run failed with error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                self.logger.log("Bad server response for assistant run.")
                completion(.failure(URLError(.badServerResponse)))
                return
            }

            guard let data = data else {
                self.logger.log("Data object is nil for assistant run")
                completion(.failure(URLError(.cannotParseResponse)))
                return
            }

            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                self.logger.log("Serialized response data to JSON for assistant run", level: .debug)

                if let jsonObject = jsonObject as? [String: Any], let threadId = jsonObject["thread_id"] as? String {
                    self.logger.log("Successfully parsed thread_id: \(threadId) for assistant run", level: .debug)

                    // Now, you need to extract the runId from the response as well
                    if let runId = jsonObject["id"] as? String {
                        completion(.success((threadId, runId)))
                    } else {
                        self.logger.log("Failed to parse run_id from JSON response for assistant run")
                        completion(.failure(URLError(.cannotParseResponse)))
                    }
                } else {
                    self.logger.log("Failed to parse thread_id from JSON response for assistant run")
                    completion(.failure(URLError(.cannotParseResponse)))
                }
            } catch {
                self.logger.log("Failed to serialize response data to JSON with error: \(error.localizedDescription) for assistant run")
                completion(.failure(error))
            }
        }

        task.resume()
    }


    
    
    private func checkRunCompletion(runId: String, threadId: String, completion: @escaping (Bool) -> Void) {
        let checkInterval = 2.0 // How often to check (in seconds)
        let maxChecks = 30 // Increased number of checks before giving up

        var checksDone = 0
        let startTime = Date() // Record the start time
        self.timer?.invalidate()

        self.timer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            let elapsedTime = Date().timeIntervalSince(startTime) // Calculate elapsed time
            let remainingTime = Double(maxChecks - checksDone) * checkInterval // Calculate remaining time
            self.logger.log("Checking status... (\(checksDone + 1)/\(maxChecks), Elapsed time: \(elapsedTime)s, Remaining time: \(remainingTime)s)", level: .debug)

            self.fetchRunStatus(runId: runId, threadId: threadId) { status, error in
                checksDone += 1

                if let error = error {
                    self.logger.log("Error fetching run status: \(error.localizedDescription)")
                    self.timer?.invalidate()
                    completion(false)
                    return
                }
                switch status {
                case "completed":
                    self.logger.log("Run completed successfully after \(elapsedTime)s.", level: .debug)
                    self.timer?.invalidate()
                    completion(true)
                case "queued", "in_progress":
                    self.logger.log("Run is \(status) after \(elapsedTime)s. Estimated time until completion or timeout: \(remainingTime)s.", level: .debug)
                    if checksDone >= maxChecks {
                        self.logger.log("Run remained \(status) too long; giving up after \(elapsedTime)s.")
                        self.timer?.invalidate()
                        completion(false)
                    }
                default:
                    self.logger.log("Run status is \(status) after \(elapsedTime)s.", level: .debug)
                    if checksDone >= maxChecks {
                        self.logger.log("Maximum number of status checks reached after \(elapsedTime)s. Run did not complete in time.")
                        self.timer?.invalidate()
                        completion(false)
                    }
                }
                // If status is not completed and maxChecks is not reached, the timer will fire again
            }
        }
        self.timer?.fire()
    }

// Remember to invalidate the timer when you're done with it, such as when the object is deinitialized
deinit {
    timer?.invalidate()
}





    func fetchRunStatus(runId: String, threadId: String, completion: @escaping (String, Error?) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/threads/\(threadId)/runs/\(runId)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")

        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.log("Error fetching run status: \(error.localizedDescription)")
                completion("", error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                self.logger.log("No HTTPURLResponse received.")
                completion("", URLError(.badServerResponse))
                return
            }
            
            self.logger.log("HTTP Status Code: \(httpResponse.statusCode)", level: .debug)
            
            if httpResponse.statusCode != 200 {
                self.logger.log("Bad server response: HTTP Status Code \(httpResponse.statusCode)")
                completion("", URLError(.badServerResponse))
                return
            }
            
            guard let data = data else {
                self.logger.log("Data object is nil when fetching run status.")
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
                        self.logger.log("Status field not found in JSON response.")
                        completion("", URLError(.cannotParseResponse))
                    }
                } else {
                    self.logger.log("Failed to cast JSON response to [String: Any].")
                    completion("", URLError(.cannotParseResponse))
                }
            } catch {
                self.logger.log("JSON parsing error: \(error.localizedDescription)")
                completion("", error)
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
    
    
    
    
    private func addMessagesToThread(threadId: String, messages: [[String: String]], completion: @escaping (Result<Void, Error>) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/threads/\(threadId)/messages")!
        
        let dispatchGroup = DispatchGroup()
        var firstError: Error?
        
        for message in messages {
            dispatchGroup.enter()
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
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
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    private func fetchMessagesForThread(threadId: String, completion: @escaping (Result<[String], Error>) -> Void) {
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
            
            if let data = data {
                self.logger.log("Received data of size: \(data.count) bytes")
            } else {
                self.logger.log("No data received in response")
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                self.logger.log("Bad server response when fetching messages")
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            guard let data = data else {
                self.logger.log("Data object is nil when fetching messages")
                completion(.failure(URLError(.cannotParseResponse)))
                return
            }
            
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                self.logger.log("Serialized response data to JSON")
                if let jsonObject = jsonObject as? [String: Any], let messages = jsonObject["data"] as? [[String: Any]] {
                    let contentList = messages.compactMap { messageDict -> String? in
                        if let contentArray = messageDict["content"] as? [[String: Any]],
                           let textDict = contentArray.first,
                           let textValue = textDict["text"] as? [String: Any],
                           let value = textValue["value"] as? String {
                            return value
                        }
                        return nil
                    }
                    self.logger.log("Successfully parsed messages with count: \(contentList.count)")
                    completion(.success(contentList))
                } else {
                    self.logger.log("Failed to cast JSON to expected dictionary type or 'data' key not found")
                    completion(.failure(URLError(.cannotParseResponse)))
                }
            } catch {
                self.logger.log("Failed to serialize response data to JSON with error: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        logger.log("Resuming data task to fetch messages")
        task.resume()
    }
    
    
    private func executeRun(threadId: String, completion: @escaping (Result<String, Error>) -> Void) {
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

    private func logHeaders(_ headers: [AnyHashable: Any]) {
        logger.log("HTTP Response Headers:")
        headers.forEach { header in
            let keyString = String(describing: header.key)
            let valueString = String(describing: header.value)
            logger.log("\(keyString): \(valueString)")
        }
    }

}
