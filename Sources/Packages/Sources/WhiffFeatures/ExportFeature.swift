import ComposableArchitecture
import Foundation
@preconcurrency import SwiftUI
import TootSniffer

public struct ExportFeature: ReducerProtocol, Sendable {

    @Dependency(\.tootSniffer) var tootSniffer
    @Dependency(\.urlSession) var urlSession
    @Dependency(\.screenScale) var screenScale

    public struct State: Equatable, Sendable {
        public var toot: Toot?
        public var rendered: Image?
        public var showingSettings = false
        public var settings = SettingsFeature.State()
        public var images: [URL: Image] = [:]

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
                return .task {
                    return .settings(.load)
                }
                .concatenate(with: .task {
                    .tootSniffCompleted(await TaskResult { try await tootSniffer.sniff(url: url) })
                })
            case let .tootSniffCompleted(.success(toot)):
                state.toot = toot
                var effect = EffectTask.task { [state] in
                    try await rerenderTask(state: state)
                }
                for url in toot.allImages {
                    effect = effect.concatenate(with: EffectTask.task {
                        .loadImageCompleted(await TaskResult {
                            let (data, _) = try await urlSession.data(from: url)
                            guard let image = UIImage(data: data) else { throw UnableToParseImage() }
                            return ImageLoadResponse(url, Image(uiImage: image))
                        })
                    })
                }
                return effect
            case let .tootSniffCompleted(.failure(error)):
                state.toot = nil
                print(error)
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
            case .settings:
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
                let renderer = ImageRenderer(content: ScreenshotView(toot: toot, images: state.images, appearance: state.settings.appearance, showDate: state.settings.showDate))
                renderer.scale = screenScale
                guard let image = renderer.uiImage else {
                    throw UnableToRender()
                }
                return Image(uiImage: image)
            }
        )
    }

    public struct ImageLoadResponse: Equatable, Sendable {

        public let url: URL
        public let image: Image

        internal init(_ url: URL, _ image: Image) {
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
    let images: [URL: Image]
    let appearance: Appearance
    let showDate: Bool

    var body: some View {
        TootView(toot: toot, images: images, appearance: appearance, showDate: showDate)
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
                        TootView(toot: toot, images: viewStore.images, appearance: viewStore.settings.appearance, showDate: viewStore.settings.showDate)
                        Spacer()
                        if let shareContent = viewStore.rendered {
                            ShareLink(item: shareContent, preview: SharePreview("Rendered Toot"))
                            .buttonStyle(.borderedProminent)
                        } else {
                            ShareLink(item: "")
                                .buttonStyle(.borderedProminent)
                                .disabled(true)
                        }
                    }.sheet(isPresented: viewStore.binding(get: \.showingSettings, send: ExportFeature.Action.tappedSettings)) {
                        SettingsFeatureView(store: store.scope(state: \.settings, action: ExportFeature.Action.settings))
                            .presentationDetents([.medium])
                    }
                } else {
                    VStack {
                        Text("Loading Toot")
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
            }
            .padding()
        }

    }

}
