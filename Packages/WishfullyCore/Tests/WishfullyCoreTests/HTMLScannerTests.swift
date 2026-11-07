import Testing
@testable import WishfullyCore

@Suite("HTML scanner")
struct HTMLScannerTests {
    @Test("Reads tag names and attributes in any quoting style and order")
    func attributes() {
        let tags = HTMLScanner.tags(in: #"<META content='68.00' PROPERTY="og:price:amount" data-x=bare checked>"#)
        #expect(tags.count == 1)
        #expect(tags.first?.name == "meta")
        #expect(tags.first?[attribute: "property"] == "og:price:amount")
        #expect(tags.first?[attribute: "content"] == "68.00")
        #expect(tags.first?[attribute: "data-x"] == "bare")
        #expect(tags.first?[attribute: "checked"] == "")
    }

    @Test("Captures script contents without treating them as tags")
    func scriptContent() {
        let html = #"<script type="application/ld+json">{"a": "<b>not a tag</b>"}</script><p>"#
        let tags = HTMLScanner.tags(in: html)
        #expect(tags.map(\.name) == ["script", "p"])
        #expect(tags.first?.content == #"{"a": "<b>not a tag</b>"}"#)
    }

    @Test("Skips comments and doctype")
    func skipsComments() {
        let html = #"<!DOCTYPE html><!-- <meta name="x" content="hidden"> --><meta name="y" content="shown">"#
        let tags = HTMLScanner.tags(in: html)
        #expect(tags.map { $0[attribute: "name"] } == ["y"])
    }

    @Test("Decodes the common entities in attribute values")
    func decodesEntities() {
        let tags = HTMLScanner.tags(in: #"<meta content="Tom &amp; Jerry &quot;Deluxe&quot;">"#)
        #expect(tags.first?[attribute: "content"] == #"Tom & Jerry "Deluxe""#)
    }

    @Test("Malformed input terminates instead of hanging or crashing", arguments: [
        "<", "<<<<", "<meta content=\"never closed", "<script>unterminated", "<script", "<script type='x",
        "<!-- open comment",
        "<a =\"x\" =>", "</>", "<1notatag>", String(repeating: "<div ", count: 5000),
    ])
    func malformedInputTerminates(html: String) {
        _ = HTMLScanner.tags(in: html)
    }

    @Test("Stops at the tag limit")
    func respectsLimit() {
        let html = String(repeating: "<p>", count: 100)
        #expect(HTMLScanner.tags(in: html, limit: 10).count == 10)
    }
}
