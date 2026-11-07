import Foundation

/// One HTML start tag, with lower-cased name and attribute keys.
/// `content` is filled in only for `<script>` tags: the raw text of the script.
struct HTMLTag: Equatable, Sendable {
    let name: String
    let attributes: [String: String]
    let content: String?

    subscript(attribute key: String) -> String? {
        attributes[key]
    }
}

/// A deliberately small, forgiving HTML tag scanner for untrusted pages.
///
/// It never executes anything and never builds a DOM. It walks the text once,
/// collecting start tags and their attributes. Every loop advances the cursor,
/// so even malformed input terminates, and the caller caps input size and tag count.
struct HTMLScanner {
    private let chars: [Unicode.Scalar]
    private var position = 0

    init(_ html: String) {
        chars = Array(html.unicodeScalars)
    }

    /// Scans the whole document, returning at most `limit` tags.
    static func tags(in html: String, limit: Int = 10000) -> [HTMLTag] {
        var scanner = HTMLScanner(html)
        var tags: [HTMLTag] = []
        while tags.count < limit, let tag = scanner.nextTag() {
            tags.append(tag)
        }
        return tags
    }

    mutating func nextTag() -> HTMLTag? {
        while position < chars.count {
            guard chars[position] == "<" else {
                position += 1
                continue
            }
            position += 1
            if skipCommentIfPresent() {
                continue
            }
            guard let first = current, first.properties.isAlphabetic else { continue }
            return readTag()
        }
        return nil
    }

    // MARK: - Tag parts

    private mutating func readTag() -> HTMLTag {
        let name = readName().lowercased()
        let attributes = readAttributes()
        position = min(position + 1, chars.count) // step past ">"
        let content = name == "script" ? readScriptContent() : nil
        return HTMLTag(name: name, attributes: attributes, content: content)
    }

    private mutating func readAttributes() -> [String: String] {
        var attributes: [String: String] = [:]
        while let char = current, char != ">" {
            if char.properties.isWhitespace || char == "/" {
                position += 1
                continue
            }
            let key = readName().lowercased()
            guard !key.isEmpty else {
                position += 1 // unexpected character: skip it
                continue
            }
            let value = readAttributeValue()
            if attributes[key] == nil {
                attributes[key] = Self.decodeEntities(value)
            }
        }
        return attributes
    }

    private mutating func readAttributeValue() -> String {
        skipWhitespace()
        guard current == "=" else { return "" }
        position += 1
        skipWhitespace()
        guard let opener = current else { return "" }
        if opener == "\"" || opener == "'" {
            position += 1
            let value = read { $0 != opener }
            position += 1 // closing quote
            return value
        }
        return read { !$0.properties.isWhitespace && $0 != ">" }
    }

    private mutating func readName() -> String {
        read(while: Self.isNameCharacter)
    }

    /// Returns the raw text up to `</script`, then moves past it.
    private mutating func readScriptContent() -> String {
        let start = min(position, chars.count)
        let end = find(Array("</script".unicodeScalars)) ?? chars.count
        let content = String(String.UnicodeScalarView(chars[start ..< max(start, end)]))
        position = end
        return content
    }

    /// Skips `<!-- ... -->` and `<!DOCTYPE ...>`. Returns true if it skipped something.
    private mutating func skipCommentIfPresent() -> Bool {
        guard current == "!" else { return false }
        if matches(Array("!--".unicodeScalars)) {
            position = (find(Array("-->".unicodeScalars)) ?? chars.count - 3) + 3
        } else {
            position = (find([">"]) ?? chars.count - 1) + 1
        }
        return true
    }

    // MARK: - Cursor helpers

    private var current: Unicode.Scalar? {
        position < chars.count ? chars[position] : nil
    }

    private mutating func skipWhitespace() {
        _ = read { $0.properties.isWhitespace }
    }

    private mutating func read(while predicate: (Unicode.Scalar) -> Bool) -> String {
        var view = String.UnicodeScalarView()
        while let char = current, predicate(char) {
            view.append(char)
            position += 1
        }
        return String(view)
    }

    /// True if `needle` (lower-case ASCII) starts at the cursor, ignoring case.
    private func matches(_ needle: [Unicode.Scalar], at start: Int? = nil) -> Bool {
        let origin = start ?? position
        guard origin + needle.count <= chars.count else { return false }
        for (offset, scalar) in needle.enumerated() where Self.asciiLowercased(chars[origin + offset]) != scalar {
            return false
        }
        return true
    }

    /// Index of the next case-insensitive occurrence of `needle` at or after the cursor.
    private func find(_ needle: [Unicode.Scalar]) -> Int? {
        var index = position
        while index + needle.count <= chars.count {
            if matches(needle, at: index) {
                return index
            }
            index += 1
        }
        return nil
    }

    // MARK: - Character classes

    private static func isNameCharacter(_ char: Unicode.Scalar) -> Bool {
        char.properties.isAlphabetic || ("0" ... "9").contains(char)
            || char == "-" || char == ":" || char == "_" || char == "."
    }

    private static func asciiLowercased(_ char: Unicode.Scalar) -> Unicode.Scalar {
        guard ("A" ... "Z").contains(char), let lower = Unicode.Scalar(char.value + 32) else { return char }
        return lower
    }

    private static func decodeEntities(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&amp;", with: "&")
    }
}
