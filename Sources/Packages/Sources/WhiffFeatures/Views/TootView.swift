import BlurHashKit
import SwiftUI
import TootSniffer

/// View that renderes the content of a post.
struct TootView: View {

    /// The post to display.
    let toot: Toot

    /// Parsed AttributedContent object for the post (usually includes parsed links/hashtags).
    let attributedContent: AttributedString?

    /// The loaded images for the post.
    let images: [URLKey: ImageEquatable]

    /// Settings for how the post should be displayed.
    let settings: SettingsFeature.State

    var content: some View {
        Group {
            if let attributedContent {
                Text(attributedContent)
                    .foregroundColor(settings.textColor)
                    .font(.system(.title3, design: .rounded, weight: .regular))
            } else {
                Text(toot.content)
                    .foregroundColor(settings.textColor)
                    .font(.system(.title3, design: .rounded, weight: .regular))
            }
        }

    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TooterView(
                tooter: toot.account,
                images: images,
                settings: settings
            )
            switch settings.imageStyle {
            case .grid:
                content
                HStack {
                    ForEach(toot.mediaAttachments) { attachment in
                        ImageWrapperView(
                            image: images[URLKey(attachment.displayURL, .remote)],
                            blurhash: images[URLKey(attachment.displayURL, .blurhash)],
                            size: attachment.size,
                            contentMode: .fit,
                            type: attachment.type
                        )
                    }
                }
            case .stacked:
                content
                VStack(spacing: 5) {
                    ForEach(toot.mediaAttachments) { attachment in
                        ImageWrapperView(
                            image: images[URLKey(attachment.displayURL, .remote)],
                            blurhash: images[URLKey(attachment.displayURL, .blurhash)],
                            size: attachment.size,
                            contentMode: .fill,
                            type: attachment.type
                        )
                    }
                }
            case .fan:
                HStack {
                    content
                    Spacer(minLength: 0)
                    ZStack {
                        ForEach(Array(zip(toot.mediaAttachments.indices, toot.mediaAttachments)), id: \.0) { idx, attachment in
                            ImageWrapperView(
                                image: images[URLKey(attachment.displayURL, .remote)],
                                blurhash: images[URLKey(attachment.displayURL, .blurhash)],
                                size: attachment.size,
                                contentMode: .fit,
                                type: attachment.type
                            )
                            .frame(maxWidth: 50)
                            .border(.white, width: 1)
                            .shadow(radius: 5)
                            .rotationEffect(Angle(degrees: Double(idx)) * 10 * (idx % 2 == 0 ? 1 : -1))
                        }
                    }
                }
            }
            if settings.showDate {
                Text(toot.createdAt.formatted())
                    .foregroundColor(settings.textColor)
                    .font(.system(.footnote, design: .rounded, weight: .regular))
            }
            if case .inImage = settings.linkStyle {
                Text(toot.url.absoluteString)
                    .foregroundColor(settings.textColor)
                    .font(.system(.footnote, design: .rounded, weight: .regular))
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity)
        .background(settings.backgroundColor)
    }

}
