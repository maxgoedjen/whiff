import ComposableArchitecture
import SwiftUI

/// Protocol to abstract image loading.
public protocol ImageLoaderProtocol: Sendable {

    /// Loads an image from a specified URL.
    /// - Parameter url: The URL for the image to load.
    /// - Returns: An `ImageEquatable` struct.
    func loadImage(at url: URL) async throws -> ImageEquatable

}

/// Concrete implementation of `ImageLoaderProtocol` backed by a URLSession.
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
