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

public enum OperationStateVisualStyle: Equatable, Sendable {
    case standard
    case cadenceScanning
    case cadenceCompletion

    public var symbolSize: CGFloat {
        switch self {
        case .standard: 16
        case .cadenceScanning: 32
        case .cadenceCompletion: 46
        }
    }
}

public struct OperationStateView: View {
    private let state: OperationPresentationState
    private let symbolName: String?
    private let visualStyle: OperationStateVisualStyle

    public init(
        state: OperationPresentationState,
        symbolName: String? = nil,
        visualStyle: OperationStateVisualStyle = .standard
    ) {
        self.state = state
        self.symbolName = symbolName
        self.visualStyle = visualStyle
    }

    @ViewBuilder
    public var body: some View {
        if visualStyle == .standard {
            standardBody
        } else {
            cadenceBody
        }
    }

    private var standardBody: some View {
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

    private var cadenceBody: some View {
        VStack(spacing: visualStyle == .cadenceScanning ? 12 : 8) {
            symbol
                .font(.system(size: visualStyle.symbolSize, weight: .light))
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            VStack(spacing: 8) {
                Text(title)
                    .font(
                        visualStyle == .cadenceCompletion
                            ? .title2.weight(.semibold)
                            : .title3.weight(.semibold)
                    )
                Text(message)
                    .font(.callout)
                    .foregroundStyle(Color(designToken: DesignTokens.Color.textSecondary))
                    .multilineTextAlignment(.center)
            }
        }
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
        if let symbolName {
            Image(systemName: symbolName)
        } else {
            switch state {
            case .preparing, .reviewing:
                ProgressView()
            case .inProgress: ProgressView()
            case .completed: Image(systemName: "checkmark.circle")
            case .failed: Image(systemName: "xmark.octagon")
            }
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
