import Foundation
import RegexBuilder
import SwiftUI

public protocol TootSnifferProtocol: Sendable {
    func sniff(url: URL) async throws -> Toot
}

public final class TootSniffer: TootSnifferProtocol {

    public init() {
    }

    public func sniff(url: URL) async throws -> Toot {
        let apiURL = try await constructMastodonAPIURL(url: url)
        return try await loadToot(url: apiURL)
    }

    func constructMastodonAPIURL(url: URL) async throws -> URL {
        var headRequest = URLRequest(url: url)
        headRequest.httpMethod = "HEAD"
        let (_, rawResponse) = try await URLSession.shared.data(for: headRequest)
        let response = rawResponse as! HTTPURLResponse
        guard response.allHeaderFields["Server"] as? String == "Mastodon" else { throw NotAMastadonPost() }
        guard var apiLink = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let id = apiLink.path.split(separator: "/").last
        else { throw NoLinkParameter() }
        apiLink.path = "/api/v1/statuses/\(id)"
        guard let final = apiLink.url else { throw NoLinkParameter() }
        return final
    }

    func loadToot(url: URL) async throws -> Toot {
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFractionalSeconds, .withFullDate, .withFullTime]
            guard let date = formatter.date(from: string) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to parse date")
            }
            return date
        }
        let raw = try decoder.decode(Toot.self, from: data)
        // Gotta be unicode, not utf8
        let attributed = try NSAttributedString(data: raw.content.data(using: .unicode)!, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
        var cleaned = raw
        cleaned.content = attributed.string
        // Uncomment to generate JSON for previews
//        print(String(data: try! JSONEncoder().encode(cleaned), encoding: .utf8)!)
        return cleaned
    }

}

public final class UnimplementedTootSniffer: TootSnifferProtocol {

    public init() {
    }

    public func sniff(url: URL) async throws -> Toot {
        fatalError("Unimplemented")
    }

}

struct NotAMastadonPost: LocalizedError {
    let errorDescription: String? = "This isn't a Mastodon Post."
}

struct NoLinkParameter: LocalizedError {
    let errorDescription: String? = "Unable to parse Toot."
}
