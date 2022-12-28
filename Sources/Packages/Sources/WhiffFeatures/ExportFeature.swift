import ComposableArchitecture
import BlurHashKit
import Foundation
@preconcurrency import SwiftUI
import TootSniffer

public struct ExportFeature: ReducerProtocol, Sendable {

    @Dependency(\.tootSniffer) var tootSniffer
    @Dependency(\.urlSession) var urlSession
    @Dependency(\.screenScale) var screenScale

    public struct State: Equatable, Sendable {
        public var toot: Toot?
        public var errorMessage: String?
        public var rendered: Image?
        public var showingSettings = false
        public var settings = SettingsFeature.State()
        public var images: [URLKey: Image] = [:]

        public init() {
        }
    }

    public enum Action: Equatable {
        case requested(url: URL)
        case tootSniffCompleted(TaskResult<Toot>)
        case loadImageCompleted(TaskResult<ImageLoadResponse>)
        case tappedSettings(Bool)
        case settings(SettingsFeature.Action)
        case rerendered(TaskResult<Image>)
    }

    public init() {
    }

    public var body: some ReducerProtocol<State, Action> {
        Scope(state: \.settings, action: /Action.settings) {
            SettingsFeature()
        }
        Reduce { state, action in
            switch action {
            case let .requested(url):
                state.toot = nil
                state.images = [:]
                return .task {
                    .tootSniffCompleted(await TaskResult { try await tootSniffer.sniff(url: url) })
                }
            case let .tootSniffCompleted(.success(toot)):
                state.toot = toot
                state.errorMessage = nil
                var effect = EffectTask.task { [state] in
                    try await rerenderTask(state: state)
                }
//                for attachment in toot.allImages {
//                    let url = attachment.url
//                    guard let blurhash = attachment.blurhash else { continue }
//                    effect = effect.concatenate(with: EffectTask.task {
//                        return .loadImageCompleted(await TaskResult {
//                            let key = URLKey(url, .blurhash)
//                            guard let image = BlurHash(string: blurhash)?.image(size: attachment.size) else { throw UnableToParseImage() }
//                            return ImageLoadResponse(key, Image(uiImage: image))
//                        })
//                    })
//                }
                for attachment in toot.allImages {
                    let url = attachment.url
                    effect = effect.concatenate(with: EffectTask.task {
                        .loadImageCompleted(await TaskResult {
                            let key = URLKey(url, .remote)
                            let (data, _) = try await urlSession.data(from: url)
                            guard let image = UIImage(data: data) else { throw UnableToParseImage() }
                            return ImageLoadResponse(key, Image(uiImage: image))
                        })
                    })
                }
                return effect
            case let .tootSniffCompleted(.failure(error)):
                state.toot = nil
                if let localized = error as? LocalizedError {
                    state.errorMessage = localized.errorDescription
                } else {
                    state.errorMessage = "Unknown Error"
                }
                return .task { [state] in
                    try await rerenderTask(state: state)
                }
            case let .loadImageCompleted(.success(response)):
                state.images[response.url] = response.image
                return .task { [state] in
                    try await rerenderTask(state: state)
                }
            case let .loadImageCompleted(.failure(error)):
                print(error)
                return .none
            case let .tappedSettings(showing):
                state.showingSettings = showing
                return .none
            case let .settings(action):
                if case .tappedDone = action {
                    state.showingSettings = false
                }
                return .task { [state] in
                    try await rerenderTask(state: state)
                }
            case .rerendered(.failure):
                state.rendered = nil
                return .none
            case let .rerendered(.success(image)):
                state.rendered = image
                return .none
            }
        }
    }

    private func rerenderTask(state: State) async throws -> Action {
        .rerendered(
            await TaskResult { @MainActor in
                guard let toot = state.toot else {
                    throw UnableToRender()
                }
                let renderer = ImageRenderer(content: ScreenshotView(toot: toot, images: state.images, settings: state.settings))
                renderer.scale = screenScale
                guard let image = renderer.uiImage else {
                    throw UnableToRender()
                }
                return Image(uiImage: image)
            }
        )
    }

    public struct ImageLoadResponse: Equatable, Sendable {

        public let url: URLKey
        public let image: Image

        internal init(_ url: URLKey, _ image: Image) {
            self.url = url
            self.image = image
        }

    }

    struct UnableToParseImage: Error {
    }

    struct UnableToRender: Error {
    }

}

struct ScreenshotView: View, Sendable {

    let toot: Toot
    let images: [URLKey: Image]
    let settings: SettingsFeature.State

    var body: some View {
        TootView(toot: toot, images: images, settings: settings)
            .frame(width: 400)
    }

}

public struct ExportFeatureView: View {

    let store: StoreOf<ExportFeature>

    public init(store: StoreOf<ExportFeature>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store) { viewStore in
            Group {
                if let toot = viewStore.toot {
                    VStack {
                        ScrollView {
                            TootView(toot: toot, images: viewStore.images, settings: viewStore.settings)
                                .cornerRadius(15)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(.white.opacity(0.5), lineWidth: 3)
                                }
                                .padding()
                        }
                        Spacer()
                        if let rendered = viewStore.rendered {
                            // FIXME: CONDITIONAL LINK SHARE
                            ShareLink(item: rendered, message: Text(toot.url.absoluteString), preview: SharePreview("Rendered Toot"))
                                .buttonStyle(.borderedProminent)
                        } else {
                            ShareLink(item: "")
                                .buttonStyle(.borderedProminent)
                                .disabled(true)
                        }
                    }
                    .sheet(isPresented: viewStore.binding(get: \.showingSettings, send: ExportFeature.Action.tappedSettings)) {
                        SettingsFeatureView(store: store.scope(state: \.settings, action: ExportFeature.Action.settings))
                            .presentationDetents([.medium])
                    }
                } else if let error = viewStore.errorMessage {
                    VStack {
                        Text("Error")
                            .font(.headline)
                        Text(error)
                    }
                } else {
                    VStack {
                        TootView(toot: .placeholder, images: [:], settings: viewStore.settings)
                            .redacted(reason: .placeholder)
                            .cornerRadius(15)
                            .overlay {
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(.white.opacity(0.5), lineWidth: 3)
                            }
                            .padding()
                        Text("Loading Toot")
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewStore.send(.tappedSettings(true))
                    } label: {
                        Image(systemName: "paintbrush")
                    }

                }
            }

        }

    }

}
