import BlurHashKit
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
        await store.receive(.tootSniffContextCompleted(.success(TootContext()))) {
            $0.tootContext = TootContext()
        }
        await store.receive(.loadImageCompleted(.success(.sampleAvatar))) {
            $0.images[.sampleAvatar] = .sampleAvatar
        }
        await store.receive(.rerendered(.success(.sampleRendered))) {
            $0.rendered = .sampleRendered
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
            $0.visibleContextIDs = Set(["root"])
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
            $0.visibleContextIDs = Set(["root"])
            var base = try! AttributedString(markdown: "Hello world. ![Test](https://example.com)")
            base.presentationIntent = nil
            let nsAttributed = NSMutableAttributedString(base)
            let tint = UIColor(.blue)
            let range = (nsAttributed.string as NSString).range(of: "Test")
            nsAttributed.setAttributes([
                .foregroundColor: tint,
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
                .foregroundColor: tint,
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
        struct BadError: Error, Equatable {
        }
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
            $0.visibleContextIDs = Set(["root"])
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
            $0.visibleContextIDs = Set(["root"])
        }
        await store.receive(.tootSniffContextCompleted(.success(TootContext()))) {
            $0.tootContext = TootContext()
        }
        await store.receive(.loadImageCompleted(.failure(URLError(.fileDoesNotExist))))
        await store.receive(.rerendered(.success(.sampleRendered))) {
            $0.rendered = .sampleRendered
        }
    }

    func testImagesLoaded() async throws {
        store = TestStore(
            initialState: ExportFeature.State(),
            reducer: ExportFeature()
                .dependency(\.keyValueStorage, StubStorage())
                .dependency(\.tootSniffer, StubTootSniffer(.success(.placeholderWithAttachments), .success(TootContext())))
                .dependency(\.imageRenderer, StubImageRenderer(.sampleRendered))
                .dependency(\.imageLoader, StubImageLoader(.sampleAvatar, loadOrder: [
                    "https://example.com/avatar",
                    "https://example.com/3",
                    "https://example.com/2",
                    "https://example.com/1",
                    "https://example.com/0",
                ].map { URL(string: $0)! }))
                .dependency(\.mainQueue, .main)
        )
        await store.send(.requested(url: URL(string: "https://example.com")!))
        await store.receive(.settings(.load))
        let blurhashes: [URLKey: ImageEquatable] = [
            URLKey("https://example.com/0", .blurhash): .sampleBlurhash,
            URLKey("https://example.com/1", .blurhash): .sampleBlurhash,
            URLKey("https://example.com/2", .blurhash): .sampleBlurhash,
            URLKey("https://example.com/3", .blurhash): .sampleBlurhash,
        ]
        await store.receive(.tootSniffCompleted(.success(.placeholderWithAttachments))) {
            $0.toot = .placeholderWithAttachments
            $0.attributedContent = [Toot.placeholder.id: UncheckedSendable(AttributedString(Toot.placeholderWithAttachments.content))]
            $0.visibleContextIDs = Set(["root"])
            $0.images = blurhashes
        }
        await store.receive(.tootSniffContextCompleted(.success(TootContext()))) {
            $0.tootContext = TootContext()
        }
        await store.receive(.loadImageCompleted(.success(.sampleAvatar))) {
            $0.images = blurhashes
            $0.images[URLKey("https://example.com/avatar")] = .sampleAvatar
        }
        await store.receive(.loadImageCompleted(.success(.loadResponse("3")))) {
            $0.images = blurhashes
            $0.images[URLKey("https://example.com/avatar")] = .sampleAvatar
            $0.images[URLKey("https://example.com/3")] = .sampleAvatar
        }
        await store.receive(.loadImageCompleted(.success(.loadResponse("2")))) {
            $0.images = blurhashes
            $0.images[URLKey("https://example.com/avatar")] = .sampleAvatar
            $0.images[URLKey("https://example.com/3")] = .sampleAvatar
            $0.images[URLKey("https://example.com/2")] = .sampleAvatar
        }
        await store.receive(.loadImageCompleted(.success(.loadResponse("1")))) {
            $0.images = blurhashes
            $0.images[URLKey("https://example.com/avatar")] = .sampleAvatar
            $0.images[URLKey("https://example.com/3")] = .sampleAvatar
            $0.images[URLKey("https://example.com/2")] = .sampleAvatar
            $0.images[URLKey("https://example.com/1")] = .sampleAvatar
        }
        await store.receive(.loadImageCompleted(.success(.loadResponse("0")))) {
            $0.images = blurhashes
            $0.images[URLKey("https://example.com/avatar")] = .sampleAvatar
            $0.images[URLKey("https://example.com/3")] = .sampleAvatar
            $0.images[URLKey("https://example.com/2")] = .sampleAvatar
            $0.images[URLKey("https://example.com/1")] = .sampleAvatar
            $0.images[URLKey("https://example.com/0")] = .sampleAvatar
        }
        await store.receive(.rerendered(.success(.sampleRendered))) {
            $0.rendered = .sampleRendered
        }
    }

    func testVideoImageLoaded() async throws {
        store = TestStore(
            initialState: ExportFeature.State(),
            reducer: ExportFeature()
                .dependency(\.keyValueStorage, StubStorage())
                .dependency(\.tootSniffer, StubTootSniffer(.success(.placeholderWithVideoAttachment), .success(TootContext())))
                .dependency(\.imageRenderer, StubImageRenderer(.sampleRendered))
                .dependency(\.imageLoader, StubImageLoader(.sampleAvatar, loadOrder: [
                    "https://example.com/avatar",
                    "https://example.com/video_thumb",
                ].map { URL(string: $0)! }))
                .dependency(\.mainQueue, .main)
        )
        await store.send(.requested(url: URL(string: "https://example.com")!))
        await store.receive(.settings(.load))
        let blurhashes: [URLKey: ImageEquatable] = [
            URLKey("https://example.com/video_thumb", .blurhash): .sampleBlurhash,
        ]
        await store.receive(.tootSniffCompleted(.success(.placeholderWithVideoAttachment))) {
            $0.toot = .placeholderWithVideoAttachment
            $0.attributedContent = [Toot.placeholder.id: UncheckedSendable(AttributedString(Toot.placeholderWithVideoAttachment.content))]
            $0.visibleContextIDs = Set(["root"])
            $0.images = blurhashes
        }
        await store.receive(.tootSniffContextCompleted(.success(TootContext()))) {
            $0.tootContext = TootContext()
        }
        await store.receive(.loadImageCompleted(.success(.sampleAvatar))) {
            $0.images = blurhashes
            $0.images[URLKey("https://example.com/avatar")] = .sampleAvatar
        }
        await store.receive(.loadImageCompleted(.success(.loadResponse("video_thumb")))) {
            $0.images = blurhashes
            $0.images[URLKey("https://example.com/avatar")] = .sampleAvatar
            $0.images[URLKey("https://example.com/video_thumb")] = .sampleAvatar
        }
        await store.receive(.rerendered(.success(.sampleRendered))) {
            $0.rendered = .sampleRendered
        }
    }

    func testContextImagesLoaded() async throws {
        store = TestStore(
            initialState: ExportFeature.State(),
            reducer: ExportFeature()
                .dependency(\.keyValueStorage, StubStorage())
                .dependency(\.tootSniffer, StubTootSniffer(.success(.placeholderWithAttachmentName("root")), .success(TootContext(
                    ancestors: [.placeholderWithAttachmentName("ancestor")],
                    descendants: [.placeholderWithAttachmentName("descendant")]
                ))))
                .dependency(\.imageRenderer, StubImageRenderer(.sampleRendered))
                .dependency(\.imageLoader, StubImageLoader(.sampleAvatar, loadOrder: [
                    "https://example.com/root_avatar",
                    "https://example.com/ancestor_avatar",
                    "https://example.com/descendant_avatar",
                    "https://example.com/attachments/root",
                    "https://example.com/attachments/ancestor",
                    "https://example.com/attachments/descendant",
                ].map { URL(string: $0)! }))
                .dependency(\.mainQueue, .main)
        )
        await store.send(.requested(url: URL(string: "https://example.com")!))
        await store.receive(.settings(.load))
        await store.receive(.tootSniffCompleted(.success(.placeholderWithAttachmentName("root")))) {
            $0.toot = .placeholderWithAttachmentName("root")
            $0.attributedContent = [Toot.placeholder.id: UncheckedSendable(AttributedString(Toot.placeholderWithAttachmentName("root").content))]
            $0.visibleContextIDs = Set(["root"])
            $0.images[URLKey("https://example.com/attachments/root", .blurhash)] = .sampleBlurhash
        }
        let context = TootContext(
            ancestors: [.placeholderWithAttachmentName("ancestor")],
            descendants: [.placeholderWithAttachmentName("descendant")]
        )
        let blurhashes: [URLKey: ImageEquatable] = [
            URLKey("https://example.com/attachments/root", .blurhash): .sampleBlurhash,
            URLKey("https://example.com/attachments/ancestor", .blurhash): .sampleBlurhash,
            URLKey("https://example.com/attachments/descendant", .blurhash): .sampleBlurhash,
        ]
        await store.receive(.tootSniffContextCompleted(.success(context))) {
            $0.tootContext = context
            $0.attributedContent[Toot.placeholderWithAttachmentName("ancestor").id] = UncheckedSendable(AttributedString(Toot.placeholderWithAttachmentName("ancestor").content))
            $0
                .attributedContent[Toot.placeholderWithAttachmentName("descendant").id] =
                UncheckedSendable(AttributedString(Toot.placeholderWithAttachmentName("descendant").content))
            $0.images = blurhashes
        }
        await store.receive(.loadImageCompleted(.success(.loadResponse("root_avatar")))) {
            $0.images = blurhashes
            $0.images[URLKey("https://example.com/root_avatar")] = .sampleAvatar
        }
        await store.receive(.loadImageCompleted(.success(.loadResponse("ancestor_avatar")))) {
            $0.images = blurhashes
            $0.images[URLKey("https://example.com/root_avatar")] = .sampleAvatar
            $0.images[URLKey("https://example.com/ancestor_avatar")] = .sampleAvatar
        }
        await store.receive(.loadImageCompleted(.success(.loadResponse("descendant_avatar")))) {
            $0.images = blurhashes
            $0.images[URLKey("https://example.com/root_avatar")] = .sampleAvatar
            $0.images[URLKey("https://example.com/ancestor_avatar")] = .sampleAvatar
            $0.images[URLKey("https://example.com/descendant_avatar")] = .sampleAvatar
        }
        await store.receive(.loadImageCompleted(.success(.loadResponse("attachments/root")))) {
            $0.images = blurhashes
            $0.images[URLKey("https://example.com/root_avatar")] = .sampleAvatar
            $0.images[URLKey("https://example.com/ancestor_avatar")] = .sampleAvatar
            $0.images[URLKey("https://example.com/descendant_avatar")] = .sampleAvatar
            $0.images[URLKey("https://example.com/attachments/root")] = .sampleAvatar
        }
        await store.receive(.loadImageCompleted(.success(.loadResponse("attachments/ancestor")))) {
            $0.images = blurhashes
            $0.images[URLKey("https://example.com/root_avatar")] = .sampleAvatar
            $0.images[URLKey("https://example.com/ancestor_avatar")] = .sampleAvatar
            $0.images[URLKey("https://example.com/descendant_avatar")] = .sampleAvatar
            $0.images[URLKey("https://example.com/attachments/root")] = .sampleAvatar
            $0.images[URLKey("https://example.com/attachments/ancestor")] = .sampleAvatar
        }
        await store.receive(.loadImageCompleted(.success(.loadResponse("attachments/descendant")))) {
            $0.images = blurhashes
            $0.images[URLKey("https://example.com/root_avatar")] = .sampleAvatar
            $0.images[URLKey("https://example.com/ancestor_avatar")] = .sampleAvatar
            $0.images[URLKey("https://example.com/descendant_avatar")] = .sampleAvatar
            $0.images[URLKey("https://example.com/attachments/root")] = .sampleAvatar
            $0.images[URLKey("https://example.com/attachments/ancestor")] = .sampleAvatar
            $0.images[URLKey("https://example.com/attachments/descendant")] = .sampleAvatar
        }
        await store.receive(.rerendered(.success(.sampleRendered))) {
            $0.rendered = .sampleRendered
        }

    }

    func testBlurhashGeneration() async throws {
        store = TestStore(
            initialState: ExportFeature.State(),
            reducer: ExportFeature()
                .dependency(\.keyValueStorage, StubStorage())
                .dependency(\.tootSniffer, StubTootSniffer(.success(.placeholderWithAttachmentName("root")), .success(TootContext(
                    ancestors: [.placeholderWithAttachmentName("ancestor")],
                    descendants: [.placeholderWithAttachmentName("descendant")]
                ))))
                .dependency(\.imageRenderer, StubImageRenderer(.sampleRendered))
                .dependency(\.imageLoader, StubImageLoader(.sampleAvatar))
                .dependency(\.mainQueue, .main)
        )
        await store.send(.requested(url: URL(string: "https://example.com")!))
        await store.receive(.settings(.load))
        await store.receive(.tootSniffCompleted(.success(.placeholderWithAttachmentName("root")))) {
            $0.toot = .placeholderWithAttachmentName("root")
            $0.attributedContent = [Toot.placeholder.id: UncheckedSendable(AttributedString(Toot.placeholderWithAttachmentName("root").content))]
            $0.visibleContextIDs = Set(["root"])
            $0.images[URLKey("https://example.com/attachments/root", .blurhash)] = .sampleBlurhash
        }
        let context = TootContext(ancestors: [.placeholderWithAttachmentName("ancestor")], descendants: [.placeholderWithAttachmentName("descendant")])
        await store.receive(.tootSniffContextCompleted(.success(context))) {
            $0.tootContext = context
            $0.attributedContent[Toot.placeholderWithAttachmentName("ancestor").id] = UncheckedSendable(AttributedString(Toot.placeholderWithAttachmentName("ancestor").content))
            $0
                .attributedContent[Toot.placeholderWithAttachmentName("descendant").id] =
                UncheckedSendable(AttributedString(Toot.placeholderWithAttachmentName("descendant").content))
            $0.images[URLKey("https://example.com/attachments/root", .blurhash)] = .sampleBlurhash
            $0.images[URLKey("https://example.com/attachments/ancestor", .blurhash)] = .sampleBlurhash
            $0.images[URLKey("https://example.com/attachments/descendant", .blurhash)] = .sampleBlurhash
        }

    }

    func testSelection() async throws {
        store = TestStore(
            initialState: ExportFeature.State(toot: .placeholder, tootContext:
                TootContext(
                    ancestors: [.placeholderWithAttachmentName("ancestor")],
                    descendants: [.placeholderWithAttachmentName("descendant")]
                )),
            reducer: ExportFeature()
                .dependency(\.keyValueStorage, StubStorage())
                .dependency(\.imageRenderer, StubImageRenderer(.sampleRendered))
                .dependency(\.mainQueue, .main)
        )
        await store.send(.tappedContextToot(.placeholder))
        await store.receive(.rerendered(.success(.sampleRendered))) {
            $0.rendered = .sampleRendered
        }
        await store.send(.tappedContextToot(.placeholderWithAttachmentName("ancestor"))) {
            $0.visibleContextIDs = ["ancestor", "root"]
        }
        await store.receive(.rerendered(.success(.sampleRendered)))
        await store.send(.tappedContextToot(.placeholderWithAttachmentName("ancestor"))) {
            $0.visibleContextIDs = ["root"]
        }
        await store.receive(.rerendered(.success(.sampleRendered)))
        await store.send(.tappedContextToot(.placeholderWithAttachmentName("descendant"))) {
            $0.visibleContextIDs = ["root", "descendant"]
        }
        await store.receive(.rerendered(.success(.sampleRendered)))

    }

}

extension ImageEquatable {
    static var sampleAvatar: ImageEquatable { ImageEquatable(image: Image(systemName: "person"), equatableValue: "avatar") }
    static var sampleRendered: ImageEquatable { ImageEquatable(image: Image(systemName: "person"), equatableValue: "rendered") }
    static var sampleBlurhash: ImageEquatable {
        ImageEquatable(uiImage: BlurHash(string: "LEHV6nWB2yk8pyo0adR*.7kCMdnj")!.image(size: CGSize(width: 10, height: 10))!, equatableValue: "LEHV6nWB2yk8pyo0adR*.7kCMdnj")
    }
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

    static func loadResponse(_ key: String) -> ExportFeature.ImageLoadResponse {
        .init(URLKey("https://example.com/\(key)"), .sampleAvatar)
    }

}
