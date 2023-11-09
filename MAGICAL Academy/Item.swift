//
//  Item.swift
//  MAGICAL Academy
//
//  Created by arash parnia on 11/8/23.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
