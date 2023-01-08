import Foundation
import RegexBuilder
import SwiftUI

/// Protocol for retreiving post and context objects from a Mastodon server instance's API.
public protocol TootSnifferProtocol: Sendable {
    /// Retrieves a `Toot` model object from a Mastodon server's API.
    /// - Parameter url: The URL of the post to fetch.
    /// - Parameter authToken: An optional OAuth token to use to authenticate the request. Optional, but some posts may be invisible without it.
    /// - Returns: A `Toot` model object, if the URL is a valid and accessible post.
    func sniff(url: URL, authToken: String?) async throws -> Toot
    /// Retrieves a `TootContext` model object from a Mastodon server's API.
    /// - Parameter url: The URL of the post to fetch the context of.
    /// - Parameter authToken: An optional OAuth token to use to authenticate the request. Optional, but some posts may be invisible without it.
    /// - Returns: A `TootContext` model object, if the URL is a valid and accessible post.
    func sniffContext(url: URL, authToken: String?) async throws -> TootContext
}

/// Concrete implementation of `TootSnifferProtocol`.
public final class TootSniffer: TootSnifferProtocol {

    private enum Endpoint: String {
        case status = ""
        case context = "/context"
    }

    public init() {
    }

    public func sniff(url: URL, authToken: String?) async throws -> Toot {
        let request = try await constructMastodonAPIURL(url: url, endpoint: .status, authToken: authToken)
        return try await loadToot(request: request)
    }

    public func sniffContext(url: URL, authToken: String?) async throws -> TootContext {
        let request = try await constructMastodonAPIURL(url: url, endpoint: .context, authToken: authToken)
        return try await loadTootContext(request: request)
    }

    /// Constructs a Mastodon API URL for a given post URL and endpoint.
    /// - Parameters:
    ///   - url: The URL of the post to fetch.
    /// - Parameter authToken: An optional OAuth token to use to authenticate the request. Optional, but some posts may be invisible without it.
    ///   - endpoint: The endpoint to fetch (either the post itself, or the context of the post).
    /// - Returns: The URL for the API specified.
    private func constructMastodonAPIURL(url: URL, endpoint: Endpoint, authToken: String?) async throws -> URLRequest {
        guard var apiLink = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let id = apiLink.path.split(separator: "/").last
        else { throw NoLinkParameterError() }
        apiLink.path = "/api/v1/statuses/\(id)" + endpoint.rawValue
        guard let final = apiLink.url else { throw NoLinkParameterError() }
        var request = URLRequest(url: final)
        if let authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    /// Loads and deserializes the `Toot` model.
    /// - Parameter url: The API endpoint URL for the post.
    /// - Parameter authToken: An optional OAuth token to use to authenticate the request. Optional, but some posts may be invisible without it.
    /// - Returns: A `Toot` model object, if the URL is a valid and accessible post.
    private func loadToot(request: URLRequest) async throws -> Toot {
        let (data, response) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom(dateDecoder)
        do {
            let raw = try decoder.decode(Toot.self, from: data)
            return try cleanToot(raw)
        } catch {
            if let http = response as? HTTPURLResponse, http.statusCode == 401 || http.statusCode == 404, request.allHTTPHeaderFields?["Authorization"] == nil {
                throw NotAuthenticatedError()
            }
            throw NotAMastadonPostError()
        }
    }

    /// Loads and deserializes the `TootContext` model.
    /// - Parameter url: The API endpoint URL for the post context.
    /// - Returns: A `TootContext` model object, if the URL is a valid and accessible post.
    private func loadTootContext(request: URLRequest) async throws -> TootContext {
        let (data, _) = try await URLSession.shared.data(for: request)
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

    /// Decodes the date in the post, because JSONDecoder's ISO 8601 parser is finnicky.
    /// - Parameter decoder: The decoder to use.
    /// - Returns: A date, if one is able to be parsed from the decoder.
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

    /// Cleans up some of the fields of the `Toot` model.
    /// - Parameter toot: The `Toot` to clean up.
    /// - Returns: A `Toot` with certain fields (described in function) normalized.
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

    public func sniff(url: URL, authToken: String?) async throws -> Toot {
        fatalError("Unimplemented")
    }

    public func sniffContext(url: URL, authToken: String?) async throws -> TootContext {
        fatalError("Unimplemented")
    }

}

public struct NotAMastadonPostError: LocalizedError, Equatable {
    public let errorDescription: String? = "This isn't a Mastodon Post."
}

public struct NoLinkParameterError: LocalizedError, Equatable {
    public let errorDescription: String? = "Unable to parse Toot."
}

public struct NotAuthenticatedError: LocalizedError, Equatable {
    public let errorDescription: String? = "This Toot couldn't be loaded. It may not be publicly visible, you can log in to try again."
}
