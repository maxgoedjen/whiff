import Foundation
import TootSniffer

public final actor StubTootSniffer: TootSnifferProtocol {

    let result: Result<Toot, Error>
    var callCount = 0

    init(_ result: Result<Toot, Error>) {
        self.result = result
    }

    public func sniff(url: URL) async throws -> Toot {
        callCount += 1
        switch result {
        case let .success(success):
            return success
        case let .failure(failure):
            throw failure
        }
    }

}
