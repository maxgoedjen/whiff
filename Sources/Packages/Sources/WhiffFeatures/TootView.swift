import SwiftUI
import TootSniffer

struct TootView: View {

    let toot: Toot
    let backgroundColor = Color.black
    let textColor = Color.white

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TooterView(
                tooter: toot.tooter,
                backgroundColor: backgroundColor,
                textColor: textColor
            )
            Text(toot.body)
                .foregroundColor(textColor)
                .font(.system(.title3, design: .rounded, weight: .regular))
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(15)
    }

}

struct TooterView: View {

    let tooter: Tooter
    let backgroundColor: Color
    let textColor: Color

    var body: some View {
        HStack(spacing: 10) {
            AsyncImage(url: tooter.image) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
                    .progressViewStyle(.circular)
            }
            .frame(width: 60)
            .mask(Circle())
            VStack(alignment: .leading) {
                Text(tooter.name)
                    .foregroundColor(textColor)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                Text(tooter.username)
                    .foregroundColor(textColor)
                    .font(.system(.title3, design: .rounded, weight: .regular))
            }
        }
    }

}

