import ComposableArchitecture
import Foundation
import SwiftUI
import TootSniffer

public struct ExportFeature: ReducerProtocol, Sendable {

    @Dependency(\.tootSniffer) var tootSniffer

    public struct State: Equatable, Sendable {
        public var toot: Toot?
        public var textColor: UncheckedSendable<Color> = UncheckedSendable(.white)
        public var backgroundColor: UncheckedSendable<Color> = UncheckedSendable(.black)
        public var showDate: Bool = true
        public var shareLink: Bool = false

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
        case tappedShare
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
            return .none
        case let .tootSniffCompleted(.failure(error)):
            state.toot = nil
            print(error)
            return .none
        case let .showDateToggled(show):
            state.showDate = show
            return .none
        case let .shareLinkToggled(share):
            state.shareLink = share
            return .none
        case let .textColorModified(color):
            state.textColor = UncheckedSendable(color)
            return .none
        case let .backgroundColorModified(color):
            state.backgroundColor = UncheckedSendable(color)
            return .none
        case .tappedShare:
            print("SHARE")
            return .none
        }
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
                        TootView(toot: toot, appearance: Appearance(textColor: viewStore.textColor.value, backgroundColor: viewStore.backgroundColor.value), showDate: viewStore.showDate)
                        Spacer()
                        ColorPicker(selection: viewStore.binding(get: \.textColor.value, send: ExportFeature.Action.textColorModified).animation(), supportsOpacity: false) {
                            Text("Text Color")
                        }
                        ColorPicker(selection: viewStore.binding(get: \.backgroundColor.value, send: ExportFeature.Action.backgroundColorModified).animation(), supportsOpacity: false) {
                            Text("Background Color")
                        }
                        Toggle("Show Date",
                               isOn: viewStore.binding(get: \.showDate, send: ExportFeature.Action.showDateToggled))
                        Toggle("Share Link with Image",
                               isOn: viewStore.binding(get: \.shareLink, send: ExportFeature.Action.shareLinkToggled))
                        Button("Share") {
                            viewStore.send(.tappedShare)
                        }
                        .buttonStyle(.borderedProminent)
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
