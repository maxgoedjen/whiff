import SwiftUI

struct ImageWrapperView: View {

    var image: Image?
    var blurhash: Image?
    var size: CGSize
    var contentMode: ContentMode

    var body: some View {
        Group {
            if let image {
                image
                    .resizable()
                    .aspectRatio(size, contentMode: contentMode)
            } else {
                if let blurhash {
                    blurhash
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
