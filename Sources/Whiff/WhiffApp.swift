import ComposableArchitecture
import Foundation
import SwiftUI
import WhiffFeatures

@main
struct WhiffApp: App {

    let store = Store(initialState: .init(), reducer: ExportFeature())

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ExportFeatureView(store: store)
                    .onAppear {
                        ViewStore(store).send(.requested(url: URL(string: "https://mastodon.online/@kyleve/109543232439362633")!))
                    }
            }
        }

    }

}
