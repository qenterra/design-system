#if os(macOS)
import QenTerraDesignTokens
import SwiftUI

public struct AudioDetail: Identifiable, Equatable, Sendable {
    public let id: String
    public let label: String
    public let value: String
    public let order: Int

    public init(id: String, label: String, value: String, order: Int) {
        self.id = id
        self.label = label
        self.value = value
        self.order = order
    }

    public static func ordered(_ details: [Self]) -> [Self] {
        details.enumerated().sorted { lhs, rhs in
            lhs.element.order == rhs.element.order
                ? lhs.offset < rhs.offset
                : lhs.element.order < rhs.element.order
        }.map(\.element)
    }
}

public struct AudioDetailsView: View {
    private let title: String
    private let subtitle: String?
    private let details: [AudioDetail]

    public init(title: String, subtitle: String? = nil, details: [AudioDetail]) {
        self.title = title
        self.subtitle = subtitle
        self.details = AudioDetail.ordered(details)
    }

    public var body: some View {
        VStack(
            alignment: .leading,
            spacing: DesignTokens.Component.panelMetadataDetailsSectionGap.points
        ) {
            VStack(
                alignment: .leading,
                spacing: DesignTokens.Component.panelMetadataDetailsTitleGap.points
            ) {
                Text(verbatim: title)
                    .font(.headline)
                if let subtitle {
                    Text(verbatim: subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Grid(
                alignment: .leading,
                horizontalSpacing: DesignTokens.Component.panelMetadataDetailsColumnGap.points,
                verticalSpacing: DesignTokens.Component.panelMetadataDetailsRowGap.points
            ) {
                ForEach(details) { detail in
                    GridRow {
                        Text(verbatim: detail.label)
                            .foregroundStyle(.secondary)
                        Text(verbatim: detail.value)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .font(.callout)
        }
        .padding(DesignTokens.Component.panelMetadataDetailsPadding.points)
        .frame(width: DesignTokens.Component.panelMetadataDetailsWidth.points)
    }
}
#endif
