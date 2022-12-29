import ComposableArchitecture
import Foundation
import SwiftUI
import WhiffFeatures

@main
struct WhiffApp: App {

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                AppFeatureView(store: Store(initialState: .init(), reducer: AppFeature()))
            }
        }

    }

}
