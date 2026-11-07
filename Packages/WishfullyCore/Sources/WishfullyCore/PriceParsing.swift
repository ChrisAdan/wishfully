import Foundation

/// Turns price text found on web pages ("$1,299.99", "68,00", "68") into exact amounts.
enum PriceParsing {
    /// Anything outside this range is treated as junk, not a gift price.
    static let plausibleRange: ClosedRange<Decimal> = 0.01 ... 1_000_000

    private static let posix = Locale(identifier: "en_US_POSIX")

    static func amount(from raw: String) -> Decimal? {
        // A minus sign means a negative number or a range ("10-20"): neither is a price.
        guard !raw.contains("-") else { return nil }
        let digitsAndSeparators = String(raw.filter { $0.isASCII && ($0.isNumber || $0 == "." || $0 == ",") })
        guard digitsAndSeparators.contains(where: \.isNumber),
              let value = Decimal(string: normalize(digitsAndSeparators), locale: posix),
              plausibleRange.contains(value)
        else { return nil }
        return value
    }

    /// A three-letter ISO 4217 code, upper-cased; nil if the text isn't one.
    static func currencyCode(from raw: String?) -> String? {
        guard let code = raw?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
              code.count == 3,
              code.allSatisfy({ $0.isASCII && $0.isLetter })
        else { return nil }
        return code
    }

    /// Rewrites a number to use "." as the only decimal separator.
    ///
    /// When both separators appear, whichever comes last is the decimal point
    /// ("1.299,99" and "1,299.99"). A lone comma followed by exactly two digits
    /// is a decimal comma ("68,00"); otherwise commas group thousands.
    private static func normalize(_ number: String) -> String {
        let lastDot = number.lastIndex(of: ".")
        let lastComma = number.lastIndex(of: ",")
        switch (lastDot, lastComma) {
        case let (dot?, comma?):
            return dot > comma ? removing(",", from: number) : decimalComma(removing(".", from: number))
        case let (nil, comma?):
            let digitsAfterComma = number.distance(from: comma, to: number.endIndex) - 1
            let isDecimalComma = number.count(of: ",") == 1 && digitsAfterComma == 2
            return isDecimalComma ? decimalComma(number) : removing(",", from: number)
        case (.some, nil):
            return number.count(of: ".") > 1 ? removing(".", from: number) : number
        case (nil, nil):
            return number
        }
    }

    private static func removing(_ separator: String, from number: String) -> String {
        number.replacingOccurrences(of: separator, with: "")
    }

    private static func decimalComma(_ number: String) -> String {
        number.replacingOccurrences(of: ",", with: ".")
    }
}

private extension String {
    func count(of character: Character) -> Int {
        reduce(0) { $1 == character ? $0 + 1 : $0 }
    }
}
