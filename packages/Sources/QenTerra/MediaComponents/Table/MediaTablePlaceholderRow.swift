#if os(macOS)
import QenTerraDesignTokens
import SwiftUI

public struct MediaTablePlaceholderRow: View {
    private let density: DesignDensity
    private let showsArtwork: Bool

    public init(density: DesignDensity = .standard, showsArtwork: Bool = true) {
        self.density = density
        self.showsArtwork = showsArtwork
    }

    public var body: some View {
        let geometry = MediaTableGeometry(density: density)
        HStack(spacing: geometry.songContentSpacing) {
            Color.clear.frame(width: geometry.favoriteControlWidth)
            if showsArtwork {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous)
                    .fill(Color(designToken: DesignTokens.Color.fillDisabled))
                    .frame(width: geometry.artworkSize, height: geometry.artworkSize)
            }
            RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous)
                .fill(Color(designToken: DesignTokens.Color.fillDisabled))
                .frame(width: 180, height: 12)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, geometry.horizontalInset)
        .frame(height: geometry.rowHeight)
        .redacted(reason: .placeholder)
        .accessibilityLabel(Text(verbatim: String(localized: "Loading media")))
    }
}
#endif
