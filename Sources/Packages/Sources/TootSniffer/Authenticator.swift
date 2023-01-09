import Foundation
import AuthenticationServices

/// Protocol for authenticating against a Mastodon server API.
public protocol AuthenticatorProtocol: Sendable {

    /// If the user has previously authenticated, returns the existing OAuth Bearer Token.
    var existingToken: String? { get }

    /// Obtains a fresh OAuth Bearer Token on behalf of the client.
    /// - Parameter host: The  host (eg, "example.com") of the user's Mastodon server.
    /// - Returns: An OAuth Bearer token, if one is successfully obtained.
    func obtainOAuthToken(from host: String) async throws -> String

    /// Clears any stored OAuth tokens.
    func logout()
}

extension AuthenticatorProtocol {

    /// Conveninence getter for login status.
    public var loggedIn: Bool {
        existingToken != nil
    }

}

/// Concrete implementation of AuthenticatorProtocol implemented using ASWebAuthenticationSession.
public final class AuthenticationServicesAuthenticator: AuthenticatorProtocol {

    private let contextBridge = WebAuthenticationContextBridge()

    public init() {
    }

    public var existingToken: String? {
        // This token has an extremely limited scope (only read:status) so it should be fine to just dump it in defaults.
        guard let token = UserDefaults.standard.string(forKey: Constants.tokenStorageKey) else { return nil }
        return token
    }

    private func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: Constants.tokenStorageKey)
    }

    public func obtainOAuthToken(from host: String) async throws -> String {
        let clientDetails = try await obtainOAuthClientDetails(from: host)
        let code = try await obtainOAuthCode(from: host, clientDetails: clientDetails)
        return try await obtainOAuthToken(code: code, host: host, clientDetails: clientDetails)
    }

    /// Creates a new OAuth app on the Mastodon server instance.
    /// - Parameter host: The host to create the app on.
    /// - Returns: An OAuthAppCreatePostResponse struct, containing client id + secret.
    func obtainOAuthClientDetails(from host: String) async throws -> OAuthAppCreatePostResponse {
        var urlComponents = URLComponents(string: "https://mastodon.social/api/v1/apps")!
        urlComponents.host = host
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(OAuthAppCreatePostBody())
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(OAuthAppCreatePostResponse.self, from: data)
    }

    /// Obtains an OAuth code to be redeemed for a Bearer Token.
    /// - Parameters:
    ///   - host: The  host (eg, "example.com") of the user's Mastodon server.
    ///   - clientDetails: An OAuthAppCreatePostResponse struct, containing client id + secret.
    /// - Returns: An OAuth code to be redeemed for a Bearer Token.
    func obtainOAuthCode(from host: String, clientDetails: OAuthAppCreatePostResponse) async throws -> String {
        // example.com host will be rewritten below
        var urlComponents = URLComponents(string: "https://example.com/oauth/authorize?response_type=code&client_id=\(clientDetails.clientId)&redirect_uri=\(Constants.redirectURI)&scope=\(Constants.scope)")!
        urlComponents.host = host
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: urlComponents.url!, callbackURLScheme: "whiff", completionHandler: { url, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    let responseComponents = URLComponents(url: url!, resolvingAgainstBaseURL: true)!
                    let code = responseComponents.queryItems?.filter { $0.name == "code" }.first?.value
                    continuation.resume(returning: code!)
                }
            })
            session.presentationContextProvider = contextBridge
            session.start()
        }
    }

    /// Exchanges an OAuth code for a Bearer Token.
    /// - Parameters:
    ///   - code: The OAuth code to be exchanged for a Bearer Token.
    ///   - host: The  host (eg, "example.com") of the user's Mastodon server.
    ///   - clientDetails: An OAuthAppCreatePostResponse struct, containing client id + secret.
    /// - Returns: An OAuth Bearer Token.
    func obtainOAuthToken(code: String, host: String, clientDetails: OAuthAppCreatePostResponse) async throws -> String {
        var urlComponents = URLComponents(string: "https://example.com/oauth/token")!
        urlComponents.host = host
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(OAuthTokenPostBody(code: code, clientId: clientDetails.clientId, clientSecret: clientDetails.clientSecret))
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(OAuthTokenPostResponse.self, from: data)
        saveToken(response.accessToken)
        return response.accessToken
    }

    public func logout() {
        UserDefaults.standard.removeObject(forKey: Constants.tokenStorageKey)
    }

}

extension AuthenticationServicesAuthenticator {

    enum Constants {
        static let redirectURI = "whiff://auth_redirect"
        static let scope = "read:statuses"
        static let tokenStorageKey = "AuthenticatorProtocol.tokenStorageKey"
    }

}

extension AuthenticationServicesAuthenticator {

    struct OAuthAppCreatePostBody: Encodable {
        let clientName = "Whiff"
        let redirectUris = Constants.redirectURI
        let scopes = Constants.scope
        let website = "https://github.com/maxgoedjen/whiff"
    }

    struct OAuthAppCreatePostResponse: Decodable {
        let clientId: String
        let clientSecret: String
    }

    struct OAuthTokenPostBody: Encodable {
        let code: String
        let grantType = "authorization_code"
        let clientId: String
        let clientSecret: String
        let redirectUri = Constants.redirectURI
    }

    struct OAuthTokenPostResponse: Decodable {
        let accessToken: String
        // Currently Mastodon API tokens just... don't expire?
//        let expiration: Date
    }

}

extension AuthenticationServicesAuthenticator {

    /// Trampoline to return a presentation anchor for the session.
    private final class WebAuthenticationContextBridge: NSObject, ASWebAuthenticationPresentationContextProviding, Sendable {

        public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
            // This API is not currently annotated well for MainActor access.
            DispatchQueue.main.sync {
                ASPresentationAnchor()
            }
        }

    }

}


public final class UnimplementedAuthenticator: AuthenticatorProtocol {

    public init() {
    }

    public var existingToken: String? {
        fatalError()
    }

    public func obtainOAuthToken(from host: String) async throws -> String {
        fatalError()
    }

    public func logout() {
        fatalError()
    }

}
