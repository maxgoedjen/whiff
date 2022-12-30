import ComposableArchitecture
import XCTest
import SwiftUI
@testable import WhiffFeatures

@MainActor
final class ExtensionFeatureTests: XCTestCase {

    var store: TestStore<ExtensionFeature.State, ExtensionFeature.Action, ExtensionFeature.State, ExtensionFeature.Action, Void>!
    var dismissCalled = false
    var dismissError: Error?

    override func setUp() async throws {
        try await super.setUp()
        dismissCalled = false
        store = TestStore(
            initialState: ExtensionFeature.State(),
            reducer: ExtensionFeature()
                .dependency(\.keyValueStorage, StubStorage())
                .dependency(\.tootSniffer, StubTootSniffer(.success(.placeholder)))
                .dependency(\.urlSession, .shared)
                .dependency(\.dismissExtension, { error in
                    XCTAssertFalse(self.dismissCalled)
                    self.dismissCalled = true
                    self.dismissError = error
                })
        )
    }

    func testDone() async throws {
        XCTAssertFalse(dismissCalled)
        await store.send(.tappedDone)
        await store.receive(.dismissed)
        XCTAssertTrue(dismissCalled)
        XCTAssertNil(dismissError)
    }

}
