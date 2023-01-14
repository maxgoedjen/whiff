import ComposableArchitecture
import SwiftUI
import WhiffFeatures

public final class StubImageRenderer: ImageRendererProtocol, Sendable {

    let result: Result<ImageEquatable, Error>

    init(_ image: ImageEquatable, equatableValue: some Equatable = "rendered") {
        result = .success(image)
    }

    init(_ error: Error) {
        result = .failure(error)
    }

    public func render(state: ExportFeature.State, colorScheme: ColorScheme?) async throws -> ImageEquatable {
        try result.get()
    }

}
