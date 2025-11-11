//
//  TimeUtility.swift
//  ASAM Assessment Application
//
//  Time formatting utilities for consistent timestamp handling
//

import Foundation

/// Time formatting utilities
struct Time {
    /// ISO 8601 formatter for timestamps
    static let iso = ISO8601DateFormatter()
    
    /// Current time in ISO format
    static var nowISO: String {
        return iso.string(from: Date())
    }
    
    /// Format date to ISO string
    static func isoString(from date: Date) -> String {
        return iso.string(from: date)
    }
}