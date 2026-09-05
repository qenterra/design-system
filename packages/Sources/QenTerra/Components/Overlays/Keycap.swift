#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public struct Keycap: View {
    private let token: String

    public init(_ token: String) {
        self.token = token
    }

    public var body: some View {
        Text(token)
            .font(.system(.caption, design: .rounded).weight(.medium))
            .foregroundStyle(Color(designToken: DesignTokens.Color.textPrimary))
            .padding(.horizontal, DesignTokens.Component.keycapPaddingX.points)
            .frame(minHeight: DesignTokens.Component.keycapHeight.points)
            .background(Color(designToken: DesignTokens.Color.surfaceSecondary))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Component.keycapRadius.points, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.Component.keycapRadius.points, style: .continuous)
                    .stroke(Color(designToken: DesignTokens.Color.borderDefault), lineWidth: DesignTokens.Stroke.hairline)
            }
            .accessibilityLabel(token)
    }
}

public struct KeycapChord: View {
    private let tokens: [String]

    public init(tokens: [String]) {
        self.tokens = tokens
    }

    public var body: some View {
        let presentation = Self.presentation(tokens: tokens)
        HStack(spacing: DesignTokens.Component.keycapGap.points) {
            ForEach(Array(presentation.tokens.enumerated()), id: \.offset) { _, token in
                Keycap(token)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(presentation.accessibilityLabel)
    }

    public static func presentation(tokens: [String]) -> KeycapChordPresentation {
        KeycapChordPresentation(
            tokens: tokens,
            accessibilityLabel: tokens.joined(separator: " ")
        )
    }
}

public struct KeycapChordPresentation: Equatable, Sendable {
    public let tokens: [String]
    public let accessibilityLabel: String

    public init(tokens: [String], accessibilityLabel: String) {
        self.tokens = tokens
        self.accessibilityLabel = accessibilityLabel
    }
}
#endif
