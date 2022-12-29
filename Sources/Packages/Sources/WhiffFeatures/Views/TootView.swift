import BlurHashKit
@preconcurrency import SwiftUI
import TootSniffer

struct TootView: View {

    let toot: Toot
    let attributedContent: AttributedString?
    let settings: SettingsFeature.State
    let images: [URLKey: Image]

    init(toot: Toot, attributedContent: AttributedString?, images: [URLKey: Image], settings: SettingsFeature.State) {
        self.toot = toot
        self.attributedContent = attributedContent
        self.images = images
        self.settings = settings
    }

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
                        ImageWrapperView(image: images[URLKey(attachment.url, .remote)], blurhash: images[URLKey(attachment.url, .blurhash)], size: attachment.size, contentMode: .fit)
                    }
                }
            case .stacked:
                content
                VStack(spacing: 5) {
                    ForEach(toot.mediaAttachments) { attachment in
                        ImageWrapperView(image: images[URLKey(attachment.url, .remote)], blurhash: images[URLKey(attachment.url, .blurhash)], size: attachment.size, contentMode: .fill)
                    }
                }
            case .fan:
                HStack {
                    content
                    ZStack {
                        ForEach(Array(zip(toot.mediaAttachments.indices, toot.mediaAttachments)), id: \.0) { idx, attachment in
                            ImageWrapperView(image: images[URLKey(attachment.url, .remote)], blurhash: images[URLKey(attachment.url, .blurhash)], size: attachment.size, contentMode: .fit)
                                .frame(maxWidth: 50)
                                .border(.white, width: 1)
                                .shadow(radius: 5)
                                .rotationEffect(Angle(degrees: Double(idx)) * 10)

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
        .padding()
        .background(settings.backgroundColor)
        .cornerRadius(settings.roundCorners ? 15 : 0)
    }

}