#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public struct NavigationRailItem<ID: Hashable & Sendable>: Identifiable, Equatable, Sendable {
    public let id: ID
    public let title: String
    public let symbol: String
    public let badge: String?
    public let isEnabled: Bool
    public let accessibilityHint: String

    public init(
        id: ID,
        title: String,
        symbol: String,
        badge: String? = nil,
        isEnabled: Bool = true,
        accessibilityHint: String = ""
    ) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.badge = badge
        self.isEnabled = isEnabled
        self.accessibilityHint = accessibilityHint
    }
}

public enum NavigationRailBackground: Equatable, Sendable {
    case none
    case thinMaterial
}

public struct NavigationRailPresentation: Equatable, Sendable {
    public let compactWidth: Double
    public let expandedWidth: Double
    public let horizontalInset: Double
    public let verticalInset: Double
    public let rowInset: Double
    public let rowSpacing: Double
    public let rowSurfaceInset: Double
    public let rowHeight: Double
    public let iconSlotWidth: Double
    public let iconSize: Double
    public let background: NavigationRailBackground
    public let expansionDuration: Double

    public init(
        compactWidth: Double,
        expandedWidth: Double,
        horizontalInset: Double,
        verticalInset: Double,
        rowInset: Double,
        rowSpacing: Double,
        rowSurfaceInset: Double,
        rowHeight: Double,
        iconSlotWidth: Double,
        iconSize: Double,
        background: NavigationRailBackground,
        expansionDuration: Double = DesignTokens.Motion.stateReplace.seconds
    ) {
        self.compactWidth = compactWidth
        self.expandedWidth = expandedWidth
        self.horizontalInset = horizontalInset
        self.verticalInset = verticalInset
        self.rowInset = rowInset
        self.rowSpacing = rowSpacing
        self.rowSurfaceInset = rowSurfaceInset
        self.rowHeight = rowHeight
        self.iconSlotWidth = iconSlotWidth
        self.iconSize = iconSize
        self.background = background
        self.expansionDuration = expansionDuration
    }

    public static let standard = Self(
        compactWidth: DesignTokens.Component.navigationRailCompact.points,
        expandedWidth: 0,
        horizontalInset: 0,
        verticalInset: 0,
        rowInset: 0,
        rowSpacing: 0,
        rowSurfaceInset: 0,
        rowHeight: DesignTokens.Component.navigationItemHeight.points,
        iconSlotWidth: DesignTokens.Size.iconM,
        iconSize: DesignTokens.Size.iconM,
        background: .none
    )

    public static let cadence = Self(
        compactWidth: 64,
        expandedWidth: 216,
        horizontalInset: 8,
        verticalInset: 12,
        rowInset: 8,
        rowSpacing: 2,
        rowSurfaceInset: 2,
        rowHeight: 48,
        iconSlotWidth: 32,
        iconSize: 15,
        background: .thinMaterial
    )

    public func totalWidth(isExpanded: Bool) -> Double {
        isExpanded ? expandedWidth : compactWidth
    }

    public func contentWidth(isExpanded: Bool) -> Double {
        totalWidth(isExpanded: isExpanded) - horizontalInset * 2
    }

    public func rowWidth(isExpanded: Bool) -> Double {
        isExpanded ? contentWidth(isExpanded: true) : rowHeight
    }

    public func iconCenterX(isExpanded: Bool) -> Double {
        if isExpanded {
            return horizontalInset + rowInset + iconSlotWidth / 2
        }
        let centeredInset = (contentWidth(isExpanded: false) - rowWidth(isExpanded: false)) / 2
        return horizontalInset + centeredInset + rowHeight / 2
    }
}

public struct NavigationRailExpansionConfiguration: Equatable, Sendable {
    public let expandedTitle: String
    public let collapsedTitle: String
    public let expandedSymbol: String
    public let collapsedSymbol: String
    public let expandedHint: String
    public let collapsedHint: String
    public let expandedAccessibilityLabel: String
    public let collapsedAccessibilityLabel: String

