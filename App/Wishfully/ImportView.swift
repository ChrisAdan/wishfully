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

/// Reads the pasteboard, keeping links from rich text as Markdown.
enum MarkdownPaste {
    static func read() -> String? {
        let pasteboard = UIPasteboard.general
        for type in [UTType.flatRTFD, UTType.rtfd, UTType.rtf] {
            if let data = pasteboard.data(forPasteboardType: type.identifier),
               let attributed = try? NSAttributedString(data: data, options: [:], documentAttributes: nil)
            {
                return markdown(from: attributed)
            }
        }
        return pasteboard.string
    }

    /// Writes every linked run as `[text](url)` and leaves the rest as plain text.
    static func markdown(from attributed: NSAttributedString) -> String {
        var output = ""
        let whole = NSRange(location: 0, length: attributed.length)
        attributed.enumerateAttribute(.link, in: whole) { value, range, _ in
            let run = attributed.attributedSubstring(from: range).string
            let link = (value as? URL) ?? (value as? String).flatMap(URL.init(string:))
            if let link, !run.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                output += "[\(run)](\(link.absoluteString))"
            } else {
                output += run
            }
        }
        return output
    }
}
