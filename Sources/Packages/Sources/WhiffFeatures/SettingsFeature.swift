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
        public var roundCorners: Bool = false
        public var imageStyle: ImageStyle = .grid

        public init() {
        }

        public enum ImageStyle: String, Equatable, Sendable, CaseIterable, Identifiable {
            case grid = "Grid"
            case stacked = "Stacked"
            case fan = "Fan"

            public var id: String {
                rawValue
            }

        }
    }
    

    public enum Action: Equatable {
        case tappedDone
        case showDateToggled(Bool)
        case roundCornersToggled(Bool)
        case imageStyleChanged(State.ImageStyle)
        case shareLinkToggled(Bool)
        case textColorModified(Color)
        case backgroundColorModified(Color)
    }

    public init() {
    }

    public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .tappedDone:
            return .none
        case let .showDateToggled(show):
            state.showDate = show
            return .none
        case let .roundCornersToggled(round):
            state.roundCorners = round
            return .none
        case let .imageStyleChanged(style):
            state.imageStyle = style
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
            NavigationView {
                List {
                    ColorPicker(selection: viewStore.binding(get: \.textColor, send: SettingsFeature.Action.textColorModified).animation(), supportsOpacity: false) {
                        Text("Text Color")
                    }
                    ColorPicker(selection: viewStore.binding(get: \.backgroundColor, send: SettingsFeature.Action.backgroundColorModified).animation(), supportsOpacity: false) {
                        Text("Background Color")
                    }
                    Toggle("Show Date",
                           isOn: viewStore.binding(get: \.showDate, send: SettingsFeature.Action.showDateToggled))
                    Toggle("Round Corners on Export",
                           isOn: viewStore.binding(get: \.roundCorners, send: SettingsFeature.Action.roundCornersToggled))
                    Picker("Image Display", selection: viewStore.binding(get: \.imageStyle, send: SettingsFeature.Action.imageStyleChanged)) {
                        ForEach(SettingsFeature.State.ImageStyle.allCases) { style in
                            Text(style.rawValue)
                                .tag(style)
                        }
                    }
//                    Toggle("Share Link with Image",
//                           isOn: viewStore.binding(get: \.shareLink, send: SettingsFeature.Action.shareLinkToggled))
                    // FIXME: This
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            viewStore.send(.tappedDone)
                        }
                    }
                }
            }
        }

    }

}
