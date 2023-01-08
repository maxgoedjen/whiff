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
        let code = try await obtainOAuthCode(from: host)
        return try await obtainOAuthToken(code: code, host: host)
    }

    func obtainOAuthCode(from host: String) async throws -> String {
        // example.com host will be rewritten below
        var urlComponents = URLComponents(string: "https://example.com/oauth/authorize?response_type=code&client_id=\(Constants.clientID)&redirect_uri=\(Constants.redirectURI)&scope=read:statuses")!
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

    func obtainOAuthToken(code: String, host: String) async throws -> String {
        var urlComponents = URLComponents(string: "https://example.com/oauth/token")!
        urlComponents.host = host
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(OAuthTokenPostBody(code: code))
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
        static let clientID = "cwlwRcvt6c2uS4qDnEddHJQPqyTs29t3qWct6-xMKCI"
        // This isn't _REALLY_ a secret, but we'll do some light obfuscation just in case any bots are trawling
        static let clientThing = String(data: Data(base64Encoded: "bS1KNTRoMHA1M0JCRnBoVFMAXRSNTVZYk5IUGxtdlBydUlTTkFrZEJLcFlXOA=="
            .replacing("MAX", with: ""))!, encoding: .utf8)
        static let redirectURI = "whiff://auth_redirect"
        static let tokenStorageKey = "AuthenticatorProtocol.tokenStorageKey"
    }

}

extension AuthenticationServicesAuthenticator {

    struct OAuthTokenPostBody: Encodable {
        let code: String
        let grant_type = "authorization_code"
        let client_id = Constants.clientID
        let client_secret = Constants.clientThing
        let redirect_uri = Constants.redirectURI
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
