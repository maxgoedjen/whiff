import ComposableArchitecture
import Foundation
import SwiftUI
import TootSniffer

public struct ExportFeature: ReducerProtocol, Sendable {

    public struct State: Equatable, Sendable {
        public var toot: Toot?

        public init() {
        }
    }

    public enum Action: Equatable {
        case task
    }

    public init() {
    }

    public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        .none
    }

}

public struct ExportFeatureView: View {

    let store: StoreOf<ExportFeature>

    public init(store: StoreOf<ExportFeature>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store) { _ in
            Text("Hello")
        }
    }

}
