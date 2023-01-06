import BlurHashKit
import SwiftUI
import TootSniffer

/// View that renders the account information of a user.
struct TooterView: View {

    /// The account to display.
    let tooter: Tooter

    /// The loaded images for the post.
    let images: [URLKey: ImageEquatable]

    /// Settings for how the post should be displayed.
    let settings: SettingsFeature.State

    var body: some View {
        HStack(spacing: 10) {
            Group {
                if let image = images[URLKey(tooter.avatar, .remote)] {
                    image
                        .image.value // FIXME: Gross
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
