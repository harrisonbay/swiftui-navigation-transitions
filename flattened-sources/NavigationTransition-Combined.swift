// import IssueReporting - removed (replaced with print)

extension AnyNavigationTransition {
	/// Combines this transition with another, returning a new transition that is the result of both transitions
	/// being applied.
	public func combined(with other: Self) -> Self {
		switch (self.handler, other.handler) {
		case (.transient(let lhsHandler), .transient(let rhsHandler)):
			struct Erased: NavigationTransitionProtocol {
				let handler: AnyNavigationTransition.TransientHandler

				@inlinable
				func transition(from fromView: TransientView, to toView: TransientView, for operation: TransitionOperation, in container: Container) {
					handler(fromView, toView, operation, container)
				}
			}
			return AnyNavigationTransition(
				NavigationTransitionCombined(Erased(handler: lhsHandler), Erased(handler: rhsHandler))
			)
		case (.transient, .primitive),
		     (.primitive, .transient),
		     (.primitive, .primitive):
			print(
				"""
				Warning: Combining primitive and non-primitive or two primitive transitions via 'combine(with:)' is not allowed.

				The left-hand side transition will be left unmodified and the right-hand side transition will be discarded.
				"""
			)
			return self
		}
	}
}

public struct NavigationTransitionCombined<TransitionA: NavigationTransitionProtocol, TransitionB: NavigationTransitionProtocol>: NavigationTransitionProtocol {
	private let transitionA: TransitionA
	private let transitionB: TransitionB

	init(_ transitionA: TransitionA, _ transitionB: TransitionB) {
		self.transitionA = transitionA
		self.transitionB = transitionB
	}

	public init(@NavigationTransitionBuilder transitions: () -> Self) {
		self = transitions()
	}

	public func transition(
		from fromView: TransientView,
		to toView: TransientView,
		for operation: TransitionOperation,
		in container: Container
	) {
		transitionA.transition(from: fromView, to: toView, for: operation, in: container)
		transitionB.transition(from: fromView, to: toView, for: operation, in: container)
	}
}

extension NavigationTransitionCombined: Equatable where TransitionA: Equatable, TransitionB: Equatable {}
extension NavigationTransitionCombined: Hashable where TransitionA: Hashable, TransitionB: Hashable {}
