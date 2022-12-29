import ComposableArchitecture
import XCTest
import SwiftUI
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
        var jsonText = String(data: try JSONEncoder().encode(persistible), encoding: .utf8)!
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
        defaults["settings"] = SettingsFeature.PersistableState.completeData
        await store.send(.save)
//        XCTAssertEqual(defaults["settings"], <#T##expression2: Equatable##Equatable#>)
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

    func testToggle() async throws {
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

    static var completeData: Data { try! JSONEncoder().encode(SettingsFeature.PersistableState.complete) }

}
