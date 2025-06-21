@resultBuilder
public enum NavigationTransitionBuilder {
	public static func buildPartialBlock<T1: NavigationTransitionProtocol>(first: T1) -> T1 {
		first
	}

	public static func buildPartialBlock<T1: NavigationTransitionProtocol, T2: NavigationTransitionProtocol>(accumulated: T1, next: T2) -> NavigationTransitionCombined<T1, T2> {
		NavigationTransitionCombined(accumulated, next)
	}

	public static func buildOptional<T: NavigationTransitionProtocol>(_ component: T?) -> _NavigationOptionalTransition<T> {
		if let component {
			_NavigationOptionalTransition(component)
		} else {
			_NavigationOptionalTransition(nil)
		}
	}

	public static func buildEither<TrueTransition: NavigationTransitionProtocol, FalseTransition: NavigationTransitionProtocol>(first component: TrueTransition) -> _NavigationConditionalTransition<TrueTransition, FalseTransition> {
		_NavigationConditionalTransition(trueTransition: component)
	}

	public static func buildEither<TrueTransition: NavigationTransitionProtocol, FalseTransition: NavigationTransitionProtocol>(second component: FalseTransition) -> _NavigationConditionalTransition<TrueTransition, FalseTransition> {
		_NavigationConditionalTransition(falseTransition: component)
	}
}

public struct _NavigationOptionalTransition<Transition: NavigationTransitionProtocol>: NavigationTransitionProtocol {
	private let transition: Transition?

	init(_ transition: Transition?) {
		self.transition = transition
	}

	public func transition(
		from fromView: TransientView,
		to toView: TransientView,
		for operation: TransitionOperation,
		in container: Container
	) {
		transition?.transition(from: fromView, to: toView, for: operation, in: container)
	}
}

public struct _NavigationConditionalTransition<TrueTransition: NavigationTransitionProtocol, FalseTransition: NavigationTransitionProtocol>: NavigationTransitionProtocol {
	private typealias Transition = _Either<TrueTransition, FalseTransition>
	private let transition: Transition

	init(trueTransition: TrueTransition) {
		self.transition = .left(trueTransition)
	}

	init(falseTransition: FalseTransition) {
		self.transition = .right(falseTransition)
	}

	public func transition(
		from fromView: TransientView,
		to toView: TransientView,
		for operation: TransitionOperation,
		in container: Container
	) {
		switch transition {
		case .left(let trueTransition):
			trueTransition.transition(from: fromView, to: toView, for: operation, in: container)
		case .right(let falseTransition):
			falseTransition.transition(from: fromView, to: toView, for: operation, in: container)
		}
	}
}

private enum _Either<Left, Right> {
	case left(Left)
	case right(Right)
}

extension _Either: Equatable where Left: Equatable, Right: Equatable {}
extension _Either: Hashable where Left: Hashable, Right: Hashable {}
