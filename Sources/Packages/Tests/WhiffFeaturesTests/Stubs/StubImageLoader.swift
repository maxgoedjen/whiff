import ComposableArchitecture
import SwiftUI
import WhiffFeatures

public final class StubImageLoader: ImageLoaderProtocol, Sendable {

    let result: Result<UncheckedSendable<Image>, Error>

    init(_ image: Image) {
        self.result = .success(UncheckedSendable(image))
    }

    init(_ error: Error) {
        result = .failure(error)
    }

    public func loadImage(at url: URL) async throws -> Image {
        try result.get().value
    }

}
