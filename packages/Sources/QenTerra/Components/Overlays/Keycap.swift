#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public enum KeycapPresentation: Equatable, Sendable {
    case standard
    case cadence
}

public struct Keycap: View {
    private let token: String
    private let symbolName: String?
    private let presentation: KeycapPresentation

    public init(_ token: String) {
        self.init(token, symbolName: nil, presentation: .standard)
    }

    public init(
        _ token: String,
        symbolName: String?,
        presentation: KeycapPresentation
    ) {
        self.token = token
        self.symbolName = symbolName
        self.presentation = presentation
    }

    public var body: some View {
        Group {
            if let symbolName {
                Image(systemName: symbolName)
            } else {
                Text(token)
            }
        }
        .font(
            presentation == .cadence
                ? .callout.weight(.medium)
                : .system(.caption, design: .rounded).weight(.medium)
        )
        .foregroundStyle(
            Color(
                designToken: presentation == .cadence
                    ? DesignTokens.Color.textSecondary
                    : DesignTokens.Color.textPrimary
            )
        )
        .frame(minWidth: presentation == .cadence ? 18 : nil, minHeight: presentation == .cadence ? 18 : DesignTokens.Component.keycapHeight.points)
        .padding(.horizontal, presentation == .cadence ? 5 : DesignTokens.Component.keycapPaddingX.points)
        .background(
            Color(
                designToken: presentation == .cadence
                    ? DesignTokens.Color.fillDisabled
                    : DesignTokens.Color.surfaceSecondary
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: presentation == .cadence ? DesignTokens.Radius.control : DesignTokens.Component.keycapRadius.points,
                style: .continuous
            )
        )
        .overlay {
            if presentation == .standard {
                RoundedRectangle(cornerRadius: DesignTokens.Component.keycapRadius.points, style: .continuous)
                    .stroke(Color(designToken: DesignTokens.Color.borderDefault), lineWidth: DesignTokens.Stroke.hairline)
            }
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
