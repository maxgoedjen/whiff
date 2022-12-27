@preconcurrency import SwiftUI
import TootSniffer

struct TootView: View {

    let toot: Toot
    let appearance: Appearance
    let showDate: Bool
    let images: [URL: Image]

    init(toot: Toot, images: [URL: Image], appearance: Appearance, showDate: Bool = true) {
        self.toot = toot
        self.images = images
        self.appearance = appearance
        self.showDate = showDate
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TooterView(
                tooter: toot.account,
                images: images,
                appearance: appearance
            )
            Text(toot.content)
                .foregroundColor(appearance.textColor)
                .font(.system(.title3, design: .rounded, weight: .regular))
            HStack {
                // FIXME: GRID/FAN?
                ForEach(toot.mediaAttachments) { attachment in
                    if let image = images[attachment.url] {
                        image
                            .resizable()
                            .aspectRatio(attachment.size, contentMode: .fit)
                    } else {
                        Rectangle()
                            .foregroundColor(.gray)
                            .overlay {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            }
                    }

                }

            }
            if showDate {
                Text(toot.createdAt.formatted())
                    .foregroundColor(appearance.textColor)
                    .font(.system(.footnote, design: .rounded, weight: .regular))
            }
        }
        .padding()
        .background(appearance.backgroundColor)
        .cornerRadius(15)
    }

}

struct TooterView: View {

    let tooter: Tooter
    let images: [URL: Image]
    let appearance: Appearance

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
                    .foregroundColor(appearance.textColor)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                Text(tooter.username)
                    .foregroundColor(appearance.textColor)
                    .font(.system(.title3, design: .rounded, weight: .regular))
            }
        }
    }

}

struct Appearance: Equatable, Sendable {

    let textColor: Color
    let backgroundColor: Color

}
