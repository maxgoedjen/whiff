import ComposableArchitecture
import Foundation
@preconcurrency import SwiftUI
import TootSniffer

public struct ExportFeature: ReducerProtocol, Sendable {

    @Dependency(\.tootSniffer) var tootSniffer
    @Dependency(\.urlSession) var urlSession

    public struct State: Equatable, Sendable {
        public var toot: Toot?
        public var rendered: Image?
        public var textColor: Color = .white
        public var backgroundColor: Color = .black
        public var showDate: Bool = true
        public var shareLink: Bool = false

        fileprivate var appearance: Appearance {
            Appearance(textColor: textColor, backgroundColor: backgroundColor)
        }

        public init() {
        }
    }

    public enum Action: Equatable {
        case requested(url: URL)
        case tootSniffCompleted(TaskResult<Toot>)
        case showDateToggled(Bool)
        case shareLinkToggled(Bool)
        case textColorModified(Color)
        case backgroundColorModified(Color)
        case rerendered(TaskResult<Image>)
    }

    public init() {
    }

    public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .requested(url):
            return .task {
                .tootSniffCompleted(await TaskResult { try await tootSniffer.sniff(url: url) })
            }
        case let .tootSniffCompleted(.success(toot)):
            state.toot = toot
            return .task { [state] in
                try await rerenderTask(state: state)
            }
        case let .tootSniffCompleted(.failure(error)):
            state.toot = nil
            print(error)
            return .task { [state] in
                try await rerenderTask(state: state)
            }
        case let .showDateToggled(show):
            state.showDate = show
            return .task { [state] in
                try await rerenderTask(state: state)
            }
        case let .shareLinkToggled(share):
            state.shareLink = share
            return .task { [state] in
                try await rerenderTask(state: state)
            }
        case let .textColorModified(color):
            state.textColor = color
            return .task { [state] in
                try await rerenderTask(state: state)
            }
        case let .backgroundColorModified(color):
            state.backgroundColor = color
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

    private func rerenderTask(state: State) async throws -> Action {
        .rerendered(
            await TaskResult {
                guard let toot = state.toot else {
                    throw UnableToRender()
                }
                guard let image = await ImageRenderer(content: ScreenshotView(toot: toot, appearance: state.appearance, showDate: state.showDate)).uiImage else {
                    throw UnableToRender()
                }
                return Image(uiImage: image)
            }
        )
    }

    struct UnableToRender: Error {
    }

}

struct ScreenshotView: View, Sendable {

    let toot: Toot
    let appearance: Appearance
    let showDate: Bool

    var body: some View {
        TootView(toot: toot, appearance: appearance, showDate: showDate)
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
                        TootView(toot: toot, appearance: viewStore.appearance, showDate: viewStore.showDate)
                        Spacer()
                        ColorPicker(selection: viewStore.binding(get: \.textColor, send: ExportFeature.Action.textColorModified).animation(), supportsOpacity: false) {
                            Text("Text Color")
                        }
                        ColorPicker(selection: viewStore.binding(get: \.backgroundColor, send: ExportFeature.Action.backgroundColorModified).animation(), supportsOpacity: false) {
                            Text("Background Color")
                        }
                        Toggle("Show Date",
                               isOn: viewStore.binding(get: \.showDate, send: ExportFeature.Action.showDateToggled))
                        Toggle("Share Link with Image",
                               isOn: viewStore.binding(get: \.shareLink, send: ExportFeature.Action.shareLinkToggled))
                        .hidden() // FIXME: This
                        if let shareContent = viewStore.rendered {
                            ShareLink(item: shareContent, preview: SharePreview("Rendered Toot"))
                            .buttonStyle(.borderedProminent)
                        } else {
                            ShareLink(item: "")
                                .buttonStyle(.borderedProminent)
                                .disabled(true)
                        }
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
            .task {
                viewStore.send(.requested(url: URL(string: "https://mstdn.social/@lolennui/109547842480496094")!))
            }
        }

    }

}
