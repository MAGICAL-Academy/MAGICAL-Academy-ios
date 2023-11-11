//
//  AssistantThreadManager.swift
//  MAGICAL Academy
//
//  Created by arash parnia on 11/10/23.
//
import Foundation

class AssistantThreadManager {
    private let apiKey: String
    private let assistantId: String
    private let session: URLSession
    private let logger = Logger()
    
    init(apiKey: String, assistantId: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.assistantId = assistantId
        self.session = session
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

    private func checkRunStatus(runId: String, threadId: String, completion: @escaping (Result<Void, Error>) -> Void) {
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


    private func fetchRunStatus(runId: String, threadId: String, completion: @escaping (String, Error?) -> Void) {
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

    
    private func getStatus(for threadId: String, completion: @escaping (Result<String, Error>) -> Void) {
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

}
