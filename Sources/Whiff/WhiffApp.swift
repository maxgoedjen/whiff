import ComposableArchitecture
import Foundation
import SwiftUI
import WhiffFeatures
// FIXME: REMOVE
import TootSniffer

@main
struct WhiffApp: App {

    var body: some Scene {
        WindowGroup {
            ExportFeatureView(store: Store(initialState: .init(), reducer: ExportFeature()))
                .task {
                    let x = TootSniffer()
                    print(try! await x.sniff(url: URL(string: "https://mstdn.social/@lolennui/109547842480496094")!))
                }
        }

    }

}
