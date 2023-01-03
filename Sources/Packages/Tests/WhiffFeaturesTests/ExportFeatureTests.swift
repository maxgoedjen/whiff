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
                .dependency(\.imageRenderer, StubImageRenderer(.sampleRendered))
                .dependency(\.imageLoader, StubImageLoader(.sampleAvatar))
                .dependency(\.mainQueue, .main)
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
                .dependency(\.imageRenderer, StubImageRenderer(.sampleRendered))
                .dependency(\.imageLoader, StubImageLoader(.sampleAvatar))
                .dependency(\.mainQueue, .main)
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
                .dependency(\.imageRenderer, StubImageRenderer(.sampleRendered))
                .dependency(\.imageLoader, StubImageLoader(.sampleAvatar))
                .dependency(\.mainQueue, .main)
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
        store = TestStore(
            initialState: ExportFeature.State(),
            reducer: ExportFeature()
                .dependency(\.keyValueStorage, StubStorage())
                .dependency(\.tootSniffer, StubTootSniffer(.success(.placeholderWithHTML), .success(TootContext())))
                .dependency(\.imageRenderer, StubImageRenderer(.sampleRendered))
                .dependency(\.imageLoader, StubImageLoader(.sampleAvatar))
                .dependency(\.mainQueue, .main)
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
        
        await store.receive(.loadImageCompleted(.success(.sampleAvatar))) {
            $0.images[.sampleAvatar] = .sampleAvatar
        }

        await store.receive(.rerendered(.success(.sampleRendered))) {
            $0.rendered = .sampleRendered
        }
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
        await store.receive(.rerendered(.success(.sampleRendered)))
    }

    func testSettingChangeRerenders() async throws {
        await store.send(.tootSniffCompleted(.success(.placeholder))) {
            $0.toot = .placeholder
            $0.attributedContent = [Toot.placeholder.id: UncheckedSendable(AttributedString(Toot.placeholder.content))]
            $0.visibleContextIDs = [Toot.placeholder.id]
        }
        await store.receive(.loadImageCompleted(.success(.sampleAvatar))) {
            $0.images[.sampleAvatar] = .sampleAvatar
        }
        await store.receive(.rerendered(.success(.sampleRendered))) {
            $0.rendered = .sampleRendered
        }
        await store.send(.settings(.linkStyleChanged(.none))) {
            $0.settings.linkStyle = .none
        }
        await store.receive(.settings(.save))
        await store.receive(.rerendered(.success(.sampleRendered)))
    }

    func testLoadFailureShowsMessage() async throws {
        store = TestStore(
            initialState: ExportFeature.State(),
            reducer: ExportFeature()
                .dependency(\.keyValueStorage, StubStorage())
                .dependency(\.tootSniffer, StubTootSniffer(.failure(NotAMastadonPostError()), .failure(NotAMastadonPostError())))
                .dependency(\.imageRenderer, StubImageRenderer(NotAMastadonPostError()))
                .dependency(\.imageLoader, StubImageLoader(URLError(.fileDoesNotExist)))
                .dependency(\.mainQueue, .main)
        )
        await store.send(.requested(url: URL(string: "https://example.com")!))
        await store.receive(.settings(.load))
        await store.receive(.tootSniffCompleted(.failure(NotAMastadonPostError()))) {
            $0.toot = nil
            $0.errorMessage = NotAMastadonPostError().localizedDescription
        }
    }

    func testLoadFailureWithoutMessageShowsFallback() async throws {
        struct BadError: Error, Equatable {}
        store = TestStore(
            initialState: ExportFeature.State(),
            reducer: ExportFeature()
                .dependency(\.keyValueStorage, StubStorage())
                .dependency(\.tootSniffer, StubTootSniffer(.failure(BadError()), .failure(BadError())))
                .dependency(\.imageRenderer, StubImageRenderer(NotAMastadonPostError()))
                .dependency(\.imageLoader, StubImageLoader(URLError(.fileDoesNotExist)))
                .dependency(\.mainQueue, .main)
        )
        await store.send(.requested(url: URL(string: "https://example.com")!))
        await store.receive(.settings(.load))
        await store.receive(.tootSniffCompleted(.failure(BadError()))) {
            $0.toot = nil
            $0.errorMessage = "Unknown Error"
        }
    }

    func testContextFailureStillShowsBase() async throws {
        store = TestStore(
            initialState: ExportFeature.State(),
            reducer: ExportFeature()
                .dependency(\.keyValueStorage, StubStorage())
                .dependency(\.tootSniffer, StubTootSniffer(.success(.placeholder), .failure(NotAMastadonPostError())))
                .dependency(\.imageRenderer, StubImageRenderer(NotAMastadonPostError()))
                .dependency(\.imageLoader, StubImageLoader(URLError(.fileDoesNotExist)))
                .dependency(\.mainQueue, .main)
        )
        await store.send(.requested(url: URL(string: "https://example.com")!))
        await store.receive(.settings(.load))
        await store.receive(.tootSniffCompleted(.success(.placeholder))) {
            $0.toot = .placeholder
            $0.attributedContent = [Toot.placeholder.id: UncheckedSendable(AttributedString(Toot.placeholder.content))]
            $0.visibleContextIDs = Set([""])
        }
        await store.receive(.tootSniffContextCompleted(.failure(NotAMastadonPostError())))
    }

    func testImageLoadFailureStillRenders() async throws {
        store = TestStore(
            initialState: ExportFeature.State(),
            reducer: ExportFeature()
                .dependency(\.keyValueStorage, StubStorage())
                .dependency(\.tootSniffer, StubTootSniffer(.success(.placeholder), .success(TootContext())))
                .dependency(\.imageRenderer, StubImageRenderer(.sampleRendered))
                .dependency(\.imageLoader, StubImageLoader(URLError(.fileDoesNotExist)))
                .dependency(\.mainQueue, .main)
        )
        await store.send(.requested(url: URL(string: "https://example.com")!))
        await store.receive(.settings(.load))
        await store.receive(.tootSniffCompleted(.success(.placeholder))) {
            $0.toot = .placeholder
            $0.attributedContent = [Toot.placeholder.id: UncheckedSendable(AttributedString(Toot.placeholder.content))]
            $0.visibleContextIDs = Set([""])
        }
        await store.receive(.tootSniffContextCompleted(.success(TootContext()))) {
            $0.tootContext = TootContext()
        }
        await store.receive(.loadImageCompleted(.failure(URLError(.fileDoesNotExist))))
        await store.receive(.rerendered(.success(.sampleRendered))) {
            $0.rendered = .sampleRendered
        }
    }

}

extension Image {
    static var sampleAvatar: Image { Image(systemName: "person") }
    static var sampleRendered: Image { Image(systemName: "square.and.arrow.up") }
}

extension URLKey {
    static var sampleAvatar: URLKey {
        URLKey("https://example.com/avatar")
    }
}

extension ExportFeature.ImageLoadResponse {
    static var sampleAvatar: ExportFeature.ImageLoadResponse {
        .init(.sampleAvatar, .sampleAvatar)
    }
}
