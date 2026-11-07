/// How much the recipient wants a wish. Stored as its raw value (1–3).
public enum Desire: Int, CaseIterable, Codable, Sendable, Comparable {
    case niceToHave = 1
    case wouldLove = 2
    case dreamGift = 3

    public var label: String {
        switch self {
        case .niceToHave: "Nice to have"
        case .wouldLove: "Would love"
        case .dreamGift: "Dream gift"
        }
    }

    public static func < (lhs: Desire, rhs: Desire) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
