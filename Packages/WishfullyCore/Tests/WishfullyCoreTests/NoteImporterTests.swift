import Foundation
import Testing
@testable import WishfullyCore

/// The note below mirrors the structure of a real Apple Notes checklist (emoji
/// title, emoji headings, uneven spacing, an unheaded block, a separator) with
/// invented items.
@Suite("Note importer")
struct NoteImporterTests {
    static let note = """
    ⭐️ holiday wishes ⭐️

    Outdoors 🌲
    - [ ] Trail mug
    - [ ]  Wool beanie
    - [ ] Hiking  socks m
    - [x] Headlamp

    Reading 📚
    - [ ] Poetry anthology
    • Bookmark set


    - [ ] Reading lamp
    - [ ] Book stand

    ----
    """

    let result = NoteImporter.parse(Self.note, importedAt: Fixtures.start)

    @Test("The emoji title line becomes the list title")
    func title() {
        #expect(result.title == "⭐️ holiday wishes ⭐️")
    }

    @Test("Every item line becomes a wish, in note order, with whitespace tidied")
    func wishes() {
        #expect(result.wishes.map(\.title) == [
            "Trail mug", "Wool beanie", "Hiking socks m", "Headlamp",
            "Poetry anthology", "Bookmark set", "Reading lamp", "Book stand",
        ])
    }

    @Test("Headings become categories with emoji removed")
    func categories() {
        #expect(result.categories == ["Outdoors", "Reading"])
    }

    @Test("A heading stays in effect across blank lines")
    func unheadedBlockKeepsCategory() {
        let lamp = result.wishes.first { $0.title == "Reading lamp" }
        #expect(lamp?.category == "Reading")
    }

    @Test("Wishes keep note order under the shopping-list sort")
    func orderSurvivesSorting() {
        let list = ShoppingList(wishes: Array(result.wishes.reversed()), overlays: [])
        #expect(list.items.map(\.wish.title) == result.wishes.map(\.title))
    }

    @Test("Imported wishes start as plain, unpriced wishes")
    func defaults() {
        #expect(result.wishes.allSatisfy { $0.price == nil && $0.desire == .wouldLove && $0.note.isEmpty })
    }

    @Test("A note that starts with a heading and its items has no title")
    func noTitle() {
        let parsed = NoteImporter.parse("Kitchen\n- [ ] Whisk\n- [ ] Apron")
        #expect(parsed.title == nil)
        #expect(parsed.wishes.map(\.category) == ["Kitchen", "Kitchen"])
    }

    @Test("Items above any heading have no category")
    func uncategorized() {
        let parsed = NoteImporter.parse("- [ ] Mystery gift")
        #expect(parsed.wishes.first?.category == nil)
        #expect(parsed.title == nil)
    }

    @Test("Line endings, trailing spaces, empty markers and separators are handled", arguments: [
        "Gifts\r\n- [ ] Scarf\r\n- [ ]\r\n***\r\n- [ ] Gloves\r\n",
        "Gifts\n- [ ] Scarf\n-\n___\n- [ ] Gloves\n",
        "Gifts \n- [ ]  Scarf  \n- [ ]   Gloves \t\n",
    ])
    func messyInput(text: String) {
        let parsed = NoteImporter.parse(text)
        #expect(parsed.wishes.map(\.title) == ["Scarf", "Gloves"])
    }

    @Test("A heading made only of emoji keeps its text as the category")
    func emojiOnlyHeading() {
        let parsed = NoteImporter.parse("Intro\n🎁\n- [ ] Surprise")
        #expect(parsed.wishes.first?.category == "🎁")
    }

    @Test("An empty note imports nothing")
    func emptyNote() {
        #expect(NoteImporter.parse("") == NoteImport(title: nil, wishes: []))
    }
}
