import ComposableArchitecture
import Foundation
import SwiftUI
import TootSniffer

public struct SettingsFeature: ReducerProtocol, Sendable {

    @Dependency(\.userDefaults) var userDefaults

    fileprivate struct PersistableState: Equatable, Sendable, Codable {
        var textColorData: Data?
        var backgroundColorData: Data?
        var showDate: Bool?
        var shareLink: Bool?
        var roundCorners: Bool?
        var imageStyle: ImageStyle?
    }

    public struct State: Equatable, Sendable {

        fileprivate var persistableState = PersistableState()

        public var textColor: Color {
            get {
                .whf_fromData(persistableState.textColorData) ?? .white
            }
            set {
                persistableState.textColorData = newValue.whf_data
            }
        }

        public var backgroundColor: Color {
            get {
                .whf_fromData(persistableState.backgroundColorData) ?? .black
            }
            set {
                persistableState.backgroundColorData = newValue.whf_data
            }
        }

        public var showDate: Bool {
            get { persistableState.showDate ?? true }
            set { persistableState.showDate = newValue }
        }

        public var shareLink: Bool {
            get { persistableState.shareLink ?? false }
            set { persistableState.shareLink = newValue }
        }

        public var roundCorners: Bool {
            get { persistableState.roundCorners ?? false }
            set { persistableState.roundCorners = newValue }
        }

        public var imageStyle: ImageStyle {
            get { persistableState.imageStyle ?? .grid }
            set { persistableState.imageStyle = newValue }
        }

        public init() {
        }

    }

    public enum ImageStyle: String, Equatable, Sendable, Codable, CaseIterable, Identifiable {
        case grid = "Grid"
        case stacked = "Stacked"
        case fan = "Fan"

        public var id: String {
            rawValue
        }

    }

    public enum Action: Equatable {
        case tappedDone
        case load
        case save
        case reset
        case showDateToggled(Bool)
        case roundCornersToggled(Bool)
        case imageStyleChanged(ImageStyle)
        case shareLinkToggled(Bool)
        case textColorModified(Color)
        case backgroundColorModified(Color)
    }

    public init() {
    }

    public var body: some ReducerProtocol<State, Action> {
        Reduce(internalReduce)
        Reduce(saveReduce)
    }

    public func internalReduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .load:
            guard let data = userDefaults.data(forKey: "settings") else { return .none }
            guard let loaded = try? JSONDecoder().decode(PersistableState.self, from: data) else { return .none }
            state.persistableState = loaded
            return .none
        case .save:
            guard let encoded = try? JSONEncoder().encode(state.persistableState) else { return .none }
            userDefaults.set(encoded, forKey: "settings")
            return .none
        case .reset:
            state.persistableState = PersistableState()
            return .none
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

    public func saveReduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .load, .save:
            return .none
        default:
            return .task {
                .save
            }
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
                           isOn: viewStore.binding(get: \.showDate, send: SettingsFeature.Action.showDateToggled).animation())
                    Toggle("Round Corners on Export",
                           isOn: viewStore.binding(get: \.roundCorners, send: SettingsFeature.Action.roundCornersToggled).animation())
                    Picker("Image Display", selection: viewStore.binding(get: \.imageStyle, send: SettingsFeature.Action.imageStyleChanged).animation()) {
                        ForEach(SettingsFeature.ImageStyle.allCases) { style in
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
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Reset") {
                            viewStore.send(.reset)
                        }
                    }
                }
            }
        }

    }

}

extension Color {

    var whf_data: Data {
        let uiColor = UIColor(self)
        return try! NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: true)
    }

    static func whf_fromData(_ data: Data?) -> Color? {
        guard let data, let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) else { return nil }
        return Color(uiColor: uiColor)
    }

}
