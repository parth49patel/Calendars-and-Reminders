//
//  Item.swift
//  CalRem
//
//  Created by Parth Patel on 2026-04-27.
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
