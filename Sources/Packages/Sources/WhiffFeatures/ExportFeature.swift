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

        public init() {
        }
    }

    public enum Action: Equatable {
        case requested(url: URL)
        case tootSniffCompleted(TaskResult<Toot>)
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
                .tootSniffCompleted(await TaskResult { try await tootSniffer.sniff(url: url)} )
            }
        case let .tootSniffCompleted(.success(toot)):
            state.toot = toot
            return .none
        case let .tootSniffCompleted(.failure(error)):
            state.toot = nil
            print(error)
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
                    TootView(toot: toot)
                } else {
                    VStack {
                        Text("Loading Toot")
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
            }
            .task {
                viewStore.send(.requested(url: URL(string: "https://mstdn.social/@lolennui/109547842480496094")!))
            }
        }
        
    }

}
