import ComposableArchitecture
import Foundation

/// Protocol to abstract key-value storage of Data blobs.
public protocol KeyValueStorage: AnyObject, Sendable {

    /// Gets/sets a data blob for a given key.
    /// - Parameter key: The key to store data for.
    subscript(_ key: String) -> Data? { get set }

}

/// Concrete implementation of KeyValueStorage backed by UserDefaults.
public final class UserDefaultsStorage: KeyValueStorage {

    let defaults: UncheckedSendable<UserDefaults>

    /// Initializes a storage object with a UserDefaults backing store.
    /// - Parameter defaults: The UserDefaults instance to use.
    init(defaults: UserDefaults) {
        self.defaults = UncheckedSendable(defaults)
    }

    public subscript(_ key: String) -> Data? {
        get {
            defaults.value.data(forKey: key)
        }
        set {
            defaults.value.set(newValue, forKey: key)
        }
    }

}

public final class UnimplementedKeyValueStorage: KeyValueStorage {

    public subscript(_ key: String) -> Data? {
        get {
            fatalError()
        }
        set {
            fatalError()
        }
    }

}
