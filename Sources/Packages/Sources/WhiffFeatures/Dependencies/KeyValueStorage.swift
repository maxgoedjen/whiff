import ComposableArchitecture
import Foundation
import os

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

public final class StubStorage: KeyValueStorage, @unchecked Sendable {

    public var storage: [String: Data]
    private let lock = OSAllocatedUnfairLock()

    public init(storage: [String: Data] = [:]) {
        self.storage = storage
    }

    public subscript(_ key: String) -> Data? {
        get {
            lock.withLock { _ in
                storage[key]
            }
        }
        set {
            lock.withLock { _ in
                storage[key] = newValue
            }
        }
    }

}
