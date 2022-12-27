import UIKit
import MobileCoreServices
import UniformTypeIdentifiers
import SwiftUI
import ComposableArchitecture
import WhiffFeatures

final class ShareExtension: UIHostingController<ExportFeatureView> {

    let store = Store(initialState: .init(), reducer: ExportFeature())

    required init?(coder aDecoder: NSCoder) {
        let rootView = ExportFeatureView(store: store)
        super.init(coder: aDecoder, rootView: rootView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        Task {
            do {
                ViewStore(store)
                    .send(.requested(url: try await url))
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

    @objc func done(_ sender: UIButton) {
        context.completeRequest(returningItems: context.inputItems, completionHandler: nil)
    }

}

struct URLNotFoundError: Error, LocalizedError {
    let errorDescription: String? = "This isn't a Mastodon URL."
}

