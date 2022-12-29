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
        do {
            let raw = try decoder.decode(Toot.self, from: data)
            return try cleanToot(raw)
        } catch {
            throw NotAMastadonPost()
        }
    }

    func cleanToot(_ toot: Toot) throws -> Toot {
        var cleaned = toot
        // Mastodon API doesn't return a clean "@username@example.com" style username, so we'll look at the canonical
        // url for the
        if let canonicalServer = URLComponents(url: toot.url, resolvingAgainstBaseURL: true)?.host {
            cleaned.account.username = "@\(toot.account.username)@\(canonicalServer)"
        }
        // Uncomment to generate data for previews
//        print(try! JSONEncoder().encode(cleaned).base64EncodedString())
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
