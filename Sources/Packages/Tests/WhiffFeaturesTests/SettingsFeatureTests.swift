import ComposableArchitecture
import SwiftUI
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
        let persistible = SettingsFeature.PersistableState.complete
        var jsonText = String(data: persistible.data, encoding: .utf8)!
        jsonText.replace("showDate", with: "newKey")
        defaults["settings"] = jsonText.data(using: .utf8)
        // All the keys in PersistibleState are optional, so both missing and unexpected keys should be fine.
        await store.send(.load) {
            $0.textColor = .red
            $0.linkColor = .blue
            $0.backgroundColor = .green
            $0.roundCorners = false
            $0.imageStyle = .stacked
            $0.linkStyle = .afterImage
        }
    }

    func testLoadFromInvalidJSON() async throws {
        defaults["settings"] = "asdf".data(using: .utf8)
        // Loading invalid shouldn't change anything
        await store.send(.load)
    }

    func testLoadFromComplete() async throws {
        defaults["settings"] = SettingsFeature.PersistableState.completeData
        await store.send(.load) {
            $0.textColor = .red
            $0.linkColor = .blue
            $0.backgroundColor = .green
            $0.showDate = true
            $0.roundCorners = false
            $0.imageStyle = .stacked
            $0.linkStyle = .afterImage
        }
    }

    func testSave() async throws {
        store = TestStore(
            initialState: SettingsFeature.State(.complete),
            reducer: SettingsFeature()
                .dependency(\.keyValueStorage, defaults)
        )
        XCTAssertNil(defaults["settings"])
        await store.send(.save)
        XCTAssertEqual(defaults["settings"], SettingsFeature.PersistableState.completeData)
    }

    func testSaveAndImmediateLoad() async throws {
        defaults["settings"] = SettingsFeature.PersistableState.completeData
        await store.send(.load) {
            $0.textColor = .red
            $0.linkColor = .blue
            $0.backgroundColor = .green
            $0.showDate = true
            $0.roundCorners = false
            $0.imageStyle = .stacked
            $0.linkStyle = .afterImage
        }
        defaults["settings"] = nil
        await store.send(.save)
        XCTAssertEqual(defaults["settings"], SettingsFeature.PersistableState.completeData)
    }

    func testReset() async throws {
        store = TestStore(
            initialState: SettingsFeature.State(.complete),
            reducer: SettingsFeature()
                .dependency(\.keyValueStorage, defaults)
        )
        XCTAssertNil(defaults["settings"])
        await store.send(.save)
        XCTAssertEqual(defaults["settings"], SettingsFeature.PersistableState.completeData)
        await store.send(.reset) {
            $0 = SettingsFeature.State()
        }
        await store.receive(.save)
        XCTAssertEqual(defaults["settings"], SettingsFeature.PersistableState().data)
    }

    func testDefaultColors() async throws {
        XCTAssertEqual(store.state.textColor, .white)
        XCTAssertEqual(store.state.linkColor, .blue)
        XCTAssertEqual(store.state.backgroundColor, .black)
    }

    func testSetters() async throws {
        await store.send(.textColorModified(.red)) {
            $0.textColor = .red
        }
        await store.receive(.save)

        await store.send(.linkColorModified(.red)) {
            $0.linkColor = .red
        }
        await store.receive(.save)

        await store.send(.backgroundColorModified(.red)) {
            $0.backgroundColor = .red
        }
        await store.receive(.save)

        await store.send(.showDateToggled(true)) {
            $0.showDate = true
        }
        await store.receive(.save)

        await store.send(.roundCornersToggled(false)) {
            $0.roundCorners = false
        }
        await store.receive(.save)

        await store.send(.imageStyleChanged(.fan)) {
            $0.imageStyle = .fan
        }
        await store.receive(.save)

        await store.send(.linkStyleChanged(.inImage)) {
            $0.linkStyle = .inImage
        }
        await store.receive(.save)

    }

}

extension SettingsFeature.PersistableState {

    static var complete = SettingsFeature.PersistableState(
        textColorData: Color.red.whf_data,
        linkColorData: Color.blue.whf_data,
        backgroundColorData: Color.green.whf_data,
        showDate: true,
        roundCorners: false,
        imageStyle: .stacked,
        linkStyle: .afterImage
    )

    static var completeData: Data {
        SettingsFeature.PersistableState.complete.data
    }

}

extension SettingsFeature.PersistableState {

    var data: Data {
        try! JSONEncoder().encode(self)
    }

}
