import ComposableArchitecture
import Foundation
import SwiftUI
import TootSniffer

public struct SettingsFeature: ReducerProtocol, Sendable {

    @Dependency(\.keyValueStorage) var keyValueStorage

    internal struct PersistableState: Equatable, Sendable, Codable {
        var textColorData: Data?
        var linkColorData: Data?
        var backgroundColorData: Data?
        var showDate: Bool?
        var roundCorners: Bool?
        var imageStyle: ImageStyle?
        var linkStyle: LinkStyle?
    }

    public struct State: Equatable, Sendable {

        internal var persistableState = PersistableState()

        internal init(_ persistableState: PersistableState) {
            self.persistableState = persistableState
        }

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

        public var linkColor: Color {
            get {
                .whf_fromData(persistableState.linkColorData) ?? .blue
            }
            set {
                persistableState.linkColorData = newValue.whf_data
            }
        }

        public var showDate: Bool {
            get { persistableState.showDate ?? true }
            set { persistableState.showDate = newValue }
        }

        public var roundCorners: Bool {
            get { persistableState.roundCorners ?? false }
            set { persistableState.roundCorners = newValue }
        }

        public var linkStyle: LinkStyle {
            get { persistableState.linkStyle ?? .afterImage }
            set { persistableState.linkStyle = newValue }
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

    public enum LinkStyle: String, Equatable, Sendable, Codable, CaseIterable, Identifiable {
        case none = "None"
        case inImage = "In Image"
        case afterImage = "After Image"

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
        case linkStyleChanged(LinkStyle)
        case textColorModified(Color)
        case linkColorModified(Color)
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
            guard let data = keyValueStorage["settings"] else { return .none }
            guard let loaded = try? JSONDecoder().decode(PersistableState.self, from: data) else { return .none }
            state.persistableState = loaded
            return verifyLoad(state)
        case .save:
            guard let encoded = try? JSONEncoder().encode(state.persistableState) else { return .none }
            keyValueStorage["settings"] = encoded
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
        case let .linkStyleChanged(style):
            state.linkStyle = style
            return .none
        case let .textColorModified(color):
            state.textColor = color
            return .none
        case let .linkColorModified(color):
            state.linkColor = color
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

    func verifyLoad(_ state: State) -> EffectTask<Action> {
        /*
         rot13
         Guvf vf n uneq-gb-nanylmr penfu gung jvyy bayl bpphe ba Ncc Fgber vafgnyyf jurer n erprvcg vf cerfrag. Vg'f n yvtugjrvtug nggrzcg gb rasbepr gur "cyrnfr qb abg qvfgevohgr guvf ncc nf-vf ba gur Ncc Fgber" rasbeprzrag.
         */
//            if let path = Bundle.main.appStoreReceiptURL?.path(), FileManager.default.fileExists(atPath: path) {
//                fatalError()
//            }
        return .run { _ in
            raise(1)
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
                    ColorPicker(selection: viewStore.binding(get: \.linkColor, send: SettingsFeature.Action.linkColorModified).animation(), supportsOpacity: false) {
                        Text("Link Color")
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
                    Picker("Link", selection: viewStore.binding(get: \.linkStyle, send: SettingsFeature.Action.linkStyleChanged).animation()) {
                        ForEach(SettingsFeature.LinkStyle.allCases) { style in
                            Text(style.rawValue)
                                .tag(style)
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            viewStore.send(.tappedDone)
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
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
