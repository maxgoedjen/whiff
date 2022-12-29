import ComposableArchitecture
import XCTest
@testable import WhiffFeatures

@MainActor
final class SettingsFeatureTests: XCTestCase {

    var defaults: StubStorage!
    var store: TestStore<SettingsFeature.State, SettingsFeature.Action, SettingsFeature.State, SettingsFeature.Action, Void>!

    override func setUp() async throws {
        try await super.setUp()
        defaults = StubStorage()
        store = TestStore(
            initialState: SettingsFeature.State(),
            reducer: SettingsFeature()
                .dependency(\.keyValueStorage, defaults)
        )
    }

    func testLoadFromEmpty() async throws {
        await store.send(.load)
    }

    func testLoadFromPartial() async throws {
    }

    func testLoadFromInvalidJSON() async throws {
        defaults["settings"] = "asdf".data(using: .utf8)
        // Loading invalid shouldn't change anything
        await store.send(.load)
    }

    func testLoadFromComplete() async throws {
        let persistible = SettingsFeature.PersistableState(
            textColorData: nil,
            linkColorData: nil,
            backgroundColorData: nil,
            showDate: true,
            roundCorners: false,
            imageStyle: .stacked,
            linkStyle: .afterImage
        )
        defaults["settings"] = try JSONEncoder().encode(persistible)
        await store.send(.load) {
            $0.showDate = true
            $0.roundCorners = false
            $0.imageStyle = .stacked
            $0.linkStyle = .afterImage
        }
    }

    func testDateToggle() async throws {
        await store.send(.showDateToggled(true)) {
            $0.showDate = true
        }
        await store.receive(.save)
        await store.send(.showDateToggled(false)) {
            $0.showDate = false
        }
        await store.receive(.save)
    }

}
