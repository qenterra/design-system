#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public struct TabStripPresentation: Equatable, Sendable {
    public let iconSize: CGSize
    public let minimumItemSize: CGSize
    public let itemSpacing: Double
    public let usesVerticalLabels: Bool
    public let showsSelectionFill: Bool

    public static let standard = Self(
        iconSize: CGSize(width: DesignTokens.Size.iconM, height: DesignTokens.Size.iconM),
        minimumItemSize: CGSize(width: 0, height: DesignTokens.Component.navigationItemHeight.points),
        itemSpacing: DesignTokens.Space.value2,
        usesVerticalLabels: false,
        showsSelectionFill: true
    )
    public static let cadenceSettings = Self(
        iconSize: CGSize(width: 24, height: 22),
        minimumItemSize: CGSize(width: 76, height: 54),
        itemSpacing: DesignProductMetrics.cadence.compactGap,
        usesVerticalLabels: true,
        showsSelectionFill: false
    )

    public init(
        iconSize: CGSize,
        minimumItemSize: CGSize,
        itemSpacing: Double,
        usesVerticalLabels: Bool,
        showsSelectionFill: Bool
    ) {
        self.iconSize = iconSize
        self.minimumItemSize = minimumItemSize
        self.itemSpacing = itemSpacing
        self.usesVerticalLabels = usesVerticalLabels
        self.showsSelectionFill = showsSelectionFill
    }
}

public struct TabItem<ID: Hashable & Sendable>: Identifiable, Equatable, Sendable {
    public let id: ID
    public let title: String
    public let symbol: String
    public let isEnabled: Bool

    public init(id: ID, title: String, symbol: String, isEnabled: Bool = true) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.isEnabled = isEnabled
    }
}

public struct TabStrip<ID: Hashable & Sendable>: View {
    @Environment(\.designNativeEnvironment) private var nativeEnvironment

    private let items: [TabItem<ID>]
    @Binding private var selection: ID
    private let presentation: TabStripPresentation
    @FocusState private var focusedID: ID?

    public init(
        items: [TabItem<ID>],
        selection: Binding<ID>,
        presentation: TabStripPresentation = .standard
    ) {
        self.items = items
        _selection = selection
        self.presentation = presentation
    }

    public var body: some View {
        HStack(spacing: presentation.itemSpacing) {
            ForEach(items) { item in
                Button {
                    selection = Self.selectionAfterActivating(item, current: selection)
                } label: {
                    tabLabel(item)
                        .frame(
                            minWidth: presentation.minimumItemSize.width,
                            minHeight: presentation.minimumItemSize.height
                        )
                        .padding(.horizontal, presentation.usesVerticalLabels ? 0 : metrics.controlGap)
                        .background(
                            item.id == selection && presentation.showsSelectionFill
                                ? Color(designToken: DesignTokens.Color.fillSelected)
                                : .clear,
                            in: RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!item.isEnabled)
                .focused($focusedID, equals: item.id)
                .accessibilityValue(item.id == selection ? Text("Selected") : Text(""))
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func tabLabel(_ item: TabItem<ID>) -> some View {
        if presentation.usesVerticalLabels {
            VStack(spacing: metrics.textStack) {
                Image(systemName: item.symbol)
                    .font(.system(size: 17, weight: .medium))
                    .frame(width: presentation.iconSize.width, height: presentation.iconSize.height)
                Text(item.title)
                    .font(.caption)
                    .lineLimit(1)
            }
            .foregroundStyle(
                item.id == selection
                    ? Color(designToken: DesignTokens.Color.actionPrimary)
                    : Color(designToken: DesignTokens.Color.textSecondary)
            )
            .contentShape(Rectangle())
        } else {
            Label(item.title, systemImage: item.symbol)
        }
    }

    public static func selectionAfterActivating(_ item: TabItem<ID>, current: ID) -> ID {
        item.isEnabled ? item.id : current
    }

    private var metrics: DesignComponentMetrics {
        DesignComponentMetrics.resolve(for: nativeEnvironment)
    }
}
#endif
