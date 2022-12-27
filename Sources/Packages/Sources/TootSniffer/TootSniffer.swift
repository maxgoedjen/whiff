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
            formatter.formatOptions = [.withFractionalSeconds]
            guard let date = formatter.date(from: string) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to parse date")
            }
            return date
        }
        let raw = try decoder.decode(Toot.self, from: data)
        // I know,
        // dO Not Use reGex TO ParSE hTMl
        // but I'm not going to actually parse this HTML, so.
        let regex = #/<[^>]+>/#
        let strippedContent = raw.content.replacing(regex, with: "")
        var cleaned = raw
        cleaned.content = strippedContent
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

struct NotAMastadonPost: Error {
}

struct NoLinkParameter: Error {
}

struct UnableToParseAuthorName: Error {
}

struct UnableToParseAuthorImage: Error {
}

struct UnableToParseDate: Error {
}
