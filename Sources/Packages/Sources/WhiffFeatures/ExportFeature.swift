import BlurHashKit
import ComposableArchitecture
import Foundation
@preconcurrency import SwiftUI
import TootSniffer

public struct ExportFeature: ReducerProtocol, Sendable {

    @Dependency(\.tootSniffer) var tootSniffer
    @Dependency(\.urlSession) var urlSession
    @Dependency(\.screenScale) var screenScale

    public struct State: Equatable, Sendable {
        public var toot: Toot?
        public var tootContext: TootContext?
        public var attributedContent: [Toot.ID: UncheckedSendable<AttributedString>] = [:]
        public var errorMessage: String?
        public var rendered: Image?
        public var showingSettings = false
        public var settings = SettingsFeature.State()
        public var images: [URLKey: Image] = [:]
        public var visibleContextIDs: Set<Toot.ID> = []

        public var allToots: [Toot] {
            (tootContext?.ancestors ?? []) + [toot].compactMap({ $0 }) + (tootContext?.descendants ?? [])
        }

        public init() {
        }
    }

    public enum Action: Equatable {
        case requested(url: URL)
        case tootSniffCompleted(TaskResult<Toot>)
        case tootSniffContextCompleted(TaskResult<TootContext>)
        case loadImageCompleted(TaskResult<ImageLoadResponse>)
        case tappedContextToot(Toot)
        case tappedSettings(Bool)
        case settings(SettingsFeature.Action)
        case rerendered(TaskResult<Image>)
    }

    public init() {
    }

    public var body: some ReducerProtocol<State, Action> {
        Scope(state: \.settings, action: /Action.settings) {
            SettingsFeature()
        }
        Reduce(internalReduce)
        Reduce(rerenderReduce)
    }

