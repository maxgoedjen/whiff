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

extension DependencyValues {
    var tootSniffer: any TootSnifferProtocol {
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
    var screenScale: Double {
        get { self[ScreenScaleKey.self] }
        set { self[ScreenScaleKey.self] = newValue }
    }
}
