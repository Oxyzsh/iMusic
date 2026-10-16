import Foundation

struct LyricLine: Identifiable, Equatable {
    let id: Int
    let timestamp: TimeInterval?
    let text: String
}

struct LyricsDocument: Equatable {
    let lines: [LyricLine]
    let isSynchronized: Bool

    var plainText: String {
        lines.map(\.text).joined(separator: "\n")
    }

    func activeLineIndex(at time: TimeInterval) -> Int? {
        guard isSynchronized else { return nil }

        var activeIndex: Int?
        for (index, line) in lines.enumerated() {
            guard let timestamp = line.timestamp else { continue }
            if timestamp <= time {
                activeIndex = index
            } else {
                break
            }
        }
        return activeIndex
    }
}

enum LRCParser {
    private static let timestampRegex: NSRegularExpression = {
        let pattern = #"\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]"#
        return try! NSRegularExpression(pattern: pattern)
    }()

    static func parse(_ text: String) -> LyricsDocument {
        var parsedLines: [(timestamp: TimeInterval?, text: String, order: Int)] = []
        var order = 0

        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }

            let range = NSRange(line.startIndex..<line.endIndex, in: line)
            let matches = timestampRegex.matches(in: line, range: range)

            if matches.isEmpty {
                parsedLines.append((nil, line, order))
                order += 1
                continue
            }

            let textRangeStart = matches.last.map { NSMaxRange($0.range) } ?? 0
            let lyricText = (line as NSString)
                .substring(from: textRangeStart)
                .trimmingCharacters(in: .whitespaces)

            for match in matches {
                guard
                    let minuteRange = Range(match.range(at: 1), in: line),
                    let secondRange = Range(match.range(at: 2), in: line)
                else { continue }

                let minutes = Double(line[minuteRange]) ?? 0
                let seconds = Double(line[secondRange]) ?? 0
                var fraction = 0.0

                if let fractionRange = Range(match.range(at: 3), in: line) {
                    let fractionText = String(line[fractionRange])
                    let scale = pow(10.0, Double(fractionText.count))
                    fraction = (Double(fractionText) ?? 0) / scale
                }

                parsedLines.append((minutes * 60 + seconds + fraction, lyricText, order))
                order += 1
            }
        }

        let hasTimestamps = parsedLines.contains { $0.timestamp != nil }
        let sortedLines: [(timestamp: TimeInterval?, text: String, order: Int)]

        if hasTimestamps {
            sortedLines = parsedLines.sorted { lhs, rhs in
                switch (lhs.timestamp, rhs.timestamp) {
                case let (left?, right?):
                    if left == right { return lhs.order < rhs.order }
                    return left < right
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return lhs.order < rhs.order
                }
            }
        } else {
            sortedLines = parsedLines
        }

        return LyricsDocument(
            lines: sortedLines.enumerated().map { index, item in
                LyricLine(id: index, timestamp: item.timestamp, text: item.text)
            },
            isSynchronized: hasTimestamps
        )
    }
}
