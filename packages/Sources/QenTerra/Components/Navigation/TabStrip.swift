#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

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
    @FocusState private var focusedID: ID?

    public init(items: [TabItem<ID>], selection: Binding<ID>) {
        self.items = items
        _selection = selection
    }

    public var body: some View {
        HStack(spacing: metrics.compactGap) {
            ForEach(items) { item in
                Button {
                    selection = Self.selectionAfterActivating(item, current: selection)
                } label: {
                    Label(item.title, systemImage: item.symbol)
                        .frame(minHeight: DesignTokens.Component.navigationItemHeight.points)
                        .padding(.horizontal, metrics.controlGap)
                        .background(
                            item.id == selection
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

    public static func selectionAfterActivating(_ item: TabItem<ID>, current: ID) -> ID {
        item.isEnabled ? item.id : current
    }

    private var metrics: DesignComponentMetrics {
        DesignComponentMetrics.resolve(for: nativeEnvironment)
    }
}
#endif
