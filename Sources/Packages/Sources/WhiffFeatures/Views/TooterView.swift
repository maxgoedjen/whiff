import BlurHashKit
@preconcurrency import SwiftUI
import TootSniffer

struct TooterView: View {

    let tooter: Tooter
    let images: [URLKey: Image]
    let settings: SettingsFeature.State

    var body: some View {
        HStack(spacing: 10) {
            Group {
                if let image = images[URLKey(tooter.avatar, .remote)] {
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
