import Foundation
import ImageIO
import UniformTypeIdentifiers
import WishfullyCore

/// A product page read for its details, with a downsized photo.
struct FetchedPage: Sendable {
    var metadata: PageMetadata
    var photo: Data?
}

/// Downloads a product page as plain data (AGENTS.md, section 2: HTTPS, capped size, timeouts,
/// text values only). Page scripts stay inert: the HTML is scanned as text.
enum PageFetcher {
    /// Largest page or photo download, in bytes.
    static let maxDownloadBytes: Int64 = 8_000_000
    /// Longest edge of the stored photo, in pixels: sharp on a phone's detail screen.
    static let photoMaxPixels = 900
    static let photoQuality = 0.8

    /// Stores serve their full product page to a phone browser; a bare client gets less.
    private static let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 "
        + "(KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1"

    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 20
        configuration.httpCookieAcceptPolicy = .never
        return URLSession(configuration: configuration)
    }()

    /// Reads the page at `url`. Missing pieces stay nil; the person fills them in.
    static func fetch(_ url: URL) async -> FetchedPage {
        guard let secure = secureURL(url), let html = await download(secure) else {
            return FetchedPage(metadata: PageMetadata.extract(fromHTML: "", pageURL: url), photo: nil)
        }
        let metadata = PageMetadata.extract(fromHTML: Self.text(from: html), pageURL: secure)
        var photo: Data?
        if let imageURL = metadata.imageURL, let original = await download(imageURL) {
            photo = downsized(original)
        }
        Log.extraction.info(
            "Page read: title \(metadata.title != nil), photo \(photo != nil), price \(metadata.price != nil)"
        )
        return FetchedPage(metadata: metadata, photo: photo)
    }

    /// Shrinks a photo to `photoMaxPixels` on its longest edge and re-encodes it as JPEG.
    static func downsized(_ data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: photoMaxPixels,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output as CFMutableData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else { return nil }
        let properties: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: photoQuality]
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        return CGImageDestinationFinalize(destination) ? output as Data : nil
    }

    /// Pages are UTF-8 almost everywhere; older ones are Latin-1, which decodes any bytes.
    private static func text(from data: Data) -> String {
        String(bytes: data, encoding: .utf8) ?? String(bytes: data, encoding: .isoLatin1) ?? ""
    }

    private static func secureURL(_ url: URL) -> URL? {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let scheme = components.scheme?.lowercased(), scheme == "https" || scheme == "http"
        else { return nil }
        components.scheme = "https"
        return components.url
    }

    private static func download(_ url: URL) async -> Data? {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode),
                  Int64(data.count) <= maxDownloadBytes
            else { return nil }
            return data
        } catch {
            Log.extraction.error("Download failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}
