import ComposableArchitecture
import SwiftUI
import TootSniffer

public struct ExtensionFeature: ReducerProtocol, Sendable {

    @Dependency(\.dismissExtension) var dismissExtension

    public struct State: Equatable, Sendable {
        public var exportState = ExportFeature.State()

        public init() {
        }
    }

    public enum Action: Equatable {
        case tappedDone
        case dismissed
        case export(ExportFeature.Action)
    }

    public init() {
    }

    public var body: some ReducerProtocol<State, Action> {
        Reduce { _, action in
            switch action {
            case .tappedDone:
                return .task {
                    await dismissExtension(nil)
                    return .dismissed
                }
            case .dismissed:
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

public struct ExtensionFeatureView: View {

    let store: StoreOf<ExtensionFeature>

    public init(store: StoreOf<ExtensionFeature>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store) { viewStore in
            NavigationStack {
                ExportFeatureView(store: store.scope(state: \.exportState, action: ExtensionFeature.Action.export))
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                viewStore.send(.tappedDone)
                            }
                        }
                    }
                    .navigationTitle("Whiff")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }

}
