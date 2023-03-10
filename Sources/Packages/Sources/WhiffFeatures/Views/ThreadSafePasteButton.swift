import Foundation
import SwiftUI

/// Paste button wrapper that dispatches to main queue before calling onPaste.
public struct PasteButtonThreadSafe<T: Transferable>: View {

    let onPaste: ([T]) -> Void

    public init(payloadType: T.Type, onPaste: @escaping ([T]) -> Void) {
        self.onPaste = onPaste
    }

    public var body: some View {
        PasteButton(payloadType: T.self) { values in
            DispatchQueue.main.async {
                onPaste(values)
            }
        }

        .labelStyle(.titleAndIcon)
        .buttonBorderShape(.capsule)
    }
}
