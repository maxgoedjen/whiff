import ComposableArchitecture
import Foundation

public protocol KeyValueStorage: AnyObject, Sendable {

    subscript(_ key: String) -> Data? { get set }

}

public final class UserDefaultsStorage: KeyValueStorage {

    let defaults: UncheckedSendable<UserDefaults>

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
