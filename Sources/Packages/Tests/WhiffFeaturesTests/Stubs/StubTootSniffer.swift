import Foundation
import TootSniffer

public final actor StubTootSniffer: TootSnifferProtocol {

    let result: Result<Toot, Error>
    let contextResult: Result<TootContext, Error>
    var resultCallCount = 0
    var contextResultCallCount = 0

    init(_ result: Result<Toot, Error>, _ contextResult: Result<TootContext, Error>) {
        self.result = result
        self.contextResult = contextResult
    }

    public func sniff(url: URL, authToken: String?) async throws -> Toot {
        resultCallCount += 1
        switch result {
        case let .success(success):
            return success
        case let .failure(failure):
            throw failure
        }
    }

    public func sniffContext(url: URL, authToken: String?) async throws -> TootContext {
        contextResultCallCount += 1
        switch contextResult {
        case let .success(success):
            return success
        case let .failure(failure):
            throw failure
        }
    }

}
