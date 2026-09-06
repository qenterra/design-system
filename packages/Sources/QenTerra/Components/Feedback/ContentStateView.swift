#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public enum ContentPresentationState: Equatable, Sendable {
    case loading(title: String)
    case empty(title: String, message: String)
    case noResults(title: String, message: String)
    case unavailable(title: String, message: String)
    case error(title: String, message: String)
}

public enum ContentStatePresentationStyle: Equatable, Sendable {
    case designed
    case nativeUnavailable
}

public enum PresentationActionStyle: Equatable, Sendable {
    case primary
    case secondary
    case plain
}

public struct PresentationAction {
    public let title: String
    public let style: PresentationActionStyle
    private let handler: @MainActor () -> Void

    public init(
        title: String,
        style: PresentationActionStyle = .secondary,
        handler: @escaping @MainActor () -> Void
    ) {
        self.title = title
        self.style = style
        self.handler = handler
    }

    @MainActor
    public func perform() {
        handler()
    }
}

@MainActor
public struct ContentStateView: View {
    private let state: ContentPresentationState
    private let actions: [PresentationAction]
    private let symbolName: String?
    private let details: AnyView?
    private let presentation: ContentStatePresentationStyle

    public init(
        state: ContentPresentationState,
        symbolName: String? = nil,
        actions: [PresentationAction] = [],
        presentation: ContentStatePresentationStyle = .designed
    ) {
        self.state = state
        self.symbolName = symbolName
        self.actions = actions
        details = nil
        self.presentation = presentation
    }

    public init<Details: View>(
        state: ContentPresentationState,
        symbolName: String? = nil,
        actions: [PresentationAction] = [],
        presentation: ContentStatePresentationStyle = .designed,
        @ViewBuilder details: () -> Details
    ) {
        self.state = state
        self.symbolName = symbolName
        self.actions = actions
        self.details = AnyView(details())
        self.presentation = presentation
    }

    public init?(state: ContentPresentationState, recovery: PresentationAction?) {
        guard recovery == nil || state.isError else { return nil }
        self.state = state
        symbolName = nil
        actions = recovery.map { [$0] } ?? []
        details = nil
        presentation = .designed
    }

    @ViewBuilder
    public var body: some View {
        if presentation == .nativeUnavailable {
            nativeUnavailableBody
        } else {
            designedBody
        }
    }

    private var designedBody: some View {
        VStack(spacing: DesignTokens.Space.value3) {
            stateSymbol
                .font(.title2)
                .accessibilityHidden(true)
            Text(title)
                .font(
                    .system(
                        size: DesignTokens.Typography.sectionTitle.size,
                        weight: DesignTokens.Typography.sectionTitle.swiftUIWeight
                    )
                )
                .foregroundStyle(Color(designToken: DesignTokens.Color.textPrimary))
                .multilineTextAlignment(.center)
            if let message {
                Text(message)
                    .font(
                        .system(
                            size: DesignTokens.Typography.supporting.size,
                            weight: DesignTokens.Typography.supporting.swiftUIWeight
                        )
                    )
                    .foregroundStyle(Color(designToken: DesignTokens.Color.textSecondary))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let details {
                details
            }
            if !actions.isEmpty {
                HStack(spacing: DesignTokens.Space.value3) {
                    ForEach(actions.indices, id: \.self) { index in
                        Button(actions[index].title) {
                            actions[index].perform()
                        }
                        .buttonStyle(
                            DesignButtonStyle(role: index == 0 ? .primary : .secondary)
                        )
                    }
                }
            }
        }
        .padding(DesignTokens.Space.value6)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
    }

    private var nativeUnavailableBody: some View {
        ContentUnavailableView {
            Label(title, systemImage: symbolName ?? "exclamationmark.triangle")
        } description: {
            VStack(spacing: DesignTokens.Space.value3) {
                if let message {
                    Text(message)
                }
                if let details {
                    details
                }
            }
        } actions: {
            HStack(spacing: DesignTokens.Space.value3) {
                ForEach(actions.indices, id: \.self) { index in
                    nativeActionButton(actions[index])
                }
            }
        }
    }

    @ViewBuilder
    private func nativeActionButton(_ action: PresentationAction) -> some View {
        switch action.style {
        case .primary:
            Button(action.title) { action.perform() }
                .buttonStyle(.borderedProminent)
        case .secondary:
            Button(action.title) { action.perform() }
                .buttonStyle(.bordered)
        case .plain:
            Button(action.title) { action.perform() }
        }
    }

    public static func actionTitles(
        for _: ContentPresentationState,
        actions: [PresentationAction]
    ) -> [String] {
        actions.map(\.title)
    }

    private var title: String {
        switch state {
        case let .loading(title): title
        case let .empty(title, _): title
        case let .noResults(title, _): title
        case let .unavailable(title, _): title
        case let .error(title, _): title
        }
    }

    private var message: String? {
        switch state {
        case .loading: nil
        case let .empty(_, message), let .noResults(_, message), let .unavailable(_, message), let .error(_, message): message
        }
    }

    @ViewBuilder private var stateSymbol: some View {
        if let symbolName {
            Image(systemName: symbolName)
        } else {
            switch state {
            case .loading:
                ProgressView()
            case .empty:
                Image(systemName: "tray")
            case .noResults:
                Image(systemName: "magnifyingglass")
            case .unavailable:
                Image(systemName: "exclamationmark.triangle")
            case .error:
                Image(systemName: "xmark.octagon")
            }
        }
    }
}

private extension ContentPresentationState {
    var isError: Bool {
        if case .error = self { return true }
        return false
    }
}
#endif
