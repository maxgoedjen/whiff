import SwiftUI

/// Button style for the big blue capsule style used by Whiff.
public struct BigCapsuleButton: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .bold()
            .frame(width: 250, height: 60)
            .foregroundColor(.white)
            .background(.tint)
            .clipShape(Capsule())
    }
}
