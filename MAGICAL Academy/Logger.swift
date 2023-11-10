//
//  Logger.swift
//  MAGICAL Academy
//
//  Created by arash parnia on 11/10/23.
//

import Foundation
// Logger.swift
enum LogLevel {
    case debug
    case error
}

struct Logger {
    var logLevel: LogLevel = .error

    func log(_ message: String, level: LogLevel = .debug) {
        if level == .debug && logLevel == .debug {
            print("[Debug] \(message)")
        } else if level == .error {
            print("[Error] \(message)")
        }
    }
}
