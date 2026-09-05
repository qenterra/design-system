#if os(macOS)
import AppKit

@MainActor
public final class NativeMediaTableView: NSTableView {
    public var onFocusChange: (@MainActor (Bool) -> Void)?
    public private(set) var hasTableFocus = false

    private var returnAction: (@MainActor () -> Void)?
    private var spaceAction: (@MainActor () -> Void)?
    private var deleteAction: (@MainActor () -> Void)?

    public override var acceptsFirstResponder: Bool { true }

    public func configureKeyboardActions<ID: Hashable & Sendable>(
        target: @escaping @MainActor () -> (id: ID, isAvailable: Bool),
        onAction: @escaping @MainActor (ID, NativeMediaTableAction) -> Void
    ) {
        returnAction = {
            let current = target()
            guard current.isAvailable else { return }
            onAction(current.id, .play)
        }
        spaceAction = {
            let current = target()
            guard current.isAvailable else { return }
            onAction(current.id, .togglePlayback)
        }
        deleteAction = {
            let current = target()
            guard current.isAvailable else { return }
            onAction(current.id, .delete)
        }
    }

    public override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result { updateFocus(true) }
        return result
    }

    public override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result { updateFocus(false) }
        return result
    }

    public override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 36: returnAction?()
        case 49: spaceAction?()
        case 51, 117: deleteAction?()
        default: super.keyDown(with: event)
        }
    }

    private func updateFocus(_ value: Bool) {
        guard hasTableFocus != value else { return }
        hasTableFocus = value
        onFocusChange?(value)
    }
}
#endif
