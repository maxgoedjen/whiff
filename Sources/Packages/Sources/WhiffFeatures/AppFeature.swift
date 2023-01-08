import ComposableArchitecture
import SwiftUI
import TootSniffer

public struct AppFeature: ReducerProtocol, Sendable {

    public struct State: Equatable, Sendable {
        public var showingExport = false
        public var showingAuthentication = false
        public var exportState = ExportFeature.State()

        public init() {
        }

        internal init(showingExport: Bool = false, showingAuthentication: Bool = false, exportState: ExportFeature.State = ExportFeature.State()) {
            self.showingExport = showingExport
            self.exportState = exportState
            self.showingAuthentication = showingAuthentication
        }
    }

    public enum Action: Equatable {
        case load([URL])
        case setShowingExport(Bool)
        case setShowingAuthentication(Bool)
        case export(ExportFeature.Action)
    }

    public init() {
    }

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case let .load(urls):
                guard let url = urls.first else { return .none }
                state.showingExport = true
                return .task {
                    return .export(.requested(url: url))
                }
            case let .setShowingExport(showingExport):
                state.showingExport = showingExport
                state.exportState = ExportFeature.State()
                return .none
            case let .setShowingAuthentication(showingAuthentication):
                state.showingAuthentication = showingAuthentication
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
                .buttonStyle(BigCapsuleButton())
                PasteButtonThreadSafe(payloadType: URL.self) { urls in
                    viewStore.send(.load(urls))
                }
                .buttonStyle(BigCapsuleButton())
            }
            .sheet(isPresented: viewStore.binding(get: \.showingExport, send: AppFeature.Action.setShowingExport)) {
                NavigationStack {
                    ExportFeatureView(store: store.scope(state: \.exportState, action: AppFeature.Action.export))
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    viewStore.send(.setShowingExport(false))
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: viewStore.binding(get: \.showingAuthentication, send: AppFeature.Action.setShowingAuthentication)) {
                NavigationStack {
                    ExportFeatureView(store: store.scope(state: \.exportState, action: AppFeature.Action.export))
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    viewStore.send(.setShowingExport(false))
                                }
                            }
                        }
                }
            }
        }
    }

}
