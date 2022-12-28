import ComposableArchitecture
import Foundation
@preconcurrency import SwiftUI
import TootSniffer

public struct SettingsFeature: ReducerProtocol, Sendable {

    @Dependency(\.userDefaults) var userDefaults

    public struct State: Equatable, Sendable {
        public var textColor: Color = .white
        public var backgroundColor: Color = .black
        public var showDate: Bool = true
        public var shareLink: Bool = false
        public var roundCorners: Bool = false
        public var imageStyle: ImageStyle = .grid

        public init() {
        }

        fileprivate enum StorageKey: String, CaseIterable {
            case textColor
            case backgroundColor
            case showDate
            case shareLink
            case roundCorners
            case imageStyle
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
        case load
        case save
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
        case .load:
            loadBool(key: .showDate, into: &state)
            loadBool(key: .roundCorners, into: &state)
            loadBool(key: .shareLink, into: &state)
            loadColor(key: .textColor, into: &state)
            loadColor(key: .backgroundColor, into: &state)
            return .none
        case .save:
            saveBool(key: .showDate, from: state)
            saveBool(key: .roundCorners, from: state)
            saveBool(key: .shareLink, from: state)
            saveColor(key: .textColor, from: state)
            saveColor(key: .backgroundColor, from: state)
            return .none
        case .tappedDone:
            return .none
        case let .showDateToggled(show):
            state.showDate = show
            return .task {
                .save
            }
        case let .roundCornersToggled(round):
            state.roundCorners = round
            return .task {
                .save
            }
        case let .imageStyleChanged(style):
            state.imageStyle = style
            return .task {
                .save
            }
        case let .shareLinkToggled(share):
            state.shareLink = share
            return .task {
                .save
            }
        case let .textColorModified(color):
            state.textColor = color
            return .task {
                .save
            }
        case let .backgroundColorModified(color):
            state.backgroundColor = color
            return .task {
                .save
            }
        }
    }

    fileprivate func loadBool(key: State.StorageKey, into state: inout State) {
        guard let loaded = userDefaults.value(forKey: key.rawValue) as? Bool else { return }
        switch key {
        case .showDate:
            state.showDate = loaded
        case .shareLink:
            state.shareLink = loaded
        case .roundCorners:
            state.roundCorners = loaded
        default:
            break
        }
    }

    fileprivate func loadColor(key: State.StorageKey, into state: inout State) {
        guard let data = userDefaults.data(forKey: key.rawValue),
              let uiColor = try? NSKeyedUnarchiver(forReadingFrom: data).decodeObject(of: UIColor.self, forKey: "color")
        else { return }
        let loaded = Color(uiColor: uiColor)
        switch key {
        case .textColor:
            state.textColor = loaded
        case .backgroundColor:
            state.backgroundColor = loaded
        default:
            break
        }
    }

    fileprivate func saveBool(key: State.StorageKey, from state: State) {
        switch key {
        case .showDate:
            userDefaults.set(state.showDate, forKey: key.rawValue)
        case .shareLink:
            userDefaults.set(state.shareLink, forKey: key.rawValue)
        case .roundCorners:
            userDefaults.set(state.roundCorners, forKey: key.rawValue)
        default:
            break
        }
    }

    fileprivate func saveColor(key: State.StorageKey, from state: State) {
        let color: Color
        switch key {
        case .textColor:
            color = state.textColor
        case .backgroundColor:
            color = state.backgroundColor
        default:
            return
        }
        guard let cgColor = color.cgColor else { return }
        let uiColor = UIColor(cgColor: cgColor)
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        archiver.encode(uiColor, forKey: "color")
        userDefaults.set(archiver.encodedData, forKey: key.rawValue)
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
                           isOn: viewStore.binding(get: \.showDate, send: SettingsFeature.Action.showDateToggled).animation())
                    Toggle("Round Corners on Export",
                           isOn: viewStore.binding(get: \.roundCorners, send: SettingsFeature.Action.roundCornersToggled).animation())
                    Picker("Image Display", selection: viewStore.binding(get: \.imageStyle, send: SettingsFeature.Action.imageStyleChanged).animation()) {
                        ForEach(SettingsFeature.State.ImageStyle.allCases) { style in
                            Text(style.rawValue)
                                .tag(style)
                        }
                    }
                    Toggle("Share Link with Image",
                           isOn: viewStore.binding(get: \.shareLink, send: SettingsFeature.Action.shareLinkToggled))
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
