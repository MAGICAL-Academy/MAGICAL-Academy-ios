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
        createThread(with: messages) { [weak self] result in
            switch result {
            case .success(let threadId):
                UserDefaults.standard.set(threadId, forKey: "ThreadId")
                self?.checkRunStatus(for: threadId) { result in
                    switch result {
                    case .success:
                        UserDefaults.standard.set(true, forKey: "RunFinished")
                        completion(.success(threadId))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func createThread(with messages: [[String: String]], completion: @escaping (Result<String, Error>) -> Void) {
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
            completion(.failure(error))
            return
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            self.logger.log("data for createThread \(String(describing: data))", level: .debug)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.cannotParseResponse)))
                return
            }
            
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                if let jsonObject = jsonObject as? [String: Any], let threadId = jsonObject["thread_id"] as? String {
                    completion(.success(threadId))
                    self.logger.log("Thread created with threadId: \(threadId)", level: .debug)
                } else {
                    completion(.failure(URLError(.cannotParseResponse)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    private func checkRunStatus(for threadId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        var runFinished = false
        let statusCheckInterval: TimeInterval = 5.0
        
        while !runFinished {
            getStatus(for: threadId) { result in
                switch result {
                case .success(let status):
                    if status == "succeeded" {
                        runFinished = true
                        self.logger.log("Status check: Thread \(threadId) has succeeded.", level: .debug)
                        completion(.success(()))
                    } else if status == "failed" {
                        runFinished = true
                        self.logger.log("Status check: Thread \(threadId) has failed.", level: .debug)
                        completion(.failure(NSError(domain: "YourAppErrorDomain", code: 0, userInfo: nil)))
                    } else {
                        self.logger.log("Status check: Thread \(threadId) is still running.", level: .debug)
                    }
                case .failure(let error):
                    self.logger.log("Status check failed with error: \(error)", level: .error)
                    completion(.failure(error))
                }
            }
            
            Thread.sleep(forTimeInterval: statusCheckInterval)
        }
    }
    
    private func getStatus(for threadId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/threads/\(threadId)/runs/latest")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("assistants=v1", forHTTPHeaderField: "OpenAI-Beta")
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.cannotParseResponse)))
                return
            }
            
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                if let jsonObject = jsonObject as? [String: Any], let status = jsonObject["status"] as? String {
                    completion(.success(status))
                    self.logger.log("Status check for threadId \(threadId): Status = \(status)", level: .debug)
                } else {
                    completion(.failure(URLError(.cannotParseResponse)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}
