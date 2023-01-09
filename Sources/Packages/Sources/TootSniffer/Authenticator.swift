import Foundation
import AuthenticationServices

public protocol AuthenticatorProtocol: Sendable {

    var existingToken: String? { get }
    func obtainOAuthToken(from host: String) async throws -> String
    func logout()
}

extension AuthenticatorProtocol {

    public var loggedIn: Bool {
        existingToken != nil
    }

}

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

    private final class WebAuthenticationContextBridge: NSObject, ASWebAuthenticationPresentationContextProviding, Sendable {

        public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
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
