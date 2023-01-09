import Foundation
@testable import TootSniffer

public final actor StubTootSniffer: TootSnifferProtocol {

    let result: Result<Toot, Error>
    let contextResult: Result<TootContext, Error>
    let requiresAuthentiation: Bool
    var resultCallCount = 0
    var contextResultCallCount = 0

    init(_ result: Result<Toot, Error>, _ contextResult: Result<TootContext, Error>, requiresAuthentiation: Bool = false) {
        self.result = result
        self.contextResult = contextResult
        self.requiresAuthentiation = requiresAuthentiation
    }

    public func sniff(url: URL, authToken: String?) async throws -> Toot {
        resultCallCount += 1
        if requiresAuthentiation && authToken == nil {
            throw NotAuthenticatedError()
        }
        switch result {
        case let .success(success):
            return success
        case let .failure(failure):
            throw failure
        }
    }

    public func sniffContext(url: URL, authToken: String?) async throws -> TootContext {
        contextResultCallCount += 1
        if requiresAuthentiation && authToken == nil {
            throw NotAuthenticatedError()
        }
        switch contextResult {
        case let .success(success):
            return success
        case let .failure(failure):
            throw failure
        }
    }

}
