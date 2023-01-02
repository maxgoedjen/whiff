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
                .dependency(\.imageRenderer, StubImageRenderer(Image(systemName: "person")))
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
                .dependency(\.imageRenderer, StubImageRenderer(Image(systemName: "person")))
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

    func testHTMLInToot() async throws {
        store = TestStore(
            initialState: ExportFeature.State(),
            reducer: ExportFeature()
                .dependency(\.keyValueStorage, StubStorage())
                .dependency(\.tootSniffer, StubTootSniffer(.success(.placeholderWithHTML), .success(TootContext())))
                .dependency(\.imageRenderer, StubImageRenderer(Image(systemName: "person")))
                .dependency(\.urlSession, .shared)
        )
        await store.send(.requested(url: URL(string: "https://example.com")!))
        await store.receive(.settings(.load))
        await store.receive(.tootSniffCompleted(.success(.placeholderWithHTML))) {
            $0.toot = .placeholderWithHTML
            $0.visibleContextIDs = Set([""])
            var base = try! AttributedString(markdown: "Hello world. ![Test](https://example.com)")
            base.presentationIntent = nil
            let ns = NSMutableAttributedString(base)
            let range = (ns.string as NSString).range(of: "Test")
            let tint = UIColor(.blue)
            ns.setAttributes([.foregroundColor: tint], range: range)
            $0.attributedContent = [Toot.placeholderWithHTML.id: UncheckedSendable(AttributedString(ns))]
        }
        await store.receive(.tootSniffContextCompleted(.success(TootContext()))) {
            $0.tootContext = TootContext()
        }
    }

    func testChangingLinkColorRegeneratesAttributed() async throws {
        let image = Image(systemName: "person")
        store = TestStore(
            initialState: ExportFeature.State(),
            reducer: ExportFeature()
                .dependency(\.keyValueStorage, StubStorage())
                .dependency(\.tootSniffer, StubTootSniffer(.success(.placeholderWithHTML), .success(TootContext())))
                .dependency(\.imageRenderer, StubImageRenderer(image))
                .dependency(\.urlSession, .shared)
        )
        await store.send(.requested(url: URL(string: "https://example.com")!))
        await store.receive(.settings(.load))
        await store.receive(.tootSniffCompleted(.success(.placeholderWithHTML))) {
            $0.toot = .placeholderWithHTML
            $0.visibleContextIDs = Set([""])
            var base = try! AttributedString(markdown: "Hello world. ![Test](https://example.com)")
            base.presentationIntent = nil
            let nsAttributed = NSMutableAttributedString(base)
            let tint = UIColor(.blue)
            let range = (nsAttributed.string as NSString).range(of: "Test")
            nsAttributed.setAttributes([
                .foregroundColor: tint
            ], range: range)
            $0.attributedContent = [Toot.placeholderWithHTML.id: UncheckedSendable(AttributedString(nsAttributed))]
        }
        await store.receive(.tootSniffContextCompleted(.success(TootContext()))) {
            $0.tootContext = TootContext()
        }
        await store.receive(.rerendered(.success(image))) {
            $0.rendered = image
        }
        await store.receive(.loadImageCompleted(.failure(UnableToParseImageError())))
        await store.receive(.rerendered(.success(image)))
        let red = Color(red: 1, green: 0, blue: 0)
        await store.send(.settings(.linkColorModified(red))) {
            $0.settings.linkColor = red
            var base = try! AttributedString(markdown: "Hello world. ![Test](https://example.com)")
            base.presentationIntent = nil
            let nsAttributed = NSMutableAttributedString(base)
            let tint = UIColor(red)
            let range = (nsAttributed.string as NSString).range(of: "Test")
            nsAttributed.setAttributes([
                .foregroundColor: tint
            ], range: range)
            $0.attributedContent = [Toot.placeholderWithHTML.id: UncheckedSendable(AttributedString(nsAttributed))]
        }
        await store.receive(.settings(.save))
        await store.receive(.rerendered(.success(image)))
    }

    func testSettingChangeRerenders() async throws {
//        await store.send(.tootSniffCompleted(.success(.placeholder))) {
//            $0.toot = .placeholder
//            $0.visibleContextIDs = [Toot.placeholder.id]
//        }
//        await store.receive(.rerendered(.success(Image(systemName: "person"))))
    }

}

