@preconcurrency import SwiftUI
import TootSniffer

struct TootView: View {

    let toot: Toot
    let appearance: Appearance
    let showDate: Bool

    init(toot: Toot, appearance: Appearance, showDate: Bool = true) {
        self.toot = toot
        self.appearance = appearance
        self.showDate = showDate
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TooterView(
                tooter: toot.account,
                appearance: appearance
            )
            Text(toot.content)
                .foregroundColor(appearance.textColor)
                .font(.system(.title3, design: .rounded, weight: .regular))
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
    let appearance: Appearance

    var body: some View {
        HStack(spacing: 10) {
            AsyncImage(url: tooter.avatar) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .foregroundColor(.gray)
                    .overlay {
                        ProgressView()
                            .progressViewStyle(.circular)
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
