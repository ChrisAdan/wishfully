import Foundation
import Testing
import WishfullyCore

@Suite("Shared text")
struct SharedTextTests {
    struct Case: Sendable, CustomTestStringConvertible {
        let text: String
        let title: String?
        let url: String?

        var testDescription: String {
            text
        }
    }

    @Test("Splits shared text into a title and a product link", arguments: [
        Case(text: "Linen throw https://shop.example/p/7", title: "Linen throw", url: "https://shop.example/p/7"),
        Case(text: " https://www.shop.example/p/7 \n", title: nil, url: "https://www.shop.example/p/7"),
        Case(text: "Check this out!", title: "Check this out!", url: nil),
        Case(text: "", title: nil, url: nil),
    ])
    func splitsText(testCase: Case) {
        let shared = SharedText(testCase.text)
        #expect(shared.title == testCase.title)
        #expect(shared.url?.absoluteString == testCase.url)
    }
}
