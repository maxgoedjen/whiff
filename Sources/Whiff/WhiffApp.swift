import ComposableArchitecture
import Foundation
import SwiftUI
import WhiffFeatures

@main
struct WhiffApp: App {

    var body: some Scene {
        WindowGroup {
            NavigationView {
                AppFeatureView(store: Store(initialState: .init(), reducer: AppFeature()))
            }
        }

    }

}
