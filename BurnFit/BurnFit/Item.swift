//
//  Item.swift
//  BurnFit
//
//  Created by d6 on 30/10/26.
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
