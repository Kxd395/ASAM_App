//
//  Item.swift
//  ASAM_LOC_1.0
//
//  Created by Kevin Dial on 11/11/25.
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
