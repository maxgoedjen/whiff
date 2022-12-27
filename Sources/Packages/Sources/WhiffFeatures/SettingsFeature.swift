import ComposableArchitecture
import Foundation
@preconcurrency import SwiftUI
import TootSniffer

public struct SettingsFeature: ReducerProtocol, Sendable {

    public struct State: Equatable, Sendable {
        public var textColor: Color = .white
        public var backgroundColor: Color = .black
        public var showDate: Bool = true
        public var shareLink: Bool = false

        public var appearance: Appearance {
            Appearance(textColor: textColor, backgroundColor: backgroundColor)
        }

        public init() {
        }
    }

    public enum Action: Equatable {
        case showDateToggled(Bool)
        case shareLinkToggled(Bool)
        case textColorModified(Color)
        case backgroundColorModified(Color)
    }

    public init() {
    }

    public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .showDateToggled(show):
            state.showDate = show
            return .none
        case let .shareLinkToggled(share):
            state.shareLink = share
            return .none
        case let .textColorModified(color):
            state.textColor = color
            return .none
        case let .backgroundColorModified(color):
            state.backgroundColor = color
            return .none
        }
    }

}

public struct SettingsFeatureView: View {

    let store: StoreOf<SettingsFeature>

    public init(store: StoreOf<SettingsFeature>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                ColorPicker(selection: viewStore.binding(get: \.textColor, send: SettingsFeature.Action.textColorModified).animation(), supportsOpacity: false) {
                    Text("Text Color")
                }
                ColorPicker(selection: viewStore.binding(get: \.backgroundColor, send: SettingsFeature.Action.backgroundColorModified).animation(), supportsOpacity: false) {
                    Text("Background Color")
                }
                Toggle("Show Date",
                       isOn: viewStore.binding(get: \.showDate, send: SettingsFeature.Action.showDateToggled))
                Toggle("Share Link with Image",
                       isOn: viewStore.binding(get: \.shareLink, send: SettingsFeature.Action.shareLinkToggled))
                .hidden() // FIXME: This
            }
            .padding()
        }

    }

}
