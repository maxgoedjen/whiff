import BlurHashKit
import SwiftUI
import TootSniffer

/// View that renderes the content of a card.
struct CardView: View {

    /// The card to display.
    let card: Card
    /// The loaded images for the post.
    let images: [URLKey: ImageEquatable]

    var body: some View {
        VStack(spacing: 0) {
            if let image = card.image {
                ImageWrapperView(image: images[URLKey(image, .remote)], blurhash: images[URLKey(image, .remote)], size: CGSize(width: card.width, height: card.height), contentMode: .fit, type: .image)
                    .frame(maxWidth: .infinity)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(card.title)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                if let description = card.description {
                    Text(description)
                        .font(.system(.body, design: .rounded, weight: .regular))
                }
                if let url = card.url {
                    Text(url.absoluteString)
                        .font(.system(.footnote, design: .rounded, weight: .regular))
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Material.thin)
        }
        .cornerRadius(10)
    }

}
