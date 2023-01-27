import ComposableArchitecture
import SwiftUI
import TootSniffer

public struct ExtensionFeature: ReducerProtocol, Sendable {

    @Dependency(\.authenticator) var authenticator
    @Dependency(\.dismissExtension) var dismissExtension

    public struct State: Equatable, Sendable {
        public var exportState = ExportFeature.State()
        public var authenticationState = AuthenticationFeature.State()
        public var loggedIn = false
        public var showingAuthentication = false

        public init() {
        }
    }

    public enum Action: Equatable {
        case onAppear
        case tappedDone
        case dismissed
        case setShowingAuthentication(Bool)
        case export(ExportFeature.Action)
        case authenticate(AuthenticationFeature.Action)
    }

    public init() {
    }

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.loggedIn = authenticator.loggedIn
                return .none
            case .tappedDone:
                return .task {
                    await dismissExtension(nil)
                    return .dismissed
                }
            case .dismissed:
                return .none
            case let .setShowingAuthentication(showingAuthentication):
                state.showingAuthentication = showingAuthentication
                return .none
            case .authenticate(.response(.success)):
                state.loggedIn = true
                state.showingAuthentication = false
                return .send(.export(.rerequest))
            case .export(.tappedLogin):
                state.showingAuthentication = true
                return .none
            default:
                return .none
            }
        }
        Scope(state: \.exportState, action: /Action.export) {
            ExportFeature()
        }
        Scope(state: \.authenticationState, action: /Action.authenticate) {
            AuthenticationFeature()
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
            .onAppear {
                viewStore.send(.onAppear)
            }
            .sheet(isPresented: viewStore.binding(get: \.showingAuthentication, send: ExtensionFeature.Action.setShowingAuthentication)) {
                NavigationStack {
                    AuthenticationFeatureView(store: store.scope(state: \.authenticationState, action: ExtensionFeature.Action.authenticate))
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    viewStore.send(.setShowingAuthentication(false))
                                }
                            }
                        }
                }
            }
        }
    }

}
