import ComposableArchitecture
import SwiftUI
import TootSniffer

public struct AppFeature: ReducerProtocol, Sendable {

    public struct State: Equatable, Sendable {
        public var showing = false
        public var exportState = ExportFeature.State()

        public init() {
        }
    }

    public enum Action: Equatable {
        case load([URL])
        case setShowing(Bool)
        case export(ExportFeature.Action)
    }

    public init() {
    }

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case let .load(urls):
                state.showing = true
                guard let url = urls.first else { return .none }
                return .task {
                    return .export(.requested(url: url))
                }
            case let .setShowing(showing):
                state.showing = showing
                return .none
            default:
                return .none
            }
        }
        Scope(state: \.exportState, action: /Action.export) {
            ExportFeature()
        }
    }

}

public struct AppFeatureView: View {

    let store: StoreOf<AppFeature>

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                Text("Paste a Mastodon Link, or try a sample Toot")
                Button("View a Sample") {
                    viewStore.send(.load([URL(string: "https://mastodon.social/@harshil/109572736506622176")!]))
                }
                .buttonStyle(.borderedProminent)
                PasteButton(payloadType: URL.self) { urls in
                    viewStore.send(.load(urls))
                }
            }
            .sheet(isPresented: viewStore.binding(get: \.showing, send: AppFeature.Action.setShowing)) {
                NavigationView {
                    ExportFeatureView(store: store.scope(state: \.exportState, action: AppFeature.Action.export))
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    viewStore.send(.setShowing(false))
                                }
                            }
                        }
                }
            }
        }
    }

}
