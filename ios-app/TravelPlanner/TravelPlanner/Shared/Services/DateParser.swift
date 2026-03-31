//
//  DateParser.swift
//  TravelPlanner
//
//  Created by Assistant on 3/23/26.
//

import Foundation

/// Parses a variety of human-entered date/time strings into `Date` values.
/// - Supports multiple common formats and natural language like "tomorrow", "next Friday", etc.
struct DateParser {
    /// Attempts to parse the given string into a Date using several strategies.
    /// - Parameters:
    ///   - string: The input string containing date/time text.
    ///   - reference: The reference date for relative expressions (defaults to now).
    ///   - timeZone: Optional timezone to assume for parsed dates (defaults to current).
    /// - Returns: A parsed `Date` if successful, otherwise `nil`.
    func parse(_ string: String, reference: Date = Date(), timeZone: TimeZone = .current) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // 1) Try natural language via NSDataDetector (dates).
        if let date = detectNaturalLanguageDate(in: trimmed, reference: reference, timeZone: timeZone) {
            return date
        }

        // 2) Try a list of common, locale-aware formats.
        for formatter in Self.formatters(timeZone: timeZone) {
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }

        // 3) Try ISO8601 variations.
        if let date = Self.iso8601Formatter.date(from: trimmed) {
            return date
        }
        if let date = Self.iso8601DateOnlyFormatter.date(from: trimmed) {
            return date
        }

        return nil
    }

    // MARK: - Helpers

    private func detectNaturalLanguageDate(in text: String, reference: Date, timeZone: TimeZone) -> Date? {
        let types: NSTextCheckingResult.CheckingType = [.date]
        guard let detector = try? NSDataDetector(types: types.rawValue) else { return nil }

        let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)
        var best: (date: Date, range: NSRange)?
        detector.enumerateMatches(in: text, options: [], range: fullRange) { match, _, _ in
            guard let match, let date = match.date else { return }
            // Prefer the longest match; fallback to first
            if best == nil || (best!.range.length < match.range.length) {
                best = (date, match.range)
            }
        }
        return best?.date
    }

    private static func formatters(timeZone: TimeZone) -> [DateFormatter] {
        var f: [DateFormatter] = []

        func make(_ format: String, locale: Locale = .current) -> DateFormatter {
            let df = DateFormatter()
            df.locale = locale
            df.timeZone = timeZone
            df.dateFormat = format
            return df
        }

        // Common US and international formats
        f.append(make("yyyy-MM-dd HH:mm"))
        f.append(make("yyyy-MM-dd"))
        f.append(make("MM/dd/yyyy"))
        f.append(make("M/d/yyyy"))
        f.append(make("dd/MM/yyyy"))
        f.append(make("d/M/yyyy"))
        f.append(make("MMM d, yyyy"))
        f.append(make("MMMM d, yyyy"))
        f.append(make("MMM d, yyyy h:mm a"))
        f.append(make("MMMM d, yyyy h:mm a"))
        f.append(make("EEE, MMM d, yyyy"))
        f.append(make("EEE, MMM d, yyyy h:mm a"))
        f.append(make("d MMM yyyy"))
        f.append(make("d MMM yyyy HH:mm"))
        f.append(make("d MMMM yyyy"))
        f.append(make("d MMMM yyyy HH:mm"))
        f.append(make("HH:mm dd/MM/yyyy"))
        f.append(make("h:mm a MMM d, yyyy"))

        return f
    }

    private static let iso8601Formatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let iso8601DateOnlyFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f
    }()
}
