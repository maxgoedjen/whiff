import SwiftUI

/// Wrapper view to deal with image loading and blurhash display.
struct ImageWrapperView: View {

    var image: ImageEquatable?
    var blurhash: ImageEquatable?
    var size: CGSize
    var contentMode: ContentMode

    var body: some View {
        Group {
            if let image {
                image
                    .image.value // FIXME: Gross
                    .resizable()
                    .aspectRatio(size, contentMode: contentMode)
            } else {
                if let blurhash {
                    blurhash
                        .image.value // FIXME: Gross
                        .resizable()
                        .aspectRatio(size, contentMode: contentMode)
                        .overlay {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                } else {
                    Rectangle()
                        .foregroundColor(.gray)
                        .overlay {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                        .aspectRatio(size, contentMode: .fit)
                }
            }

        }
    }

}
