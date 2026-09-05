import Foundation
import QenTerraDesignTokens

public enum RenameValidationState: Equatable, Sendable {
    case valid
    case invalid(message: String)
}

public struct RenameAlertConfiguration: Equatable, Sendable {
    public let title: String
    public let message: String?
    public let fieldLabel: String
    public let initialText: String
    public let validation: RenameValidationState
    public let confirmLabel: String
    public let cancelLabel: String

    public var validationColor: DesignColorValue {
        switch validation {
        case .valid:
            DesignTokens.Color.textSecondary
        case .invalid:
            DesignTokens.Color.stateDestructive
        }
    }

    public init(
        title: String,
        message: String? = nil,
        fieldLabel: String,
        initialText: String,
        validation: RenameValidationState,
        confirmLabel: String,
        cancelLabel: String
    ) {
        self.title = title
        self.message = message
        self.fieldLabel = fieldLabel
        self.initialText = initialText
        self.validation = validation
        self.confirmLabel = confirmLabel
        self.cancelLabel = cancelLabel
    }
}
