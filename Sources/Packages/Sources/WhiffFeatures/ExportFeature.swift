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

        public init() {
        }
    }

    public enum Action: Equatable {
        case requested(url: URL)
        case tootSniffCompleted(TaskResult<Toot>)
        case tootSniffContextCompleted(TaskResult<TootContext>)
        case loadImageCompleted(TaskResult<ImageLoadResponse>)
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
            return effect
        case .tootSniffContextCompleted(.failure):
            return .none
        case let .loadImageCompleted(.success(response)):
            state.images[response.url] = response.image
            return .none
        case let .loadImageCompleted(.failure(error)):
            print(error)
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
        case .tootSniffCompleted, .loadImageCompleted, .settings:
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
                guard let toot = state.toot else {
                    throw UnableToRender()
                }
                let renderer =
                    ImageRenderer(content: ScreenshotView(toot: toot, attributedContent: state.attributedContent[toot.id]?.value, images: state.images, settings: state.settings))
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

struct ScreenshotView: View {

    let toot: Toot
    let attributedContent: AttributedString?
    let images: [URLKey: Image]
    let settings: SettingsFeature.State

    var body: some View {
        TootView(toot: toot, attributedContent: attributedContent, images: images, settings: settings)
            .frame(width: 400)
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
                    ZStack {
                        ScrollViewReader { value in
                            ScrollView {
                                ForEach(viewStore.tootContext?.ancestors ?? []) { ancestor in
                                    TootView(
                                        toot: ancestor,
                                        attributedContent: viewStore.attributedContent[ancestor.id]?.value,
                                        images: viewStore.images,
                                        settings: viewStore.settings
                                    )
                                    .cornerRadius(15)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(.white.opacity(0.5), lineWidth: 3)
                                    }
                                    .padding()
                                }
                                .onAppear {
                                    value.scrollTo("Canonical", anchor: .top)
                                }
                                TootView(toot: toot, attributedContent: viewStore.attributedContent[toot.id]?.value, images: viewStore.images, settings: viewStore.settings)
                                    .cornerRadius(15)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(.white.opacity(0.5), lineWidth: 3)
                                    }
                                    .padding()
                                    .id("Canonical")
                                ForEach(viewStore.tootContext?.descendants ?? []) { descendant in
                                    TootView(
                                        toot: descendant,
                                        attributedContent: viewStore.attributedContent[descendant.id]?.value,
                                        images: viewStore.images,
                                        settings: viewStore.settings
                                    )
                                    .cornerRadius(15)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(.white.opacity(0.5), lineWidth: 3)
                                    }
                                    .padding()
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
                                    ShareLink(item: rendered, message: Text(toot.url.absoluteString), preview: SharePreview("Rendered Toot"))
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
                                    .stroke(.white.opacity(0.5), lineWidth: 3)
                            }
                            .padding()
                        Text("Loading Toot")
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
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
