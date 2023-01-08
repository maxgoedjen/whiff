import ComposableArchitecture
import SwiftUI
import TootSniffer
import AuthenticationServices

public struct AuthenticationFeature: ReducerProtocol, Sendable {

    public struct State: Equatable, Sendable {

        var domain: String = ""
        var buttonDisabled = true
        let contextBridge = WebAuthenticationContextBridge()

        public init() {
        }

    }

    public enum Action: Equatable {
        case setDomain(String)
        case authenticate
        case response(TaskResult<URL>)
    }

    public init() {
    }

    public var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case let .setDomain(domain):
                state.domain = domain
                state.buttonDisabled = domain.isEmpty
                return .none
            case .authenticate:
                state.domain = state.domain
                    .replacing("http://", with: "")
                    .replacing("https://", with: "")
                // example.com host will be rewritten below
                var urlComponents = URLComponents(string: "https://example.com/oauth/authorize?response_type=code&client_id=cwlwRcvt6c2uS4qDnEddHJQPqyTs29t3qWct6-xMKCI&redirect_uri=whiff://auth_redirect&scope=read:statuses")!
                urlComponents.host = state.domain
                let url = urlComponents.url!
                return .task { [context = state.contextBridge] in
                    .response(await TaskResult {
                        try await withCheckedThrowingContinuation { continuation in
                            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "whiff", completionHandler: { url, error in
                                if let error {
                                    continuation.resume(throwing: error)
                                } else {
                                    continuation.resume(returning: url!)
                                }
                            })
                            session.presentationContextProvider = context
                            session.start()
                        }
                    })

                }
            case let .response(.success(value)):
print(value)
                return .none
            case let .response(.failure(error)):
                print(error)
                return .none
            }
        }
    }

}

public final class WebAuthenticationContextBridge: NSObject, ASWebAuthenticationPresentationContextProviding, Sendable {

    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        DispatchQueue.main.sync {
            ASPresentationAnchor()
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
                Form {
                    Section("Your Mastodon Domain") {
                        TextField("Your Mastodon Domain", text: viewStore.binding(get: \.domain, send: AuthenticationFeature.Action.setDomain), prompt: Text("mastodon.social"))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }
                Button("Log In") {
                    viewStore.send(.authenticate)
                }
                .buttonStyle(BigCapsuleButton())
                .disabled(viewStore.buttonDisabled)
            }.padding()
        }
    }

}

//public struct WebAuthenticationSessionView: UIViewControllerRepresentable {
//
//}
