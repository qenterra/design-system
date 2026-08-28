import Testing
import QenTerraDesignTokens
@testable import QenTerraComponents
#if canImport(SwiftUI)
import SwiftUI
#endif

@Test func componentModuleKeepsExistingPublicPrimitives() {
    _ = PrimaryButtonStyle(appearance: .light)
    _ = GroupContainer(appearance: .dark)
    _ = InteractiveRowSurface(state: InteractiveRowState(), appearance: .light) {
        EmptyView()
    }
}
