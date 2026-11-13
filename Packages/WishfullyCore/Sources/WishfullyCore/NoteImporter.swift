import Foundation

/// The result of importing a pasted note: an optional list title and the wishes, in note order.
public struct NoteImport: Equatable, Sendable {
    public let title: String?
    public let wishes: [Wish]

    /// Categories in the order they first appear in the note.
    public var categories: [String] {
        var seen = Set<String>()
        return wishes.compactMap(\.category).filter { seen.insert($0).inserted }
    }
}

/// Turns a checklist-style note (such as one pasted from Apple Notes) into wishes.
///
/// Format rules:
/// - A line starting with a checklist or bullet marker (`- [ ]`, `- [x]`, `-`, `*`, `•`, `☐`) is a wish.
///   A Markdown link or bare web URL in the line becomes the wish's link, and its host the store.
/// - Any other text line is a heading; it becomes the category for the wishes below it.
///   Emoji in headings are dropped from the category name ("Style 🎀" becomes "Style").
/// - A heading followed directly by another heading, before any wish, is the list title.
/// - A heading stays in effect until the next heading, across blank lines.
/// - Separator lines (`----`, `***`, `___`) and blank lines are skipped.
///
/// A note without a single marker (a checklist copied as rich text can lose its checkboxes) is read
/// again in markerless mode: a line with an emoji is a heading, and every other line is a wish.
public enum NoteImporter {
    public static func parse(_ text: String, importedAt: Date = Date()) -> NoteImport {
        let lines = text.components(separatedBy: .newlines)
        var state = ParseState()
        lines.forEach { state.consume(NoteLine($0, markerless: false)) }
        if state.items.isEmpty {
            state = ParseState()
            lines.forEach { state.consume(NoteLine($0, markerless: true)) }
        }
        let wishes = state.items.enumerated().map { index, item in
            Wish(
                title: item.title,
                url: item.url,
                store: LinkedTitle.store(for: item.url),
                category: item.category,
                // Millisecond steps keep note order under the oldest-first sort.
                createdAt: importedAt.addingTimeInterval(Double(index) / 1000)
            )
        }
        return NoteImport(title: state.resolvedTitle, wishes: wishes)
    }
}

// MARK: - Parsing

private struct ParseState {
    struct Item {
        let title: String
        let url: URL?
        let category: String?
    }

    private(set) var items: [Item] = []
    private var title: String?
    private var heading: (raw: String, category: String)?
    private var itemsUnderHeading = 0

    /// A lone heading with nothing under it (a note that is just a title) is the title.
    var resolvedTitle: String? {
        title ?? (items.isEmpty ? heading?.raw : nil)
    }

    mutating func consume(_ line: NoteLine) {
        switch line {
        case let .wish(linked):
            items.append(Item(title: linked.title, url: linked.url, category: heading?.category))
            itemsUnderHeading += 1
        case let .heading(raw, category):
            if let previous = heading, itemsUnderHeading == 0, items.isEmpty, title == nil {
                title = previous.raw
            }
            heading = (raw, category)
            itemsUnderHeading = 0
        case .skip:
            break
        }
    }
}

private enum NoteLine {
    case wish(LinkedTitle)
    case heading(raw: String, category: String)
    case skip

    private static let markers = [
        "- [ ]",
        "- [x]",
        "- [X]",
        "* [ ]",
        "* [x]",
        "[ ]",
        "[x]",
        "☐",
        "☑",
        "✅",
        "•",
        "◦",
        "-",
        "*",
    ]

    init(_ rawLine: String, markerless: Bool) {
        let line = Self.cleaned(rawLine)
        if line.isEmpty || Self.isSeparator(line) {
            self = .skip
        } else if let text = Self.itemText(line) {
            self = text.isEmpty ? .skip : .wish(LinkedTitle(parsing: text))
        } else if markerless, !Self.hasEmoji(line) {
            self = .wish(LinkedTitle(parsing: Self.collapsingWhitespace(line)))
        } else {
            let category = Self.categoryName(from: line)
            self = .heading(raw: Self.collapsingWhitespace(line), category: category.isEmpty ? line : category)
        }
    }

    /// Trimmed, with object replacement characters (rich-text checkboxes) removed.
    static func cleaned(_ rawLine: String) -> String {
        rawLine.replacingOccurrences(of: "\u{FFFC}", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The text after a checklist or bullet marker, tidied; nil when the line has no marker.
    static func itemText(_ line: String) -> String? {
        markers.first(where: { line.hasPrefix($0) }).map { collapsingWhitespace(String(line.dropFirst($0.count))) }
    }

    /// Emoji drawn as pictures: "🎀", "⭐️", "❤️". Text symbols such as "™" do not count.
    static func hasEmoji(_ line: String) -> Bool {
        let scalars = Array(line.unicodeScalars)
        return scalars.indices.contains { index in
            let scalar = scalars[index]
            let nextIsEmojiStyle = index + 1 < scalars.count && scalars[index + 1].value == 0xFE0F
            return scalar.properties.isEmojiPresentation || (scalar.properties.isEmoji && nextIsEmojiStyle)
        }
    }

    private static func isSeparator(_ line: String) -> Bool {
        guard line.count >= 3, let first = line.first, "-*_=".contains(first) else { return false }
        return line.allSatisfy { $0 == first }
    }

    /// Letters, numbers and simple punctuation survive; emoji and symbols are removed.
    private static func categoryName(from heading: String) -> String {
        collapsingWhitespace(String(heading
                .filter { $0.isLetter || $0.isNumber || $0.isWhitespace || "&'-/".contains($0) }))
    }

    static func collapsingWhitespace(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}

// MARK: - Links from rich text

/// One line of a rich-text copy that carries a link, such as an Apple Notes item whose text is
/// linked to a product page.
public struct LinkedLine: Equatable, Sendable {
    public let text: String
    public let url: URL

    public init(text: String, url: URL) {
        self.text = text
        self.url = url
    }
}

public extension NoteImporter {
    /// Adds each rich-text line's link to the matching line of the plain-text copy.
    ///
    /// The plain copy keeps the checklist markers and the rich copy keeps the links; the merge
    /// keeps both. A line matches when its item text equals the linked line's text, ignoring
    /// case and spacing, or when one contains the other and both have at least
    /// `minimumMatchCharacters` characters.
    static func addingLinks(_ links: [LinkedLine], to plain: String) -> String {
        let keyed = links.map { (key: matchKey($0.text), url: $0.url) }.filter { !$0.key.isEmpty }
        return plain.components(separatedBy: .newlines).map { line in
            let content = NoteLine.cleaned(line)
            let key = matchKey(NoteLine.itemText(content) ?? content)
            guard !key.isEmpty, !line.contains("http://"), !line.contains("https://") else { return line }
            let match = keyed.first { $0.key == key } ?? keyed.first { link in
                min(link.key.count, key.count) >= minimumMatchCharacters
                    && (link.key.contains(key) || key.contains(link.key))
            }
            return match.map { "\(line) \($0.url.absoluteString)" } ?? line
        }.joined(separator: "\n")
    }

    /// Shortest text compared by containment, so a two-letter item matches no long line by accident.
    static let minimumMatchCharacters = 4

    private static func matchKey(_ text: String) -> String {
        NoteLine.collapsingWhitespace(NoteLine.cleaned(text)).lowercased()
    }
}
