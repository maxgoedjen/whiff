import ComposableArchitecture
import SwiftUI

public protocol ImageLoaderProtocol: Sendable {

    func loadImage(at url: URL) async throws -> ImageEquatable

}

public final class ImageLoaderURLSession: ImageLoaderProtocol {

    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    public func loadImage(at url: URL) async throws -> ImageEquatable {
        let (data, _) = try await session.data(from: url)
        guard let image = UIImage(data: data) else { throw UnableToParseImageError() }
        return ImageEquatable(uiImage: image, equatableValue: url)
    }

}

public final class UnimplementedImageLoader: ImageLoaderProtocol {

    public func loadImage(at url: URL) async throws -> ImageEquatable {
        fatalError()
    }

}

struct UnableToParseImageError: Error, Equatable {
}
