import class UIKit.UIView

/// A composite transition that is the result of two or more transitions being applied.
public struct AtomicTransitionCombined<TransitionA: AtomicTransition, TransitionB: AtomicTransition>: AtomicTransition {
	private let transitionA: TransitionA
	private let transitionB: TransitionB

	init(_ transitionA: TransitionA, _ transitionB: TransitionB) {
		self.transitionA = transitionA
		self.transitionB = transitionB
	}

	public init(@AtomicTransitionBuilder transitions: () -> Self) {
		self = transitions()
	}

	public func transition(_ view: TransientView, for operation: TransitionOperation, in container: Container) {
		transitionA.transition(view, for: operation, in: container)
		transitionB.transition(view, for: operation, in: container)
	}
}

extension AtomicTransitionCombined: MirrorableAtomicTransition where TransitionA: MirrorableAtomicTransition, TransitionB: MirrorableAtomicTransition {
	public func mirrored() -> AtomicTransitionCombined<TransitionA.Mirrored, TransitionB.Mirrored> {
		.init(transitionA.mirrored(), transitionB.mirrored())
	}
}

extension AtomicTransitionCombined: Equatable where TransitionA: Equatable, TransitionB: Equatable {}
extension AtomicTransitionCombined: Hashable where TransitionA: Hashable, TransitionB: Hashable {}
