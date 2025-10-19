//
//  Item.swift
//  EarHealthTimer
//
//  Created by 尹家杰 on 2025/10/19.
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
