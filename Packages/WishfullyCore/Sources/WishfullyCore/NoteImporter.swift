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
public enum NoteImporter {
    public static func parse(_ text: String, importedAt: Date = Date()) -> NoteImport {
        var state = ParseState()
        for rawLine in text.components(separatedBy: .newlines) {
            state.consume(NoteLine(rawLine))
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

    init(_ rawLine: String) {
        let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        if line.isEmpty || Self.isSeparator(line) {
            self = .skip
        } else if let marker = Self.markers.first(where: { line.hasPrefix($0) }) {
            let text = Self.collapsingWhitespace(String(line.dropFirst(marker.count)))
            self = text.isEmpty ? .skip : .wish(LinkedTitle(parsing: text))
        } else {
            let category = Self.categoryName(from: line)
            self = .heading(raw: Self.collapsingWhitespace(line), category: category.isEmpty ? line : category)
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

    private static func collapsingWhitespace(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}
