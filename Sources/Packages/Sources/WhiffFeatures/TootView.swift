@preconcurrency import SwiftUI
import TootSniffer

struct TootView: View {

    let toot: Toot
    let settings: SettingsFeature.State
    let images: [URL: Image]

    init(toot: Toot, images: [URL: Image], settings: SettingsFeature.State) {
        self.toot = toot
        self.images = images
        self.settings = settings
    }

    var content: some View {
        Text(toot.content)
            .foregroundColor(settings.textColor)
            .font(.system(.title3, design: .rounded, weight: .regular))

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
                        ImageWrapperView(image: images[attachment.url], size: attachment.size, contentMode: .fit)
                    }
                }
            case .stacked:
                content
                VStack (spacing: 5) {
                    ForEach(toot.mediaAttachments) { attachment in
                        ImageWrapperView(image: images[attachment.url], size: attachment.size, contentMode: .fill)
                    }
                }
            case .fan:
                HStack {
                    content
                    ZStack {
                        ForEach(Array(zip(toot.mediaAttachments.indices, toot.mediaAttachments)), id: \.0) { (idx, attachment) in
                            ImageWrapperView(image: images[attachment.url], size: attachment.size, contentMode: .fit)
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
        }
        .padding()
        .background(settings.backgroundColor)
        .cornerRadius(settings.roundCorners ? 15 : 0)
    }

}

struct TooterView: View {

    let tooter: Tooter
    let images: [URL: Image]
    let settings: SettingsFeature.State

    var body: some View {
        HStack(spacing: 10) {
            Group {
                if let image = images[tooter.avatar] {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Rectangle()
                        .foregroundColor(.gray)
                        .overlay {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                }
            }
            .frame(width: 60, height: 60)
            .mask(Circle())
            VStack(alignment: .leading) {
                Text(tooter.displayName)
                    .foregroundColor(settings.textColor)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                Text(tooter.username)
                    .foregroundColor(settings.textColor)
                    .font(.system(.title3, design: .rounded, weight: .regular))
            }
        }
    }

}

struct ImageWrapperView: View {

    var image: Image?
    var size: CGSize
    var contentMode: ContentMode

    var body: some View {
        Group {
            if let image {
                image
                    .resizable()
                    .aspectRatio(size, contentMode: contentMode)
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

