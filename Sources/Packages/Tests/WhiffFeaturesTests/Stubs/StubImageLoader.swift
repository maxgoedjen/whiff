import ComposableArchitecture
import SwiftUI
import WhiffFeatures

public final actor StubImageLoader: ImageLoaderProtocol, Sendable {

    let result: Result<ImageEquatable, Error>
    private var pendingLoad: [URL]

    init(_ image: ImageEquatable, loadOrder: [URL] = []) {
        self.result = .success(image)
        self.pendingLoad = loadOrder
    }

    init(_ error: Error, loadOrder: [URL] = []) {
        result = .failure(error)
        self.pendingLoad = loadOrder
    }

    public func loadImage(at url: URL) async throws -> ImageEquatable {
        if !pendingLoad.isEmpty {
            while pendingLoad.first != url {
                try await Task.sleep(for: .milliseconds(1))
            }
            pendingLoad.removeFirst()
        }
        return try result.get()
    }

}
