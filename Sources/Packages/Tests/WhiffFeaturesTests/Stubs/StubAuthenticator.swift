import ComposableArchitecture
import os
import SwiftUI
import TootSniffer
import WhiffFeatures

public final class StubAuthenticator: AuthenticatorProtocol, @unchecked Sendable {

    public var existingToken: String? {
        lock.withLock { _ in
            token
        }
    }

    private var token: String?
    let obtainResult: Result<String, Error>
    private let lock = OSAllocatedUnfairLock()

    init(existingToken: String? = nil, obtainResult: Result<String, Error> = .success(UUID().uuidString)) {
        token = existingToken
        self.obtainResult = obtainResult
    }

    public func obtainOAuthToken(from host: String) async throws -> String {
        let value = try obtainResult.get()
        lock.withLock { _ in
            token = value
        }
        return value
    }

    public func logout() {
        lock.withLock { _ in
            token = nil
        }
    }

}
