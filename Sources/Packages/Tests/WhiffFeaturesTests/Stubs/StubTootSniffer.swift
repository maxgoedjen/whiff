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
        case .success(let success):
            return success
        case .failure(let failure):
            throw failure
        }
    }


}
