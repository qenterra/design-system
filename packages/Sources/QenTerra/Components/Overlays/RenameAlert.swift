import Foundation
import QenTerraDesignTokens
#if canImport(SwiftUI)
import SwiftUI
#endif

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

    public var isConfirmationEnabled: Bool {
        validation == .valid
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

#if canImport(SwiftUI)
public extension View {
    func renameAlert(
        configuration: RenameAlertConfiguration,
        isPresented: Binding<Bool>,
        text: Binding<String>,
        onConfirm: @escaping (String) -> Void
    ) -> some View {
        alert(configuration.title, isPresented: isPresented) {
            TextField(configuration.fieldLabel, text: text)
            Button(configuration.cancelLabel, role: .cancel) {}
            Button(configuration.confirmLabel) {
                onConfirm(text.wrappedValue)
            }
            .disabled(!configuration.isConfirmationEnabled)
        } message: {
            if let message = configuration.message {
                Text(message)
            } else if case let .invalid(message) = configuration.validation {
                Text(message)
            }
        }
    }
}
#endif
