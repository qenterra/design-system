#if os(macOS)
import QenTerraDesignTokens
import SwiftUI

public struct MediaShelf<Content: View>: View {
    private let title: String
    private let subtitle: String?
    private let actionTitle: String?
    private let action: (@MainActor () -> Void)?
    private let content: Content

    public init(
        title: String,
        subtitle: String? = nil,
        actionTitle: String? = nil,
        action: (@MainActor () -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignProductMetrics.cadence.contentGap) {
            HStack(alignment: .bottom, spacing: DesignProductMetrics.cadence.contentGap) {
                VStack(alignment: .leading, spacing: DesignProductMetrics.cadence.textStack) {
                    Text(verbatim: title).font(.title2.bold())
                    if let subtitle {
                        Text(verbatim: subtitle)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let actionTitle, let action {
                    Button(action: action) {
                        HStack(spacing: DesignProductMetrics.cadence.textStack) {
                            Text(verbatim: actionTitle)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                        }
                    }
                }
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
#endif
