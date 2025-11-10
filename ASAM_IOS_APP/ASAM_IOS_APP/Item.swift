//
//  Item.swift
//  ASAM_IOS_APP
//
//  Created by Kevin Dial on 11/9/25.
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
