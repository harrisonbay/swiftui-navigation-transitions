import class UIKit.UIView

/// A transition that returns the input view, unmodified, as the output view.
public struct AtomicTransitionIdentity: AtomicTransition, MirrorableAtomicTransition {
	public init() {}

	public func transition(_ view: TransientView, for operation: TransitionOperation, in container: Container) {
		// NO-OP
	}

	@inlinable
	public func mirrored() -> Self {
		self
	}
}

extension AtomicTransitionIdentity: Hashable {}
