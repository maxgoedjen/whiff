import SwiftUI
import TootSniffer

/// Wrapper view to deal with image loading and blurhash display.
/// Also deals with displaying non-image media types by falling back to blur hash.
struct ImageWrapperView: View {

    let image: ImageEquatable?
    let blurhash: ImageEquatable?
    let size: CGSize
    let contentMode: ContentMode
    let type: MediaAttachment.MediaType

    var body: some View {
        Group {
            if let image {
                image
                    .image.value // FIXME: Gross
                    .resizable()
                    .aspectRatio(size, contentMode: contentMode)
                    .overlay {
                        switch type {
                        case .image, .unknown:
                            EmptyView()
                        case .video, .gifv:
                            ZStack {
                                Rectangle()
                                    .foregroundColor(.black.opacity(0.2))
                                Image(systemName: "play.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 25)
                            }
                        case .audio:
                            ZStack {
                                Rectangle()
                                    .foregroundColor(.black.opacity(0.2))
                                Image(systemName: "speaker.wave.2.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 25)
                            }
                        }
                    }
            } else {
                loadingBody
                    .overlay {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    .aspectRatio(size, contentMode: .fit)
            }

        }
    }

    @ViewBuilder var loadingBody: some View {
        if let blurhash {
            blurhash
                .image.value // FIXME: Gross
                .resizable()
                .aspectRatio(size, contentMode: contentMode)
        } else {
            Rectangle()
                .foregroundColor(.gray)
        }

    }

}
