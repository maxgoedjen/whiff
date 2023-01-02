import ComposableArchitecture
import SwiftUI
import XCTest
@testable import TootSniffer
@testable import WhiffFeatures

@MainActor
final class ExportFeatureTests: XCTestCase {

    var store: TestStore<ExportFeature.State, ExportFeature.Action, ExportFeature.State, ExportFeature.Action, Void>!

    override func setUp() async throws {
        try await super.setUp()
        store = TestStore(
            initialState: ExportFeature.State(),
            reducer: ExportFeature()
                .dependency(\.keyValueStorage, StubStorage())
                .dependency(\.tootSniffer, StubTootSniffer(.success(.placeholder), .success(TootContext())))
                .dependency(\.urlSession, .shared)
        )
    }

    func testLoadEmpty() async throws {
        await store.send(.tappedSettings(true)) {
            $0.showingSettings = true
        }
    }

    func testRequested() async throws {
        store = TestStore(
            initialState: ExportFeature.State(),
            reducer: ExportFeature()
                .dependency(\.keyValueStorage, StubStorage())
                .dependency(\.tootSniffer, StubTootSniffer(.success(.placeholder), .success(TootContext())))
                .dependency(\.urlSession, .shared)
        )
        await store.send(.requested(url: URL(string: "https://example.com")!))
        await store.receive(.settings(.load))
        await store.receive(.tootSniffCompleted(.success(.placeholder))) {
            $0.toot = .placeholder
            $0.visibleContextIDs = [Toot.placeholder.id]
            $0.attributedContent = [Toot.placeholder.id: UncheckedSendable(AttributedString(Toot.placeholder.content))]
        }
    }

    // FIXME: This
    func testHTMLInToot() async throws {
//        store = TestStore(
//            initialState: ExportFeature.State(),
//            reducer: ExportFeature()
//                .dependency(\.keyValueStorage, StubStorage())
//                .dependency(\.tootSniffer, StubTootSniffer(.success(.placeholderWithHTML)))
//                .dependency(\.urlSession, .shared)
//        )
//        await store.send(.requested(url: URL(string: "https://example.com")!))
//        await store.receive(.settings(.load))
//        await store.receive(.tootSniffCompleted(.success(.placeholderWithHTML))) {
//            $0.toot = .placeholderWithHTML
//            var attributed = try! AttributedString(markdown: "Hello world. ![Test](https://example.com)")
//            let linkRange = attributed.range(of: "Test")!
//            attributed[linkRange].foregroundColor = .blue
//            $0.attributedContent = UncheckedSendable(attributed)
//        }
    }

    func testChangeColorSettingEvaluatesAttributedContent() async throws {
    }

    func testSettingChangeRerenders() async throws {
//        await store.send(.tootSniffCompleted(.success(.placeholder))) {
//            $0.toot = .placeholder
//            $0.visibleContextIDs = [Toot.placeholder.id]
//        }
//        await store.receive(.rerendered(.success(Image(systemName: "person"))))
    }

}
