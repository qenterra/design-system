#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public enum SortMenuOrder: String, CaseIterable, Equatable, Sendable {
    case ascending
    case descending
}

public struct SortMenuVisualStyle: Equatable, Sendable {
    public let triggerSymbol: String
    public let usesExplicitChoiceMarks: Bool

    public init(triggerSymbol: String, usesExplicitChoiceMarks: Bool) {
        self.triggerSymbol = triggerSymbol
        self.usesExplicitChoiceMarks = usesExplicitChoiceMarks
    }

    public static let standard = Self(
        triggerSymbol: "arrow.up.arrow.down",
        usesExplicitChoiceMarks: false
    )
    public static let cadence = Self(
        triggerSymbol: "arrow.up.arrow.down.circle",
        usesExplicitChoiceMarks: true
    )
}

public struct SortMenuField<ID: Hashable & Sendable>: Identifiable, Equatable, Sendable {
    public let id: ID
    public let title: String
    public let isEnabled: Bool

    public init(id: ID, title: String, isEnabled: Bool = true) {
        self.id = id
        self.title = title
        self.isEnabled = isEnabled
    }
}

public struct SortMenuLabels: Equatable, Sendable {
    public let trigger: String
    public let field: String
    public let order: String
    public let ascending: String
    public let descending: String
    public let unavailable: String

    public init(
        trigger: String,
        field: String,
        order: String,
        ascending: String,
        descending: String,
        unavailable: String
    ) {
        self.trigger = trigger
        self.field = field
        self.order = order
        self.ascending = ascending
        self.descending = descending
        self.unavailable = unavailable
    }
}

public enum SortMenuUnavailableReason: Equatable, Sendable {
    case emptyFields
    case selectionNotFound
}

public struct SortMenuReadyPresentation<ID: Hashable & Sendable>: Equatable, Sendable {
    public let triggerTitle: String
    public let accessibilityValue: String
    public let selectedFieldID: ID

    public init(triggerTitle: String, accessibilityValue: String, selectedFieldID: ID) {
        self.triggerTitle = triggerTitle
        self.accessibilityValue = accessibilityValue
        self.selectedFieldID = selectedFieldID
    }
}

public enum SortMenuPresentation<ID: Hashable & Sendable>: Equatable, Sendable {
    case ready(SortMenuReadyPresentation<ID>)
    case unavailable(SortMenuUnavailableReason)
}

public struct SortMenu<ID: Hashable & Sendable>: View {
    private let fields: [SortMenuField<ID>]
    @Binding private var selection: ID
    @Binding private var order: SortMenuOrder
    private let labels: SortMenuLabels
    private let visualStyle: SortMenuVisualStyle

    public init(
        fields: [SortMenuField<ID>],
        selection: Binding<ID>,
        order: Binding<SortMenuOrder>,
        labels: SortMenuLabels,
        visualStyle: SortMenuVisualStyle = .standard
    ) {
        self.fields = fields
        _selection = selection
        _order = order
        self.labels = labels
        self.visualStyle = visualStyle
    }

    public var body: some View {
        switch presentation {
        case let .ready(ready):
            Menu {
                if visualStyle.usesExplicitChoiceMarks {
                    ForEach(fields) { field in
                        Button {
                            selection = Self.selectionAfterActivating(
                                field,
                                current: selection
                            )
                        } label: {
                            choiceLabel(
                                field.title,
                                isSelected: selection == field.id
                            )
                        }
                        .disabled(!field.isEnabled)
                    }
                    Divider()
                    ForEach(SortMenuOrder.allCases, id: \.self) { candidate in
                        Button {
                            order = candidate
                        } label: {
                            choiceLabel(
                                candidate == .ascending ? labels.ascending : labels.descending,
                                isSelected: order == candidate
                            )
                        }
                    }
                } else {
                    Picker(labels.field, selection: selectableField) {
                        ForEach(fields) { field in
                            Text(field.title)
                                .tag(field.id)
                                .disabled(!field.isEnabled)
                        }
                    }
                    Divider()
                    Picker(labels.order, selection: $order) {
                        Text(labels.ascending).tag(SortMenuOrder.ascending)
                        Text(labels.descending).tag(SortMenuOrder.descending)
                    }
                }
            } label: {
                Label(
                    visualStyle.usesExplicitChoiceMarks
                        ? cadenceTriggerTitle(selectedFieldID: ready.selectedFieldID)
                        : ready.triggerTitle,
                    systemImage: visualStyle.triggerSymbol
                )
                    .foregroundStyle(Color(designToken: DesignTokens.Color.textPrimary))
            }
            .menuStyle(.borderlessButton)
            .accessibilityValue(ready.accessibilityValue)
        case .unavailable:
            Label(labels.unavailable, systemImage: "arrow.up.arrow.down")
                .foregroundStyle(Color(designToken: DesignTokens.Color.textSecondary))
                .accessibilityValue(labels.unavailable)
                .disabled(true)
        }
    }

    public static func presentation(
        fields: [SortMenuField<ID>],
        selection: ID,
        order: SortMenuOrder,
        labels: SortMenuLabels
    ) -> SortMenuPresentation<ID> {
        guard !fields.isEmpty else {
            return .unavailable(.emptyFields)
        }
        guard let selectedField = fields.first(where: { $0.id == selection }) else {
            return .unavailable(.selectionNotFound)
        }

        let directionTitle = order == .ascending ? labels.ascending : labels.descending
        return .ready(
            SortMenuReadyPresentation(
                triggerTitle: "\(labels.trigger): \(selectedField.title), \(directionTitle)",
                accessibilityValue: "\(selectedField.title), \(directionTitle)",
                selectedFieldID: selection
            )
        )
    }

    public static func selectionAfterActivating(_ field: SortMenuField<ID>, current: ID) -> ID {
        field.isEnabled ? field.id : current
    }

    private var presentation: SortMenuPresentation<ID> {
        Self.presentation(fields: fields, selection: selection, order: order, labels: labels)
    }

    public static func selectionBinding(
        fields: [SortMenuField<ID>],
        selection: Binding<ID>
    ) -> Binding<ID> {
        Binding(
            get: { selection.wrappedValue },
            set: { candidate in
                guard let field = fields.first(where: { $0.id == candidate }) else { return }
                selection.wrappedValue = Self.selectionAfterActivating(
                    field,
                    current: selection.wrappedValue
                )
            }
        )
    }

    private var selectableField: Binding<ID> {
        Self.selectionBinding(fields: fields, selection: $selection)
    }

    private func cadenceTriggerTitle(selectedFieldID: ID) -> String {
        guard let field = fields.first(where: { $0.id == selectedFieldID }) else {
            return labels.trigger
        }
        return "\(labels.trigger): \(field.title)"
    }

    private func choiceLabel(_ title: String, isSelected: Bool) -> some View {
        HStack {
            Text(title)
            if isSelected {
                Image(systemName: "checkmark")
            }
        }
    }
}
#endif
