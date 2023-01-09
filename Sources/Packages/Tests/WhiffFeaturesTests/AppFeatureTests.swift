import ComposableArchitecture
import SwiftUI
import XCTest
@testable import TootSniffer
@testable import WhiffFeatures

@MainActor
final class AppFeatureTests: XCTestCase {

    var store: TestStore<AppFeature.State, AppFeature.Action, AppFeature.State, AppFeature.Action, Void>!

    override func setUp() async throws {
        try await super.setUp()
        store = TestStore(
            initialState: AppFeature.State(),
            reducer: AppFeature()
                .dependency(\.keyValueStorage, StubStorage())
                .dependency(\.tootSniffer, StubTootSniffer(.success(.placeholder), .success(TootContext())))
                .dependency(\.imageRenderer, StubImageRenderer(.sampleRendered))
                .dependency(\.imageLoader, StubImageLoader(.sampleAvatar))
                .dependency(\.mainQueue, .main)
                .dependency(\.urlSession, .shared)
        )
    }

    func testLoadEmpty() async throws {
        await store.send(.load([]))
    }

    func testLoadMultiple() async throws {
        await store.send(.load([URL(string: "https://example.com")!, URL(string: "https://example.com")!])) {
            $0.showingExport = true
        }
    }

    func testLoadOne() async throws {
        await store.send(.load([URL(string: "https://example.com")!])) {
            $0.showingExport = true
        }
    }

    func testDismiss() async throws {
        store = TestStore(
            initialState: AppFeature.State(showingExport: true),
            reducer: AppFeature()
        )
        await store.send(.setShowingExport(false)) {
            $0.showingExport = false
            $0.exportState = ExportFeature.State()
        }
    }

}
