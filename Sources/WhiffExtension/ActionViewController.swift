import UIKit
import MobileCoreServices
import UniformTypeIdentifiers
import SwiftUI
import ComposableArchitecture
import WhiffFeatures

final class ShareExtension: UIHostingController<ExtensionFeatureView> {

    var store: StoreOf<ExtensionFeature>!

    required init?(coder aDecoder: NSCoder) {
        // Stub impl to make IB happy
        // Real stuff happens in loadView
        let stub = ExtensionFeatureView(store: Store(initialState: .init(), reducer: ExtensionFeature()))
        super.init(coder: aDecoder, rootView: stub)
    }

    override func loadView() {
        super.loadView()
        let uncheckedContext = UncheckedSendable(context)
        store = Store(initialState: .init(), reducer: ExtensionFeature()
            .dependency(\.dismissExtension) { @MainActor @Sendable [uncheckedContext] error in
                if let error {
                    uncheckedContext.value.cancelRequest(withError: error)
                } else {
                    uncheckedContext.value.completeRequest(returningItems: [], completionHandler: nil)
                }
            })
        rootView = ExtensionFeatureView(store: store)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            do {
                ViewStore(store)
                    .send(.export(.requested(url: try await url)))
            } catch {
                context.cancelRequest(withError: error)
            }
        }
    }

    var url: URL {
        get async throws {
            guard let items = context.inputItems as? [NSExtensionItem] else { throw URLNotFoundError() }
            let urlProviders = items
                .flatMap { $0.attachments ?? [] }
                .filter { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }
            guard let provider = urlProviders.first else { throw URLNotFoundError() }
            let url = try await withCheckedThrowingContinuation { continuation in
                _ = provider.loadTransferable(type: URL.self) { result in
                    continuation.resume(with: result)
                }
            }
            return url
        }
    }

    var context: NSExtensionContext {
        self.extensionContext!
    }

}

struct URLNotFoundError: Error, LocalizedError {
    let errorDescription: String? = "This isn't a Mastodon URL."
}

