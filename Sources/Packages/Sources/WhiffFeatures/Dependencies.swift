import Dependencies
import Foundation
import TootSniffer
import UIKit
import ComposableArchitecture

private enum TootSnifferKey: DependencyKey {
    static let liveValue: any TootSnifferProtocol = TootSniffer()
    #if DEBUG
    static let testValue: any TootSnifferProtocol = UnimplementedTootSniffer()
    #endif
}

extension DependencyValues {
    public var tootSniffer: any TootSnifferProtocol {
        get { self[TootSnifferKey.self] }
        set { self[TootSnifferKey.self] = newValue }
    }
}

private enum ScreenScaleKey: DependencyKey {
    @MainActor static let liveValue: Double = UIScreen.main.scale
    #if DEBUG
    @MainActor static let testValue: Double = 3
    #endif
}

extension DependencyValues {
    public var screenScale: Double {
        get { self[ScreenScaleKey.self] }
        set { self[ScreenScaleKey.self] = newValue }
    }
}

private enum UserDefaultsKey: DependencyKey {
    static let liveValue: UncheckedSendable<UserDefaults> = UncheckedSendable(.standard)
    #if DEBUG
    static let testValue: UncheckedSendable<UserDefaults> = UncheckedSendable(.standard)
    #endif
}

extension DependencyValues {
    public var userDefaults: UserDefaults {
        get { self[UserDefaultsKey.self].value }
        set { self[UserDefaultsKey.self] = UncheckedSendable(newValue) }
    }
}

private enum DismissExtensionKey: DependencyKey {
    @MainActor static let liveValue: @MainActor @Sendable (Error?) -> Void = { _ in }
    #if DEBUG
    @MainActor static let testValue: @MainActor @Sendable (Error?) -> Void = { _ in }
    #endif
}

extension DependencyValues {
    public var dismissExtension: @MainActor @Sendable (Error?) -> Void {
        get { self[DismissExtensionKey.self] }
        set { self[DismissExtensionKey.self] = newValue }
    }
}