    public init(
        expandedTitle: String,
        collapsedTitle: String,
        expandedSymbol: String,
        collapsedSymbol: String,
        expandedHint: String,
        collapsedHint: String,
        expandedAccessibilityLabel: String? = nil,
        collapsedAccessibilityLabel: String? = nil
    ) {
        self.expandedTitle = expandedTitle
        self.collapsedTitle = collapsedTitle
        self.expandedSymbol = expandedSymbol
        self.collapsedSymbol = collapsedSymbol
        self.expandedHint = expandedHint
        self.collapsedHint = collapsedHint
        self.expandedAccessibilityLabel = expandedAccessibilityLabel ?? expandedTitle
        self.collapsedAccessibilityLabel = collapsedAccessibilityLabel ?? collapsedTitle
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
    private let footerItems: [NavigationRailItem<ID>]
    @Binding private var selection: ID
    private let isCompact: Bool
    private let expansion: Binding<Bool>?
    private let expansionConfiguration: NavigationRailExpansionConfiguration?
    private let suppressesSelection: Bool
    private let freezesInteractionHighlights: Bool
    private let visualPresentation: NavigationRailPresentation
    @FocusState private var focusedID: ID?
    @State private var hoveredID: ID?

    public init(
        items: [NavigationRailItem<ID>],
        selection: Binding<ID>,
        isCompact: Bool = false,
        footerItems: [NavigationRailItem<ID>] = [],
        expansion: Binding<Bool>? = nil,
        expansionConfiguration: NavigationRailExpansionConfiguration? = nil,
        suppressesSelection: Bool = false,
        freezesInteractionHighlights: Bool = false,
        presentation: NavigationRailPresentation = .standard
    ) {
        self.items = items
        self.footerItems = footerItems
        _selection = selection
        self.isCompact = isCompact
        self.expansion = expansion
        self.expansionConfiguration = expansionConfiguration
        self.suppressesSelection = suppressesSelection
        self.freezesInteractionHighlights = freezesInteractionHighlights
        visualPresentation = presentation
    }

    @ViewBuilder
    public var body: some View {
        if visualPresentation == .standard {
            standardBody
        } else if visualPresentation.background == .thinMaterial {
            profiledBody.background(.thinMaterial)
        } else {
            profiledBody
        }
    }

    private var standardBody: some View {
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

    private var profiledBody: some View {
        let isExpanded = expansion?.wrappedValue ?? !isCompact
        return VStack(spacing: visualPresentation.rowSpacing) {
            if expansion != nil, expansionConfiguration != nil {
                expansionButton(isExpanded: isExpanded)
                    .padding(.bottom, metrics.controlGap)
            }

            ForEach(items) { item in
                profiledButton(item, isExpanded: isExpanded)
            }

            if !footerItems.isEmpty {
                Spacer(minLength: metrics.controlGap)
                ForEach(footerItems) { item in
                    profiledButton(item, isExpanded: isExpanded)
                }
            }
        }
        .frame(
            width: visualPresentation.contentWidth(isExpanded: isExpanded),
            alignment: .leading
        )
        .padding(.horizontal, visualPresentation.horizontalInset)
        .padding(.vertical, visualPresentation.verticalInset)
        .frame(
            width: visualPresentation.totalWidth(isExpanded: isExpanded),
            alignment: .leading
        )
        .clipped()
    }

    private func expansionButton(isExpanded: Bool) -> some View {
        let configuration = expansionConfiguration!
        return Button {
            guard let expansion else { return }
            if nativeEnvironment.reducesMotion {
                expansion.wrappedValue.toggle()
            } else {
                withAnimation(.smooth(duration: visualPresentation.expansionDuration)) {
                    expansion.wrappedValue.toggle()
                }
            }
        } label: {
            profiledLabel(
                symbol: isExpanded ? configuration.expandedSymbol : configuration.collapsedSymbol,
                title: isExpanded ? configuration.expandedTitle : configuration.collapsedTitle,
                isExpanded: isExpanded
            )
            .foregroundStyle(profiledForegroundStyle(isSelected: false))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(
            isExpanded
                ? configuration.expandedAccessibilityLabel
                : configuration.collapsedAccessibilityLabel
        )
        .accessibilityLabel(
            isExpanded
                ? configuration.expandedAccessibilityLabel
                : configuration.collapsedAccessibilityLabel
        )
        .accessibilityHint(isExpanded ? configuration.expandedHint : configuration.collapsedHint)
    }

    private func profiledButton(
        _ item: NavigationRailItem<ID>,
        isExpanded: Bool
    ) -> some View {
        let isSelected = !suppressesSelection && selection == item.id
        return Button {
            selection = Self.selectionAfterActivating(item, current: selection)
        } label: {
            profiledLabel(
                symbol: item.symbol,
                title: item.title,
                isExpanded: isExpanded
            )
            .foregroundStyle(profiledForegroundStyle(isSelected: isSelected))
            .background {
                InteractiveRowSurface(
                    state: InteractiveRowState(
                        isHovered: !freezesInteractionHighlights && hoveredID == item.id,
                        isFocused: !freezesInteractionHighlights && focusedID == item.id,
                        isSelected: isSelected
                    )
                ) {
                    Color.clear
                }
                .padding(.horizontal, visualPresentation.rowSurfaceInset)
            }
        }
        .buttonStyle(.plain)
        .disabled(!item.isEnabled)
        .focused($focusedID, equals: item.id)
        .onHover { hoveredID = $0 ? item.id : nil }
        .help(item.title)
        .accessibilityLabel(item.title)
        .accessibilityHint(item.accessibilityHint)
        .accessibilityValue(isSelected ? Text("Selected") : Text(""))
        .frame(
            width: visualPresentation.contentWidth(isExpanded: isExpanded),
            alignment: .center
        )
    }

    private func profiledLabel(
        symbol: String,
        title: String,
        isExpanded: Bool
    ) -> some View {
        Group {
            if isExpanded {
                HStack(spacing: metrics.controlGap) {
                    profiledIcon(symbol)
                    Text(title)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, visualPresentation.rowInset)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                profiledIcon(symbol)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(
            width: visualPresentation.rowWidth(isExpanded: isExpanded),
            height: visualPresentation.rowHeight
        )
        .clipped()
    }

    private func profiledIcon(_ symbol: String) -> some View {
        Image(systemName: symbol)
            .transaction { $0.animation = nil }
            .font(.system(size: visualPresentation.iconSize, weight: .medium))
            .symbolRenderingMode(.hierarchical)
            .frame(
                width: visualPresentation.iconSlotWidth,
                height: visualPresentation.rowHeight
            )
    }

    private func profiledForegroundStyle(isSelected: Bool) -> AnyShapeStyle {
        if visualPresentation == .cadence {
            return isSelected ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary)
        }
        return AnyShapeStyle(
            Color(
                designToken: isSelected
                    ? DesignTokens.Color.textPrimary
                    : DesignTokens.Color.textSecondary
            )
        )
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
