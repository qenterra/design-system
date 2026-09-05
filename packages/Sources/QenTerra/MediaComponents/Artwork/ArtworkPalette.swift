#if os(macOS)
import QenTerraDesignTokens
import SwiftUI

/// Ready colors only. The caller owns palette selection and extraction.
public struct ArtworkPalette: Sendable {
    public let leading: Color
    public let trailing: Color
    public let highlight: Color
    public let symbolName: String

    public init(
        leading: Color,
        trailing: Color,
        highlight: Color? = nil,
        symbolName: String = "waveform"
    ) {
        self.leading = leading
        self.trailing = trailing
        self.highlight = highlight ?? trailing
        self.symbolName = symbolName
    }

    public static var neutral: Self {
        Self(
            leading: Color(designToken: DesignTokens.Color.surfaceSecondary),
            trailing: Color(designToken: DesignTokens.Color.surfaceRaised)
        )
    }
}
#endif
