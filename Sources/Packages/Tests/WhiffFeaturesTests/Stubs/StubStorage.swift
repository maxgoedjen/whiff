import Foundation
import WhiffFeatures
import os

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
