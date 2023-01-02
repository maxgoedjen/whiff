import ComposableArchitecture
import SwiftUI

public protocol ImageRendererProtocol: Sendable {

    @MainActor func render(state: ExportFeature.State) async throws -> Image

}

public final class ImageRendererSwiftUI: ImageRendererProtocol {

    public func render(state: ExportFeature.State) async throws -> Image {
        guard state.toot != nil else {
            throw UnableToRenderError()
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
        renderer.scale = UIScreen.main.scale
        guard let image = renderer.uiImage else {
            throw UnableToRenderError()
        }
        return Image(uiImage: image)
    }
}

public final class UnimplementedImageRenderer: ImageRendererProtocol {

    public func render(state: ExportFeature.State) async throws -> Image {
        fatalError()
    }

}

struct UnableToParseImageError: Error, Equatable {
    init() {
    }
}

struct UnableToRenderError: Error, Equatable {
}
