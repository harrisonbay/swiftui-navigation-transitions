import class UIKit.UIView

/// A composite transition that is the result of all the specified transitions being applied.
public struct AtomicTransitionGroup<Transitions: AtomicTransition>: AtomicTransition {
	private let transitions: Transitions

	private init(_ transitions: Transitions) {
		self.transitions = transitions
	}

	public init(@AtomicTransitionBuilder _ transitions: () -> Transitions) {
		self.init(transitions())
	}

	public func transition(_ view: TransientView, for operation: TransitionOperation, in container: Container) {
		transitions.transition(view, for: operation, in: container)
	}
}

extension AtomicTransitionGroup: MirrorableAtomicTransition where Transitions: MirrorableAtomicTransition {
	public func mirrored() -> AtomicTransitionGroup<Transitions.Mirrored> {
		.init(transitions.mirrored())
	}
}

extension AtomicTransitionGroup: Equatable where Transitions: Equatable {}
extension AtomicTransitionGroup: Hashable where Transitions: Hashable {}
