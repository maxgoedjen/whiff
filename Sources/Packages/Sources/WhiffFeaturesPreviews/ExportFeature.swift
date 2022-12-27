import ComposableArchitecture
import Foundation
import SwiftUI
@testable import WhiffFeatures

struct ExportFeatureViewPreview: PreviewProvider {

    static var previews: some View {
        ExportFeatureView(store: Store(initialState: .init(), reducer: ExportFeature()))
    }

}