    public func internalReduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .requested(url):
            state.toot = nil
            state.images = [:]
            state.attributedContent = [:]
            return .task {
                return .settings(.load)
            }
            .concatenate(with: .task {
                .tootSniffCompleted(await TaskResult { try await tootSniffer.sniff(url: url) })
            })
            .concatenate(with: .task {
                .tootSniffContextCompleted(await TaskResult { try await tootSniffer.sniffContext(url: url) })
            })
        case let .tootSniffCompleted(.success(toot)):
            state.toot = toot
            state.visibleContextIDs.insert(toot.id)
            state.errorMessage = nil
            return parseTootAndLoadAttachments(toot: toot, state: &state)
        case let .tootSniffCompleted(.failure(error)):
            state.toot = nil
            if let localized = error as? LocalizedError, let message = localized.errorDescription {
                state.errorMessage = message
            } else {
                state.errorMessage = "Unknown Error"
            }
            return .none
        case let .tootSniffContextCompleted(.success(context)):
            state.tootContext = context
            var effect = EffectTask<Action>.none
            for toot in context.all {
                effect = effect.merge(with: parseTootAndLoadAttachments(toot: toot, state: &state))
            }
            return effect.animation()
        case .tootSniffContextCompleted(.failure):
            return .none
        case let .loadImageCompleted(.success(response)):
            state.images[response.url] = response.image
            return .none
        case let .loadImageCompleted(.failure(error)):
            print(error)
            return .none
        case let .tappedContextToot(toot):
            guard toot != state.toot else { return .none }
            if state.visibleContextIDs.contains(toot.id) {
                state.visibleContextIDs.remove(toot.id)
            } else {
                state.visibleContextIDs.insert(toot.id)
            }
            return .none
        case let .tappedSettings(showing):
            state.showingSettings = showing
            return .none
        case let .settings(action):
            if case .tappedDone = action {
                state.showingSettings = false
            }
            return .none
        case .rerendered(.failure):
            state.rendered = nil
            return .none
        case let .rerendered(.success(image)):
            state.rendered = image
            return .none
        }
    }

    public func rerenderReduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .tootSniffCompleted, .loadImageCompleted, .settings, .tappedContextToot:
            if let toot = state.toot, case .settings(.linkColorModified) = action {
                do {
                    state.attributedContent[toot.id] = UncheckedSendable(try attributedContent(from: toot, tint: state.settings.linkColor))
                } catch {
                    state.attributedContent[toot.id] = nil
                }
            }
            return .task { [state] in
                try await rerenderTask(state: state)
            }
        default:
            return .none
        }
    }

    private func rerenderTask(state: State) async throws -> Action {
        .rerendered(
            await TaskResult { @MainActor in
                guard state.toot != nil else {
                    throw UnableToRender()
                }

                let view = VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(zip(state.allToots, state.allToots.indices)), id: \.0.id) { item in
                        let (toot, idx) = item
                        if state.visibleContextIDs.contains(toot.id) {
                            TootView(
                                toot: toot,
                                attributedContent: state.attributedContent[toot.id]?.value,
                                images: state.images,
                                settings: state.settings
                            )
                            .frame(width: 400)
                        }
                        if idx < (state.allToots.count - 1) {
                            // Divider doesn't work well in ImageRenderer
                            Rectangle()
                                .foregroundColor(.gray.opacity(0.25))
                                .frame(height: 2)
                        }
                    }
                }
                    .background(state.settings.backgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: state.settings.roundCorners ? 15 : 0))

                let renderer =
                    ImageRenderer(content: view)
                renderer.scale = screenScale
                guard let image = renderer.uiImage else {
                    throw UnableToRender()
                }
                return Image(uiImage: image)
            }
        )
    }

    func parseTootAndLoadAttachments(toot: Toot, state: inout State) -> EffectTask<Action> {
        do {
            state.attributedContent[toot.id] = UncheckedSendable(try attributedContent(from: toot, tint: state.settings.linkColor))
        } catch {
            state.attributedContent[toot.id] = nil
        }
        for attachment in toot.allImages {
            let url = attachment.url
            if let blurhash = attachment.blurhash {
                let key = URLKey(url, .blurhash)
                let scaled = CGSize(width: 10.0, height: attachment.size.height * (10.0 / attachment.size.width))
                guard let image = BlurHash(string: blurhash)?.image(size: scaled) else { continue }
                state.images[key] = Image(uiImage: image)
            }
        }
        var effect = EffectTask<Action>.none
        for attachment in toot.allImages {
            let url = attachment.url
            effect = effect.merge(with: EffectTask.task {
                .loadImageCompleted(await TaskResult {
                    let key = URLKey(url, .remote)
                    let (data, _) = try await urlSession.data(from: url)
                    guard let image = UIImage(data: data) else { throw UnableToParseImage() }
                    return ImageLoadResponse(key, Image(uiImage: image))
                })
            })
        }
        return effect
    }

    func attributedContent(from toot: Toot, tint: Color) throws -> AttributedString {
        // Gotta be unicode, not utf8
        let nsAttributed = try NSMutableAttributedString(
            data: toot.content.data(using: .unicode)!,
            options: [.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil
        )
        let fullRange = NSRange(location: 0, length: nsAttributed.length)
        nsAttributed.removeAttribute(.foregroundColor, range: fullRange)
        nsAttributed.removeAttribute(.font, range: fullRange)
        nsAttributed.removeAttribute(.kern, range: fullRange)
        nsAttributed.removeAttribute(.paragraphStyle, range: fullRange)
        nsAttributed.removeAttribute(.strokeWidth, range: fullRange)
        nsAttributed.removeAttribute(.strokeColor, range: fullRange)

        let tint = UIColor(tint)
        nsAttributed.enumerateAttribute(.link, in: fullRange) { element, range, _ in
            guard element != nil else { return }
            nsAttributed.setAttributes([.foregroundColor: tint], range: range)
        }

        // Uncomment to generate data for previews
//        print(try! NSKeyedArchiver.archivedData(withRootObject: nsAttributed, requiringSecureCoding: true))
        return AttributedString(nsAttributed)
    }

    public struct ImageLoadResponse: Equatable, Sendable {

        public let url: URLKey
        public let image: Image

        internal init(_ url: URLKey, _ image: Image) {
            self.url = url
            self.image = image
        }

    }

    struct UnableToParseImage: Error {
    }

    struct UnableToRender: Error {
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
                if let rootToot = viewStore.toot {
                    ZStack {
                        ScrollViewReader { value in
                            ScrollView {
                                VStack(spacing: 0) {
                                    ForEach(Array(zip(viewStore.allToots, viewStore.allToots.indices)), id: \.0.id) { item in
                                        let (toot, idx) = item
                                        TootView(
                                            toot: toot,
                                            attributedContent: viewStore.attributedContent[toot.id]?.value,
                                            images: viewStore.images,
                                            settings: viewStore.settings
                                        )
                                        .opacity(viewStore.visibleContextIDs.contains(toot.id) ? 1 : 0.2)
                                        .onTapGesture {
                                            viewStore.send(.tappedContextToot(toot), animation: .easeInOut(duration: 0.2))
                                        }
                                        .id(toot.id)
                                        if idx < (viewStore.allToots.count - 1) {
                                            // Divider doesn't work well in ImageRenderer
                                            Rectangle()
                                                .foregroundColor(.gray.opacity(0.25))
                                                .frame(height: 2)
                                        }
                                    }
                                }
                                .onAppear {
                                    value.scrollTo(rootToot.id, anchor: UnitPoint(x: 0.5, y: 0.2))
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 15)
                                    .stroke(.white.opacity(0.25), lineWidth: 3)
                                }
                                .padding()
                                if let ancestors = viewStore.tootContext?.ancestors, !ancestors.isEmpty {
                                    // Empty view that on appear scrolls, to that if we load in context above the root toot, it doesn't suddenly jump to that.
                                    // Can't literally be EmptyView because that doesn't fire onAppear
                                    Spacer(minLength: 0)
                                        .onAppear {
                                            value.scrollTo(rootToot.id, anchor: UnitPoint(x: 0.5, y: 0.0375))
                                        }
                                }
                                Spacer(minLength: 100)
                            }
                        }
                        LinearGradient(colors: [.clear, Color.black.opacity(0.5)], startPoint: UnitPoint(x: 0, y: 0.75), endPoint: UnitPoint(x: 0, y: 1))
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                        VStack {
                            Spacer()
                            if let rendered = viewStore.rendered {
                                if case .afterImage = viewStore.settings.linkStyle {
                                    ShareLink(item: rendered, message: Text(rootToot.url.absoluteString), preview: SharePreview("Rendered Toot"))
                                        .buttonStyle(BigCapsuleButton())
                                } else {
                                    ShareLink(item: rendered, preview: SharePreview("Rendered Toot"))
                                        .buttonStyle(BigCapsuleButton())
                                }
                            } else {
                                ShareLink(item: "")
                                    .buttonStyle(BigCapsuleButton())
                                    .disabled(true)
                            }
                        }
                    }
                    .navigationTitle("Toot from \(rootToot.account.displayName)")
                    .navigationBarTitleDisplayMode(.inline)
                    .sheet(isPresented: viewStore.binding(get: \.showingSettings, send: ExportFeature.Action.tappedSettings)) {
                        SettingsFeatureView(store: store.scope(state: \.settings, action: ExportFeature.Action.settings))
                            .presentationDetents([.medium])
                    }
                } else if let error = viewStore.errorMessage {
                    VStack {
                        Text("Error")
                            .font(.headline)
                        Text(error)
                    }
                } else {
                    VStack {
                        TootView(toot: .placeholder, attributedContent: nil, images: [:], settings: viewStore.settings)
                            .redacted(reason: .placeholder)
                            .cornerRadius(15)
                            .overlay {
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(.white.opacity(0.25), lineWidth: 3)
                            }
                            .padding()
                        Spacer()
                    }
                    .navigationTitle("Loading Toot")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewStore.send(.tappedSettings(true))
                    } label: {
                        Image(systemName: "paintbrush")
                    }

                }
            }

        }

    }

}
