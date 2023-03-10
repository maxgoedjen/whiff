import ComposableArchitecture
import Dependencies
import Foundation
import TootSniffer
import UIKit

private enum TootSnifferKey: DependencyKey {
    static let liveValue: any TootSnifferProtocol = TootSniffer()
    #if DEBUG
    static let testValue: any TootSnifferProtocol = UnimplementedTootSniffer()
    #endif
}

public extension DependencyValues {
    var tootSniffer: any TootSnifferProtocol {
        get { self[TootSnifferKey.self] }
        set { self[TootSnifferKey.self] = newValue }
    }
}

private enum KeyValueStorageKey: DependencyKey {
    static let liveValue: KeyValueStorage = UserDefaultsStorage(defaults: UserDefaults(suiteName: "group.maxgoedjen.whiff")!)
    #if DEBUG
    static let testValue: KeyValueStorage = UnimplementedKeyValueStorage()
    #endif
}

public extension DependencyValues {
    var keyValueStorage: KeyValueStorage {
        get { self[KeyValueStorageKey.self] }
        set { self[KeyValueStorageKey.self] = newValue }
    }
}

private enum ImageRendererKey: DependencyKey {
    static let liveValue: ImageRendererProtocol = ImageRendererSwiftUI()
    #if DEBUG
    static let testValue: ImageRendererProtocol = UnimplementedImageRenderer()
    #endif
}

public extension DependencyValues {
    var imageRenderer: ImageRendererProtocol {
        get { self[ImageRendererKey.self] }
        set { self[ImageRendererKey.self] = newValue }
    }
}

private enum ImageLoaderKey: DependencyKey {
    static let liveValue: ImageLoaderProtocol = ImageLoaderURLSession()
    #if DEBUG
    static let testValue: ImageLoaderProtocol = UnimplementedImageLoader()
    #endif
}

public extension DependencyValues {
    var imageLoader: ImageLoaderProtocol {
        get { self[ImageLoaderKey.self] }
        set { self[ImageLoaderKey.self] = newValue }
    }
}

private enum AuthenticatorKey: DependencyKey {
    static let liveValue: AuthenticatorProtocol = AuthenticationServicesAuthenticator()
    #if DEBUG
    static let testValue: AuthenticatorProtocol = UnimplementedAuthenticator()
    #endif
}

public extension DependencyValues {
    var authenticator: AuthenticatorProtocol {
        get { self[AuthenticatorKey.self] }
        set { self[AuthenticatorKey.self] = newValue }
    }
}

private enum DismissExtensionKey: DependencyKey {
    @MainActor static let liveValue: @MainActor @Sendable (Error?) -> Void = { _ in }
    #if DEBUG
    @MainActor static let testValue: @MainActor @Sendable (Error?) -> Void = { _ in }
    #endif
}

public extension DependencyValues {
    var dismissExtension: @MainActor @Sendable (Error?) -> Void {
        get { self[DismissExtensionKey.self] }
        set { self[DismissExtensionKey.self] = newValue }
    }
}
