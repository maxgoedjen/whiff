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

// Image equality is pretty... rough, especially when testing.
// This just allows an equatable key
public struct ImageEquatable: View, Sendable, Equatable {

    public let image: UncheckedSendable<Image>
    // Ideally this would be `any Equatable`, but existentials can't conform to their own protocols
    // and AnyHashable erases Equatable anyway, so 🤷
    public let equatableValue: UncheckedSendable<AnyHashable>

    public init(uiImage: UIImage, equatableValue: some Equatable) {
        self.init(image: Image(uiImage: uiImage), equatableValue: HashableBox(value: equatableValue))
    }

    public init(image: Image, equatableValue: some Equatable) {
        self.init(image: image, equatableValue: HashableBox(value: equatableValue))
    }

    public init(uiImage: UIImage, equatableValue: some Hashable) {
        self.init(image: Image(uiImage: uiImage), equatableValue: equatableValue)
    }

    public init(image: Image, equatableValue: some Hashable) {
        self.image = UncheckedSendable(image)
        self.equatableValue = UncheckedSendable(equatableValue as AnyHashable)
    }

    public var body: Image {
        image.value
    }

    public static func ==(lhs: ImageEquatable, rhs: ImageEquatable) -> Bool {
        lhs.equatableValue.value == rhs.equatableValue.value
    }

    struct HashableBox<T: Equatable>: Hashable {

        let value: T

        func hash(into hasher: inout Hasher) {
            fatalError("This is purely for protocol conformance and shouldn't actually be called.")
        }

    }

}

