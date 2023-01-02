import ComposableArchitecture
import SwiftUI
import WhiffFeatures

public final class StubImageRenderer: ImageRendererProtocol, Sendable {

    let result: Result<UncheckedSendable<Image>, Error>

    init(_ image: Image) {
        self.result = .success(UncheckedSendable(image))
    }

    init(_ error: Error) {
        result = .failure(error)
    }

    public func render(state: ExportFeature.State) async throws -> Image {
        try result.get().value
    }

}
