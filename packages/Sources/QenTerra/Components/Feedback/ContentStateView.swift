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

public struct PresentationAction: Sendable {
    public let title: String
    private let handler: @MainActor @Sendable () -> Void

    public init(title: String, handler: @escaping @MainActor @Sendable () -> Void) {
        self.title = title
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
    private let recovery: PresentationAction?

    public init(state: ContentPresentationState) {
        self.state = state
        recovery = nil
    }

    public init?(state: ContentPresentationState, recovery: PresentationAction?) {
        guard recovery == nil || state.isError else { return nil }
        self.state = state
        self.recovery = recovery
    }

    public var body: some View {
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
            if case .error = state, let recovery {
                Button(recovery.title) {
                    recovery.perform()
                }
                .buttonStyle(DesignButtonStyle(role: .secondary))
            }
        }
        .padding(DesignTokens.Space.value6)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
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

private extension ContentPresentationState {
    var isError: Bool {
        if case .error = self { return true }
        return false
    }
}
#endif
