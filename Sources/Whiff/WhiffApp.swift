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
                        ViewStore(store).send(.requested(url: URL(string: "https://mstdn.social/@lolennui/109547842480496094")!))
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                ViewStore(store).send(.tappedSettings(true))
                            } label: {
                                Image(systemName: "gear")
                            }
                            
                        }
                    }
            }
        }

    }

}
