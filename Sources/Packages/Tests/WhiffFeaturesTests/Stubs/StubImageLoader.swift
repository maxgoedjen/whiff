import ComposableArchitecture
import SwiftUI
import WhiffFeatures

public final actor StubImageLoader: ImageLoaderProtocol, Sendable {

    let result: Result<ImageEquatable, Error>
    private var responseDelay: TimeInterval
    private var currentDelay: TimeInterval = 0

    init(_ image: ImageEquatable, responseDelay: TimeInterval = 0.001) {
        self.result = .success(image)
        self.responseDelay = responseDelay
    }

    init(_ error: Error, responseDelay: TimeInterval = 0.001) {
        result = .failure(error)
        self.responseDelay = responseDelay
    }

    public func loadImage(at url: URL) async throws -> ImageEquatable {
        currentDelay += responseDelay
        try await Task.sleep(for: .seconds(responseDelay))
        return try result.get()
    }

}
