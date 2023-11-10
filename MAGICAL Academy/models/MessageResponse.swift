//
//  MessageResponse.swift
//  MAGICAL Academy
//
//  Created by arash parnia on 11/10/23.
//
import Foundation

enum JSONValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case dictionary([String: JSONValue])
    case array([JSONValue])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
            return
        }
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
            return
        }
        if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
            return
        }
        if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
            return
        }
        if let dictionaryValue = try? container.decode([String: JSONValue].self) {
            self = .dictionary(dictionaryValue)
            return
        }
        if let arrayValue = try? container.decode([JSONValue].self) {
            self = .array(arrayValue)
            return
        }

        throw DecodingError.typeMismatch(JSONValue.self, DecodingError.Context(codingPath: container.codingPath, debugDescription: "Invalid JSON value"))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .dictionary(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        }
    }
}

struct MessageResponse: Codable {
    let object: String
    let data: [Message]
    let firstId: String
    let lastId: String
    let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case object
        case data
        case firstId = "first_id"
        case lastId = "last_id"
        case hasMore = "has_more"
    }
}

struct Message: Codable {
    let id: String
    let object: String
    let createdAt: Int
    let threadId: String
    let role: String
    let content: [Content]
    let fileIds: [String]
    let assistantId: String?
    let runId: String?
    let metadata: [String: JSONValue]

    enum CodingKeys: String, CodingKey {
        case id
        case object
        case createdAt = "created_at"
        case threadId = "thread_id"
        case role
        case content
        case fileIds = "file_ids"
        case assistantId = "assistant_id"
        case runId = "run_id"
        case metadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        object = try container.decode(String.self, forKey: .object)
        createdAt = try container.decode(Int.self, forKey: .createdAt)
        threadId = try container.decode(String.self, forKey: .threadId)
        role = try container.decode(String.self, forKey: .role)
        content = try container.decode([Content].self, forKey: .content)
        fileIds = try container.decode([String].self, forKey: .fileIds)
        assistantId = try container.decodeIfPresent(String.self, forKey: .assistantId)
        runId = try container.decodeIfPresent(String.self, forKey: .runId)
        
        // Decode metadata manually
        let metadataContainer = try container.nestedContainer(keyedBy: DynamicCodingKeys.self, forKey: .metadata)
        var metadataDict = [String: JSONValue]()
        for key in metadataContainer.allKeys {
            let value = try metadataContainer.decode(JSONValue.self, forKey: key)
            metadataDict[key.stringValue] = value
        }
        metadata = metadataDict
    }
}

struct Content: Codable {
    let type: String
    let text: MessageText
}

struct MessageText: Codable {
    let value: String
    let annotations: [String]
}

struct DynamicCodingKeys: CodingKey {
    var intValue: Int?
    var stringValue: String

    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = "\(intValue)"
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
    }
}
