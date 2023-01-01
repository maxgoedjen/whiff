import Foundation
import RegexBuilder
import SwiftUI

public protocol TootSnifferProtocol: Sendable {
    func sniff(url: URL) async throws -> Toot
    func sniffContext(url: URL) async throws -> TootContext
}

public final class TootSniffer: TootSnifferProtocol {

    private enum Endpoint: String {
        case status = ""
        case context = "/context"
    }

    public init() {
    }

    public func sniff(url: URL) async throws -> Toot {
        let apiURL = try await constructMastodonAPIURL(url: url, endpoint: .status)
        return try await loadToot(url: apiURL)
    }

    public func sniffContext(url: URL) async throws -> TootContext {
        let apiURL = try await constructMastodonAPIURL(url: url, endpoint: .context)
        return try await loadTootContext(url: apiURL)
    }

    private func constructMastodonAPIURL(url: URL, endpoint: Endpoint) async throws -> URL {
        guard var apiLink = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let id = apiLink.path.split(separator: "/").last
        else { throw NoLinkParameterError() }
        apiLink.path = "/api/v1/statuses/\(id)" + endpoint.rawValue
        guard let final = apiLink.url else { throw NoLinkParameterError() }
        return final
    }

    private func loadToot(url: URL) async throws -> Toot {
        let (data, response) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom(dateDecoder)
        do {
            let raw = try decoder.decode(Toot.self, from: data)
            return try cleanToot(raw)
        } catch {
            if let http = response as? HTTPURLResponse, http.statusCode == 401 {
                throw NotAuthenticatedError()
            }
            throw NotAMastadonPostError()
        }
    }

    private func loadTootContext(url: URL) async throws -> TootContext {
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom(dateDecoder)
        do {
            var raw = try decoder.decode(TootContext.self, from: data)
            let cleanedAncestors = try raw.ancestors.map(cleanToot(_:))
            let cleanedDescendants = try raw.descendants.map(cleanToot(_:))
            raw.ancestors = cleanedAncestors
            raw.descendants = cleanedDescendants
            return raw
        } catch {
            throw NotAMastadonPostError()
        }
    }

    @Sendable @inlinable func dateDecoder(_ decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFractionalSeconds, .withFullDate, .withFullTime]
        guard let date = formatter.date(from: string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to parse date")
        }
        return date
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

    public func sniffContext(url: URL) async throws -> TootContext {
        fatalError("Unimplemented")
    }

}

struct NotAMastadonPostError: LocalizedError {
    let errorDescription: String? = "This isn't a Mastodon Post."
}

struct NoLinkParameterError: LocalizedError {
    let errorDescription: String? = "Unable to parse Toot."
}

struct NotAuthenticatedError: LocalizedError {
    let errorDescription: String? = "This Toot requires authentication to view."
}
