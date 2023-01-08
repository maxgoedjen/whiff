import ComposableArchitecture
import SwiftUI
import TootSniffer

public struct AuthenticationFeature: ReducerProtocol, Sendable {

    @Dependency(\.authenticator) var authenticator

    public struct State: Equatable, Sendable {

        var loggedIn = false
        var domain: String = ""
        var buttonDisabled = true

        public init() {
        }

    }

    public enum Action: Equatable {
        case onAppear
        case setDomain(String)
        case begin
        case response(TaskResult<String>)
        case logout
    }

    public init() {
    }

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.loggedIn = authenticator.loggedIn
                return .none
            case let .setDomain(domain):
                state.domain = domain
                state.buttonDisabled = domain.isEmpty
                return .none
            case .begin:
                state.domain = state.domain
                    .replacing("http://", with: "")
                    .replacing("https://", with: "")
                return .task { [host = state.domain] in
                    .response(await TaskResult {
                        try await authenticator.obtainOAuthToken(from: host)
                    })
                }
            case .response(.success):
                state.loggedIn = true
                return .none
            case .response(.failure):
                state.loggedIn = false
                return .none
            case .logout:
                state.loggedIn = false
                authenticator.logout()
                return .none
            }
        }
    }

}

public struct AuthenticationFeatureView: View {

    let store: StoreOf<AuthenticationFeature>

    public init(store: StoreOf<AuthenticationFeature>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store) { viewStore in
            Group {
                if viewStore.loggedIn {
                    Text("You're Logged In")
                        .font(.title2)
                    Button("Log Out") {
                        viewStore.send(.logout)
                    }
                    .buttonStyle(BigCapsuleButton())
                } else {
                    Form {
                        Section("Your Mastodon Domain") {
                            TextField("Your Mastodon Domain", text: viewStore.binding(get: \.domain, send: AuthenticationFeature.Action.setDomain), prompt: Text("mastodon.social"))
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                    }
                    Button("Log In") {
                        viewStore.send(.begin)
                    }
                    .buttonStyle(BigCapsuleButton())
                    .disabled(viewStore.buttonDisabled)
                }
            }
            .padding()
                .onAppear {
                    viewStore.send(.onAppear)
                }
        }
    }

}
