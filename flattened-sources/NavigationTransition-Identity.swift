// For internal use only.
struct NavigationTransitionIdentity: NavigationTransitionProtocol {
	init() {}

	func transition(
		from fromView: TransientView,
		to toView: TransientView,
		for operation: TransitionOperation,
		in container: Container
	) {
		// NO-OP
	}
}

extension NavigationTransitionIdentity: Hashable {}
