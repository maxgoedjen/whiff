import BlurHashKit
import ComposableArchitecture
import Foundation
import SwiftUI
import TootSniffer

public struct ExportFeature: ReducerProtocol, Sendable {

    @Dependency(\.tootSniffer) var tootSniffer
    @Dependency(\.imageRenderer) var imageRenderer
    @Dependency(\.imageLoader) var imageLoader
    @Dependency(\.authenticator) var authenticator
    @Dependency(\.mainQueue) var mainQueue

    public struct State: Equatable, Sendable {
        public var lastURL: URL?
        public var toot: Toot?
        public var tootContext: TootContext?
        public var attributedContent: [Toot.ID: UncheckedSendable<AttributedString>] = [:]
        public var errorMessage: String?
        public var rendered: ImageEquatable?
        public var showingSettings = false
        public var settings = SettingsFeature.State()
        public var images: [URLKey: ImageEquatable] = [:]
        public var visibleContextIDs: Set<Toot.ID> = []

        public var allToots: [Toot] {
            (tootContext?.ancestors ?? []) + [toot].compactMap { $0 } + (tootContext?.descendants ?? [])
        }

        public init() {
        }

        internal init(toot: Toot? = nil, tootContext: TootContext? = nil) {
            self.toot = toot
            self.tootContext = tootContext
            if let toot {
                visibleContextIDs = [toot.id]
            }
        }
    }

    public enum Action: Equatable {
        case requested(url: URL)
        case rerequest
        case tootSniffCompleted(TaskResult<Toot>)
        case tootSniffContextCompleted(TaskResult<TootContext>)
        case loadImageCompleted(TaskResult<ImageLoadResponse>)
        case tappedContextToot(Toot)
        case tappedSettings(Bool)
        case settings(SettingsFeature.Action)
        case rerendered(TaskResult<ImageEquatable>)
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
            state.lastURL = url
            state.errorMessage = nil
            state.toot = nil
            state.images = [:]
            state.attributedContent = [:]
            return .task {
                return .settings(.load)
            }
            .concatenate(with: .task {
                .tootSniffCompleted(await TaskResult { try await tootSniffer.sniff(url: url, authToken: authenticator.existingToken) })
            })
            .concatenate(with: .task {
                .tootSniffContextCompleted(await TaskResult { try await tootSniffer.sniffContext(url: url, authToken: authenticator.existingToken) })
            })
        case .rerequest:
            guard let url = state.lastURL else { return .none }
            return .task {
                .requested(url: url)
            }
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
        case .settings(.load):
            return .none
        case .tootSniffCompleted(.success), .loadImageCompleted(.success), .settings, .tappedContextToot:
            if let toot = state.toot, case .settings(.linkColorModified) = action {
                do {
                    state.attributedContent[toot.id] = UncheckedSendable(try attributedContent(from: toot, linkColor: state.settings.linkColor))
                } catch {
                    state.attributedContent[toot.id] = nil
                }
            }
            // We only need to rerender if the image that was loaded is included in the set of selected images.
            if case let .loadImageCompleted(.success(result)) = action {
                let visibleImages = state.allToots
                    .filter { state.visibleContextIDs.contains($0.id) }
                    .flatMap(\.allImages)
                    .map(\.displayURL)
                guard visibleImages.contains(result.url.url) else {
                    return .none

                }
            }
            return .task { [state] in
                .rerendered(
                    await TaskResult { @MainActor [state] in
                        try await imageRenderer.render(state: state)
                    }
                )
            }
            .debounce(id: "rerenderReduce", for: 0.01, scheduler: mainQueue)
        default:
            return .none
        }
    }

    func parseTootAndLoadAttachments(toot: Toot, state: inout State) -> EffectTask<Action> {
        do {
            state.attributedContent[toot.id] = UncheckedSendable(try attributedContent(from: toot, linkColor: state.settings.linkColor))
        } catch {
            state.attributedContent[toot.id] = nil
        }
        for attachment in toot.allImages {
            let url = attachment.displayURL
            if let blurhash = attachment.blurhash {
                let key = URLKey(url, .blurhash)
                let scaled = CGSize(width: 10.0, height: attachment.size.height * (10.0 / attachment.size.width))
                guard let image = BlurHash(string: blurhash)?.image(size: scaled) else { continue }
                state.images[key] = ImageEquatable(uiImage: image, equatableValue: blurhash)
            }
        }
        var effect = EffectTask<Action>.none
        for attachment in toot.allImages {
            let url = attachment.displayURL
            effect = effect.merge(with: EffectTask.task {
                .loadImageCompleted(await TaskResult {
                    let key = URLKey(url, .remote)
                    return ImageLoadResponse(key, try await imageLoader.loadImage(at: url))
                })
            })
        }
        return effect
    }

    func attributedContent(from toot: Toot, linkColor: Color) throws -> AttributedString {
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

        let uiLinkColor = UIColor(linkColor)
        nsAttributed.enumerateAttribute(.link, in: fullRange) { element, range, _ in
            guard element != nil else { return }
            nsAttributed.setAttributes([
                .foregroundColor: uiLinkColor,
            ], range: range)
        }

        // Uncomment to generate data for previews
//        print(try! NSKeyedArchiver.archivedData(withRootObject: nsAttributed, requiringSecureCoding: true))
        return AttributedString(nsAttributed)
    }

    public struct ImageLoadResponse: Equatable, Sendable {

        public let url: URLKey
        public let image: ImageEquatable

        internal init(_ url: URLKey, _ image: ImageEquatable) {
            self.url = url
            self.image = image
        }

        internal init(_ remoteURLString: String, _ image: ImageEquatable) {
            url = URLKey(URL(string: remoteURLString)!, .remote)
            self.image = image
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
                if let rootToot = viewStore.toot {
                    ZStack {
                        ScrollViewReader { value in
                            ScrollView {
                                VStack(alignment: .leading, spacing: 0) {
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
                                Spacer(minLength: 100)
                            }
                        }
                        LinearGradient(colors: [.clear, Color.black.opacity(0.5)], startPoint: UnitPoint(x: 0, y: 0.75), endPoint: UnitPoint(x: 0, y: 1))
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                        VStack {
                            Spacer()
                            if let rendered = viewStore.rendered?.image.value {
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
                    .padding()
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
