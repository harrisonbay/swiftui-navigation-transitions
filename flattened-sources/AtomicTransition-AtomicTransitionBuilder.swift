@resultBuilder
public enum AtomicTransitionBuilder {
	public static func buildBlock() -> AtomicTransitionIdentity {
		AtomicTransitionIdentity()
	}

	public static func buildPartialBlock<T1: AtomicTransition>(first: T1) -> T1 {
		first
	}

	public static func buildPartialBlock<T1: AtomicTransition, T2: AtomicTransition>(accumulated: T1, next: T2) -> AtomicTransitionCombined<T1, T2> {
		AtomicTransitionCombined(accumulated, next)
	}

	public static func buildOptional<T: AtomicTransition>(_ component: T?) -> _AtomicOptionalTransition<T> {
		if let component {
			_AtomicOptionalTransition(component)
		} else {
			_AtomicOptionalTransition(nil)
		}
	}

	public static func buildEither<TrueTransition: AtomicTransition, FalseTransition: AtomicTransition>(first component: TrueTransition) -> _AtomicConditionalTransition<TrueTransition, FalseTransition> {
		_AtomicConditionalTransition(trueTransition: component)
	}

	public static func buildEither<TrueTransition: AtomicTransition, FalseTransition: AtomicTransition>(second component: FalseTransition) -> _AtomicConditionalTransition<TrueTransition, FalseTransition> {
		_AtomicConditionalTransition(falseTransition: component)
	}
}

public struct _AtomicOptionalTransition<Transition: AtomicTransition>: AtomicTransition {
	private let transition: Transition?

	init(_ transition: Transition?) {
		self.transition = transition
	}

	public func transition(_ view: TransientView, for operation: TransitionOperation, in container: Container) {
		transition?.transition(view, for: operation, in: container)
	}
}

extension _AtomicOptionalTransition: MirrorableAtomicTransition where Transition: MirrorableAtomicTransition {
	public func mirrored() -> _AtomicOptionalTransition<Transition.Mirrored> {
		.init(transition?.mirrored())
	}
}

extension _AtomicOptionalTransition: Equatable where Transition: Equatable {}
extension _AtomicOptionalTransition: Hashable where Transition: Hashable {}

public struct _AtomicConditionalTransition<TrueTransition: AtomicTransition, FalseTransition: AtomicTransition>: AtomicTransition {
	private typealias Transition = _Either<TrueTransition, FalseTransition>
	private let transition: Transition

	init(trueTransition: TrueTransition) {
		self.transition = .left(trueTransition)
	}

	init(falseTransition: FalseTransition) {
		self.transition = .right(falseTransition)
	}

	public func transition(_ view: TransientView, for operation: TransitionOperation, in container: Container) {
		switch transition {
		case .left(let trueTransition):
			trueTransition.transition(view, for: operation, in: container)
		case .right(let falseTransition):
			falseTransition.transition(view, for: operation, in: container)
		}
	}
}

extension _AtomicConditionalTransition: MirrorableAtomicTransition where TrueTransition: MirrorableAtomicTransition, FalseTransition: MirrorableAtomicTransition {
	public func mirrored() -> _AtomicConditionalTransition<TrueTransition.Mirrored, FalseTransition.Mirrored> {
		switch transition {
		case .left(let trueTransition):
			.init(trueTransition: trueTransition.mirrored())
		case .right(let falseTransition):
			.init(falseTransition: falseTransition.mirrored())
		}
	}
}

extension _AtomicConditionalTransition: Equatable where TrueTransition: Equatable, FalseTransition: Equatable {}
extension _AtomicConditionalTransition: Hashable where TrueTransition: Hashable, FalseTransition: Hashable {}

private enum _Either<Left, Right> {
	case left(Left)
	case right(Right)
}

extension _Either: Equatable where Left: Equatable, Right: Equatable {}
extension _Either: Hashable where Left: Hashable, Right: Hashable {}
