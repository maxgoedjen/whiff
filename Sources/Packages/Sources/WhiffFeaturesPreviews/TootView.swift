import Foundation
import SwiftUI
import TootSniffer
@testable import WhiffFeatures

struct TootViewPreview: PreviewProvider {

    static var previews: some View {
        VStack {
            TootView(toot: .example, appearance: Appearance(textColor: .white, backgroundColor: .black), showDate: true)
            TootView(toot: .example, appearance: Appearance(textColor: .black, backgroundColor: .white), showDate: false)
        }
    }

}

extension Toot {

    static var example = example(from: """
    {"tooter":{"image":"https://media.mstdn.social/accounts/avatars/109/354/943/563/648/756/original/568320c2b8bcd0e8.png","name":"Amy","username":"@lolennui@mstdn.social"},"body":"I feel like twitter was a bar where for some reason everyone had a knife and now I’m here looking around like “none of you have KNIVES, right??” and you’re all like “why would I have a knife, are you ok”","source":"https://mstdn.social/@lolennui/109547842480496094","images":[],"date":693260220}
    """)

    private static func example(from string: String) -> Toot {
        try! JSONDecoder()
            .decode(Toot.self, from: string.data(using: .utf8)!)
    }
}
