import ComposableArchitecture
import Foundation
import SwiftUI
import WhiffFeatures

@main
struct WhiffApp: App {

    var body: some Scene {
        WindowGroup {
            ExportFeatureView(store: Store(initialState: .init(), reducer: ExportFeature()))
        }

    }

}
