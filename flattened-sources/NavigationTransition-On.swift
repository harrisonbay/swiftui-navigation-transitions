// import AtomicTransition - removed (flattened)

/// Used to define a transition that executes only on push.
public struct OnPush<Transition: AtomicTransition>: NavigationTransitionProtocol {
	private let transition: Transition

	public init(@AtomicTransitionBuilder transition: () -> Transition) {
		self.transition = transition()
	}

	public func transition(
		from fromView: TransientView,
		to toView: TransientView,
		for operation: TransitionOperation,
		in container: Container
	) {
		switch operation {
		case .push:
			transition.transition(fromView, for: .removal, in: container)
			transition.transition(toView, for: .insertion, in: container)
		case .pop:
			return
		}
	}
}

extension OnPush: Equatable where Transition: Equatable {}
extension OnPush: Hashable where Transition: Hashable {}

/// Used to define a transition that executes only on pop.
public struct OnPop<Transition: AtomicTransition>: NavigationTransitionProtocol {
	private let transition: Transition

	public init(@AtomicTransitionBuilder transition: () -> Transition) {
		self.transition = transition()
	}

	public func transition(
		from fromView: TransientView,
		to toView: TransientView,
		for operation: TransitionOperation,
		in container: Container
	) {
		switch operation {
		case .push:
			return
		case .pop:
			transition.transition(fromView, for: .removal, in: container)
			transition.transition(toView, for: .insertion, in: container)
		}
	}
}

extension OnPop: Equatable where Transition: Equatable {}
extension OnPop: Hashable where Transition: Hashable {}
