import Foundation
import Testing
@testable import WishfullyCore

@Suite("Linked titles")
struct LinkedTitleTests {
    @Test("A Markdown link supplies the title and the URL")
    func markdownLink() {
        let parsed = LinkedTitle(parsing: "[Wool scarf](https://www.shop.example/scarf?id=7)")
        #expect(parsed.title == "Wool scarf")
        #expect(parsed.url?.absoluteString == "https://www.shop.example/scarf?id=7")
        #expect(LinkedTitle.store(for: parsed.url) == "shop.example")
    }

    @Test("Text around a Markdown link is kept")
    func markdownLinkWithText() {
        let parsed = LinkedTitle(parsing: "Scarf in red [link](https://shop.example/s) size m")
        #expect(parsed.title == "Scarf in red link size m")
        #expect(LinkedTitle.store(for: parsed.url) == "shop.example")
    }

    @Test("A bare URL is moved out of the title, trailing punctuation trimmed")
    func bareURL() {
        let parsed = LinkedTitle(parsing: "Candle https://shop.example/candle.")
        #expect(parsed.title == "Candle")
        #expect(parsed.url?.absoluteString == "https://shop.example/candle")
    }

    @Test("A line that is only a link takes the store name as its title")
    func linkOnly() {
        let parsed = LinkedTitle(parsing: "https://www.shop.example/item/42")
        #expect(parsed.title == "shop.example")
    }

    @Test("Plain text has no link")
    func plainText() {
        let parsed = LinkedTitle(parsing: "Silver bracelet")
        #expect(parsed == LinkedTitle(parsing: "Silver bracelet"))
        #expect(parsed.title == "Silver bracelet")
        #expect(parsed.url == nil)
    }

    @Test("Non-web schemes stay as text", arguments: [
        "[Click](javascript:alert(1))",
        "[Mail](mailto:someone@example.com)",
        "file:///etc/hosts",
    ])
    func rejectsOtherSchemes(text: String) {
        #expect(LinkedTitle(parsing: text).url == nil)
    }

    @Test("Imported wishes carry the link and store")
    func importerUsesLinks() {
        let note = "Gifts\n- [ ] [Wool scarf](https://www.shop.example/scarf)\n- [ ] Gloves"
        let wishes = NoteImporter.parse(note).wishes
        #expect(wishes.map(\.title) == ["Wool scarf", "Gloves"])
        #expect(wishes.first?.store == "shop.example")
        #expect(wishes.last?.url == nil)
    }
}
