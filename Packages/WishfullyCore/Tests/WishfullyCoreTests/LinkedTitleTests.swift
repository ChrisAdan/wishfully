import Foundation
import Testing
@testable import WishfullyCore

@Suite("Linked titles")
struct LinkedTitleTests {
    struct Case: Sendable, CustomTestStringConvertible {
        let line: String
        let title: String
        let url: String?
        let store: String?

        var testDescription: String {
            line
        }
    }

    @Test("Parses the title, link and store from a line", arguments: [
        Case(
            line: "[Wool scarf](https://www.shop.example/scarf?id=7)",
            title: "Wool scarf",
            url: "https://www.shop.example/scarf?id=7",
            store: "shop.example"
        ),
        Case(
            line: "Scarf in red [link](https://shop.example/s) size m",
            title: "Scarf in red link size m",
            url: "https://shop.example/s",
            store: "shop.example"
        ),
        Case(
            line: "Candle https://shop.example/candle.",
            title: "Candle",
            url: "https://shop.example/candle",
            store: "shop.example"
        ),
        Case(
            line: "https://www.shop.example/item/42",
            title: "shop.example",
            url: "https://www.shop.example/item/42",
            store: "shop.example"
        ),
        Case(line: "Silver bracelet", title: "Silver bracelet", url: nil, store: nil),
        Case(line: "[Click](javascript:alert(1))", title: "[Click](javascript:alert(1))", url: nil, store: nil),
        Case(
            line: "[Mail](mailto:someone@example.com)",
            title: "[Mail](mailto:someone@example.com)",
            url: nil,
            store: nil
        ),
        Case(line: "file:///etc/hosts", title: "file:///etc/hosts", url: nil, store: nil),
    ])
    func parsesLine(_ testCase: Case) {
        let parsed = LinkedTitle(parsing: testCase.line)
        #expect(parsed.title == testCase.title)
        #expect(parsed.url?.absoluteString == testCase.url)
        #expect(LinkedTitle.store(for: parsed.url) == testCase.store)
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
