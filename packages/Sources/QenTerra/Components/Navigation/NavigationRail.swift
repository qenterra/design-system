#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public struct NavigationRailItem<ID: Hashable & Sendable>: Identifiable, Equatable, Sendable {
    public let id: ID
    public let title: String
    public let symbol: String
    public let badge: String?
    public let isEnabled: Bool

    public init(
        id: ID,
        title: String,
        symbol: String,
        badge: String? = nil,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.badge = badge
        self.isEnabled = isEnabled
    }
}

public struct NavigationRailItemPresentation<ID: Hashable & Sendable>: Equatable, Sendable {
    public let id: ID
    public let iconAnchorWidth: Double
    public let showsLabel: Bool
    public let isSelected: Bool
    public let isFocused: Bool
    public let isEnabled: Bool

    public init(
        id: ID,
        iconAnchorWidth: Double,
        showsLabel: Bool,
        isSelected: Bool,
        isFocused: Bool,
        isEnabled: Bool
    ) {
        self.id = id
        self.iconAnchorWidth = iconAnchorWidth
        self.showsLabel = showsLabel
        self.isSelected = isSelected
        self.isFocused = isFocused
        self.isEnabled = isEnabled
    }
}

public struct NavigationRail<ID: Hashable & Sendable>: View {
    @Environment(\.designNativeEnvironment) private var nativeEnvironment

    private let items: [NavigationRailItem<ID>]
    @Binding private var selection: ID
    private let isCompact: Bool
    @FocusState private var focusedID: ID?

    public init(
        items: [NavigationRailItem<ID>],
        selection: Binding<ID>,
        isCompact: Bool = false
    ) {
        self.items = items
        _selection = selection
        self.isCompact = isCompact
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: metrics.compactGap) {
            ForEach(items) { item in
                let itemPresentation = Self.presentation(
                    for: item,
                    selection: selection,
                    focusedID: focusedID,
                    isCompact: isCompact
                )
                Button {
                    selection = Self.selectionAfterActivating(item, current: selection)
                } label: {
                    HStack(spacing: metrics.controlGap) {
                        Image(systemName: item.symbol)
                            .frame(width: itemPresentation.iconAnchorWidth, alignment: .center)
                        if itemPresentation.showsLabel {
                            Text(item.title)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            if let badge = item.badge {
                                Text(badge)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Color(designToken: DesignTokens.Color.textSecondary))
                            }
                        }
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: DesignTokens.Component.navigationItemHeight.points,
                        alignment: .leading
                    )
                    .padding(.horizontal, metrics.compactGap)
                    .background(
                        itemPresentation.isSelected
                            ? Color(designToken: DesignTokens.Color.fillSelected)
                            : .clear,
                        in: RoundedRectangle(cornerRadius: DesignTokens.Radius.control, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
                .disabled(!itemPresentation.isEnabled)
                .focused($focusedID, equals: item.id)
                .accessibilityLabel(item.title)
                .accessibilityValue(itemPresentation.isSelected ? Text("Selected") : Text(""))
            }
        }
        .frame(width: isCompact ? DesignTokens.Component.navigationRailCompact.points : nil)
    }

    public static func presentation(
        for item: NavigationRailItem<ID>,
        selection: ID,
        focusedID: ID?,
        isCompact: Bool
    ) -> NavigationRailItemPresentation<ID> {
        NavigationRailItemPresentation(
            id: item.id,
            iconAnchorWidth: DesignTokens.Size.iconM,
            showsLabel: !isCompact,
            isSelected: item.id == selection,
            isFocused: item.id == focusedID,
            isEnabled: item.isEnabled
        )
    }

    public static func selectionAfterActivating(_ item: NavigationRailItem<ID>, current: ID) -> ID {
        item.isEnabled ? item.id : current
    }

    private var metrics: DesignComponentMetrics {
        DesignComponentMetrics.resolve(for: nativeEnvironment)
    }
}
#endif
