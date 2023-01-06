import ComposableArchitecture
import SwiftUI

/// Wrapper type to allow better Image Equality testing for tests.
public struct ImageEquatable: View, Sendable, Equatable {

    /// The underlying image.
    public let image: UncheckedSendable<Image>
    /// The value to check during equality comparisons.
    /// > Note: Ideally this would be `any Equatable`, but existentials can't conform to their own protocols and AnyHashable erases Equatable anyway, so 🤷
    public let equatableValue: UncheckedSendable<AnyHashable>

    /// Conveninence initializer for UIImages and non-Hashable equatables.
    /// - Parameters:
    ///   - uiImage: The image to wrap.
    ///   - equatableValue: The equatable value to use.
    public init(uiImage: UIImage, equatableValue: some Equatable) {
        self.init(image: Image(uiImage: uiImage), equatableValue: HashableBox(value: equatableValue))
    }

    /// Conveninence initializer for non-Hashable equatables.
    /// - Parameters:
    ///   - uiImage: The image to wrap.
    ///   - equatableValue: The equatable value to use.
    public init(image: Image, equatableValue: some Equatable) {
        self.init(image: image, equatableValue: HashableBox(value: equatableValue))
    }

    /// Conveninence initializer for UIImages.
    /// - Parameters:
    ///   - uiImage: The image to wrap.
    ///   - equatableValue: The equatable value to use.
    public init(uiImage: UIImage, equatableValue: some Hashable) {
        self.init(image: Image(uiImage: uiImage), equatableValue: equatableValue)
    }

    /// Initializer.
    /// - Parameters:
    ///   - uiImage: The image to wrap.
    ///   - equatableValue: The equatable value to use.
    public init(image: Image, equatableValue: some Hashable) {
        self.image = UncheckedSendable(image)
        self.equatableValue = UncheckedSendable(equatableValue as AnyHashable)
    }

    public var body: Image {
        image.value
    }

    public static func == (lhs: ImageEquatable, rhs: ImageEquatable) -> Bool {
        lhs.equatableValue.value == rhs.equatableValue.value
    }

    /// Box type to alow easy casting to AnyHashable eraser.
    struct HashableBox<T: Equatable>: Hashable {

        let value: T

        func hash(into hasher: inout Hasher) {
            fatalError("This is purely for protocol conformance and shouldn't actually be called.")
        }

    }

}
