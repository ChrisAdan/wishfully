import SwiftUI
import UIKit
import UniformTypeIdentifiers
import WishfullyCore

/// Imports a checklist note: paste it, check the preview, add every item at once.
///
/// Apple Notes puts linked text on the pasteboard as rich text. `MarkdownPaste` writes each link
/// as `[text](url)`, which `NoteImporter` reads (dev-blog post 007).
struct ImportView: View {
    let listID: String
    @Environment(CloudStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var isImporting = false

    private var parsed: NoteImport {
        NoteImporter.parse(text)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button("Paste from a note", systemImage: "doc.on.clipboard") {
                        text = MarkdownPaste.read() ?? text
                    }
                    TextEditor(text: $text)
                        .frame(minHeight: 160)
                        .font(.callout.monospaced())
                        .accessibilityLabel("Note text")
                } footer: {
                    Text(
                        "Lines that start with a checkbox, dash or bullet become wishes. Other lines become categories."
                    )
                }
                let wishes = parsed.wishes
                if !wishes.isEmpty {
                    Section("\(wishes.count) wishes, \(wishes.count { $0.url != nil }) with links") {
                        ForEach(wishes.prefix(50)) { wish in
                            VStack(alignment: .leading) {
                                Text(wish.title)
                                Text([wish.category, wish.store].compactMap(\.self).joined(separator: " · "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Import a note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        isImporting = true
                        Task {
                            await store.importWishes(parsed.wishes, into: listID)
                            dismiss()
                        }
                    }
                    .disabled(parsed.wishes.isEmpty || isImporting)
                }
            }
        }
    }
}

/// Reads the pasteboard, keeping both the checklist shape and the links.
///
/// Apple Notes copies a note as plain text, which keeps the checklist markers, and as rich text,
/// which keeps the links. The paste takes the plain lines and adds each rich-text line's link to
/// its match (`NoteImporter.addingLinks`).
@MainActor
enum MarkdownPaste {
    static func read() -> String? {
        let pasteboard = UIPasteboard.general
        let plain = pasteboard.string
        guard let rich = richText(from: pasteboard) else { return plain }
        guard let plain, !plain.isEmpty else { return markdown(from: rich) }
        return NoteImporter.addingLinks(linkedLines(in: rich), to: plain)
    }

    private static func richText(from pasteboard: UIPasteboard) -> NSAttributedString? {
        for type in [UTType.flatRTFD, UTType.rtfd, UTType.rtf] {
            if let data = pasteboard.data(forPasteboardType: type.identifier),
               let text = try? NSAttributedString(data: data, options: [:], documentAttributes: nil)
            {
                return text
            }
        }
        guard let html = pasteboard.data(forPasteboardType: UTType.html.identifier) else { return nil }
        return try? NSAttributedString(
            data: html,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue,
            ],
            documentAttributes: nil
        )
    }

    /// Every line of the rich text that carries a web link, with the line's text.
    static func linkedLines(in rich: NSAttributedString) -> [LinkedLine] {
        let text = rich.string as NSString
        var lines: [LinkedLine] = []
        text
            .enumerateSubstrings(
                in: NSRange(location: 0, length: text.length),
                options: .byLines
            ) { line, range, _, _ in
                guard let line, let url = firstLink(in: rich, range: range) else { return }
                lines.append(LinkedLine(text: line, url: url))
            }
        return lines
    }

    /// Writes every linked run as `[text](url)`, for rich text that arrives without a plain copy.
    static func markdown(from rich: NSAttributedString) -> String {
        var output = ""
        rich.enumerateAttribute(.link, in: NSRange(location: 0, length: rich.length)) { value, range, _ in
            let run = rich.attributedSubstring(from: range).string
            if let link = webURL(value), !run.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                output += "[\(run)](\(link.absoluteString))"
            } else {
                output += run
            }
        }
        return output
    }

    private static func firstLink(in rich: NSAttributedString, range: NSRange) -> URL? {
        var found: URL?
        rich.enumerateAttribute(.link, in: range) { value, _, stop in
            if let link = webURL(value) {
                found = link
                stop.pointee = true
            }
        }
        return found
    }

    private static func webURL(_ value: Any?) -> URL? {
        let url = (value as? URL) ?? (value as? String).flatMap(URL.init(string:))
        guard let scheme = url?.scheme?.lowercased(), scheme == "https" || scheme == "http" else { return nil }
        return url
    }
}
