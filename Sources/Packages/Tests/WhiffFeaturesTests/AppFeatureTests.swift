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
                .dependency(\.authenticator, StubAuthenticator())
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

    func testAuthFromToolbar() async throws {
        await store.send(.setShowingAuthentication(.topLevel)) {
            $0.showingAuthentication = .topLevel
        }
    }

    func testAuthFromFailure() async throws {
        let authenticator = StubAuthenticator(obtainResult: .failure(NotAuthenticatedError()))
        store = TestStore(
            initialState: AppFeature.State(showingExport: false),
            reducer: AppFeature()
                .dependency(\.tootSniffer, StubTootSniffer(.failure(NotAuthenticatedError()), .failure(NotAuthenticatedError())))
                .dependency(\.authenticator, authenticator)
                .dependency(\.keyValueStorage, StubStorage())
        )
        await store.send(.load([URL(string: "https://example.com")!])) {
            $0.showingExport = true
        }
        await store.receive(.export(.requested(url: URL(string: "https://example.com")!))) {
            $0.exportState.lastURL = URL(string: "https://example.com")!
        }
        await store.receive(.export(.settings(.load)))
        await store.receive(.export(.tootSniffCompleted(.failure(NotAuthenticatedError())))) {
            $0.exportState.errorState = ExportFeature.State.ErrorState(message: NotAuthenticatedError().errorDescription!)
            $0.exportState.errorState?.button = "Log In"
        }
        await store.receive(.export(.tootSniffContextCompleted(.failure(NotAuthenticatedError()))))
        await store.send(.export(.tappedLogin)) {
            $0.showingAuthentication = .onExport
        }
    }

}
