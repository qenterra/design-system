#if canImport(SwiftUI)
import SwiftUI
import QenTerraDesignTokens

public struct MeasuredOperationProgress: Equatable, Sendable {
    public let completedUnitCount: Int
    public let totalUnitCount: Int

    public init?(
        completedUnitCount: Int,
        totalUnitCount: Int
    ) {
        guard totalUnitCount > 0,
              (0...totalUnitCount).contains(completedUnitCount) else {
            return nil
        }
        self.completedUnitCount = completedUnitCount
        self.totalUnitCount = totalUnitCount
    }

    public var fractionCompleted: Double {
        Double(completedUnitCount) / Double(totalUnitCount)
    }
}

public enum OperationPresentationState: Equatable, Sendable {
    case preparing(title: String, message: String)
    case reviewing(title: String, message: String)
    case inProgress(
        title: String,
        message: String,
        progress: MeasuredOperationProgress
    )
    case completed(title: String, message: String)
    case failed(title: String, message: String)

    public var fractionCompleted: Double? {
        guard case let .inProgress(_, _, progress) = self else {
            return nil
        }
        return progress.fractionCompleted
    }

}

public struct OperationStateView: View {
    private let state: OperationPresentationState

    public init(state: OperationPresentationState) {
        self.state = state
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.value2) {
            HStack(spacing: DesignTokens.Space.value2) {
                symbol
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)
                Text(title)
                    .font(
                        .system(
                            size: DesignTokens.Typography.rowEmphasized.size,
                            weight: DesignTokens.Typography.rowEmphasized.swiftUIWeight
                        )
                    )
                    .foregroundStyle(Color(designToken: DesignTokens.Color.textPrimary))
            }
            Text(message)
                .font(
                    .system(
                        size: DesignTokens.Typography.supporting.size,
                        weight: DesignTokens.Typography.supporting.swiftUIWeight
                    )
                )
                .foregroundStyle(Color(designToken: DesignTokens.Color.textSecondary))
            if case let .inProgress(_, _, progress) = state {
                ProgressView(
                    value: Double(progress.completedUnitCount),
                    total: Double(progress.totalUnitCount)
                )
                    .tint(tint)
            }
        }
        .padding(DesignTokens.Space.value4)
        .background(Color(designToken: DesignTokens.Color.surfaceRaised))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.group, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private var title: String {
        switch state {
        case let .preparing(title, _), let .reviewing(title, _), let .inProgress(title, _, _), let .completed(title, _), let .failed(title, _): title
        }
    }

    private var message: String {
        switch state {
        case let .preparing(_, message), let .reviewing(_, message), let .inProgress(_, message, _), let .completed(_, message), let .failed(_, message): message
        }
    }

    @ViewBuilder private var symbol: some View {
        switch state {
        case .preparing, .reviewing:
            ProgressView()
        case .inProgress: ProgressView()
        case .completed: Image(systemName: "checkmark.circle")
        case .failed: Image(systemName: "xmark.octagon")
        }
    }

    private var tint: Color {
        switch state {
        case .preparing, .reviewing, .inProgress: Color(designToken: DesignTokens.Color.stateInformative)
        case .completed: Color(designToken: DesignTokens.Color.stateSuccess)
        case .failed: Color(designToken: DesignTokens.Color.stateDestructive)
        }
    }
}
#endif
