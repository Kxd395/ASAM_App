//
//  Time.swift
//  ASAM Assessment Application
//
//  UTC and locale hardening for production correctness
//  T-0033: Clock and locale hardening
//  Addresses: Timezone skew, DST boundaries, locale influence
//

import Foundation

/// Centralized time and locale utilities enforcing UTC and ISO-8601
enum Time {
    /// UTC timezone (no offset)
    static let zone = TimeZone(secondsFromGMT: 0)!

    /// ISO-8601 formatter with fractional seconds
    static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        f.timeZone = zone
        return f
    }()

    /// POSIX locale for ASCII number parsing (no regional variations)
    static let posixLocale = Locale(identifier: "en_US_POSIX")

    /// Current UTC timestamp as ISO string
    static var nowISO: String {
        iso.string(from: Date())
    }

    /// Parse ISO-8601 string to Date
    static func parse(_ iso: String) -> Date? {
        self.iso.date(from: iso)
    }

    /// Check if two timestamps are within acceptable skew (1 second)
    static func withinSkew(_ a: Date, _ b: Date, tolerance: TimeInterval = 1.0) -> Bool {
        abs(a.timeIntervalSince(b)) <= tolerance
    }
}

extension Date {
    /// Convert to UTC ISO-8601 string with fractional seconds
    var isoUTC: String {
        Time.iso.string(from: self)
    }

    /// Add time interval and return new date
    func adding(seconds: TimeInterval) -> Date {
        addingTimeInterval(seconds)
    }

    /// Check if date is in the past
    var isPast: Bool {
        self < Date()
    }

    /// Check if date is in the future
    var isFuture: Bool {
        self > Date()
    }
}

/// Parse ASCII decimal with POSIX locale (no regional decimal separators)
func parseDecimalASCII(_ s: String) -> Decimal? {
    let f = NumberFormatter()
    f.locale = Time.posixLocale
    f.decimalSeparator = "."
    f.numberStyle = .decimal
    return f.number(from: s)?.decimalValue
}

/// Parse ASCII integer with POSIX locale
func parseIntASCII(_ s: String) -> Int? {
    let f = NumberFormatter()
    f.locale = Time.posixLocale
    f.numberStyle = .none
    return f.number(from: s)?.intValue
}

/// Format decimal to ASCII string with POSIX locale
func formatDecimalASCII(_ d: Decimal) -> String {
    let f = NumberFormatter()
    f.locale = Time.posixLocale
    f.decimalSeparator = "."
    f.numberStyle = .decimal
    f.minimumFractionDigits = 0
    f.maximumFractionDigits = 10
    return f.string(from: d as NSDecimalNumber) ?? "0"
}
