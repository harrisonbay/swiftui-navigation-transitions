import UIKit

final class NavigationTransitionDelegate: NSObject, UINavigationControllerDelegate {
	var transition: AnyNavigationTransition
	private weak var baseDelegate: (any UINavigationControllerDelegate)?
	var interactionController: UIPercentDrivenInteractiveTransition?

	init(transition: AnyNavigationTransition, baseDelegate: (any UINavigationControllerDelegate)?) {
		self.transition = transition
		self.baseDelegate = baseDelegate
	}

	func navigationController(
		_ navigationController: UINavigationController, willShow viewController: UIViewController,
		animated: Bool
	) {
		baseDelegate?.navigationController?(
			navigationController, willShow: viewController, animated: animated)
	}

	func navigationController(
		_ navigationController: UINavigationController, didShow viewController: UIViewController,
		animated: Bool
	) {
		baseDelegate?.navigationController?(
			navigationController, didShow: viewController, animated: animated)
	}

	func navigationController(
		_ navigationController: UINavigationController,
		interactionControllerFor animationController: any UIViewControllerAnimatedTransitioning
	) -> (any UIViewControllerInteractiveTransitioning)? {
		if !transition.isDefault {
			interactionController
		} else {
			nil
		}
	}

	func navigationController(
		_ navigationController: UINavigationController,
		animationControllerFor operation: UINavigationController.Operation,
		from fromVC: UIViewController, to toVC: UIViewController
	) -> (any UIViewControllerAnimatedTransitioning)? {
		if !transition.isDefault,
			let animation = transition.animation,
			let operation = NavigationTransitionOperation(operation)
		{
			NavigationTransitionAnimatorProvider(
				transition: transition,
				animation: animation,
				operation: operation
			)
		} else {
			nil
		}
	}
}

final class NavigationTransitionAnimatorProvider: NSObject, UIViewControllerAnimatedTransitioning {
	let transition: AnyNavigationTransition
	let animation: SwiftUINavigationTransitionAnimation
	let operation: NavigationTransitionOperation

	init(
		transition: AnyNavigationTransition, animation: SwiftUINavigationTransitionAnimation,
		operation: NavigationTransitionOperation
	) {
		self.transition = transition
		self.animation = animation
		self.operation = operation
	}

	func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?)
		-> TimeInterval
	{
		animation.duration
	}

	func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
		transitionAnimator(for: transitionContext).startAnimation()
	}

	func interruptibleAnimator(using transitionContext: any UIViewControllerContextTransitioning)
		-> any UIViewImplicitlyAnimating
	{
		transitionAnimator(for: transitionContext)
	}

	func animationEnded(_ transitionCompleted: Bool) {
		cachedAnimators.removeAll(keepingCapacity: true)
	}

	private var cachedAnimators: [ObjectIdentifier: UIViewPropertyAnimator] = .init(
		minimumCapacity: 1)

	private func transitionAnimator(for transitionContext: any UIViewControllerContextTransitioning)
		-> UIViewPropertyAnimator
	{
		if let cached = cachedAnimators[ObjectIdentifier(transitionContext)] {
			return cached
		}
		let animator = UIViewPropertyAnimator(
			duration: transitionDuration(using: transitionContext),
			timingParameters: animation.timingParameters
		)
		cachedAnimators[ObjectIdentifier(transitionContext)] = animator

		let container = transitionContext.containerView
		guard
			let fromUIView = transitionContext.view(forKey: .from),
			let toUIView = transitionContext.view(forKey: .to)
		else {
			return animator
		}

		fromUIView.isUserInteractionEnabled = false
		toUIView.isUserInteractionEnabled = false

		switch transition.handler {
		case .transient(let handler):
			if let (fromView, toView) = transientViews(
				for: handler,
				animator: animator,
				context: (container, fromUIView, toUIView)
			) {
				for view in [fromView, toView] {
					view.setUIViewProperties(to: \.initial)
					animator.addAnimations { view.setUIViewProperties(to: \.animation) }
					animator.addCompletion { _ in
						if transitionContext.transitionWasCancelled {
							view.resetUIViewProperties()
						} else {
							view.setUIViewProperties(to: \.completion)
						}
					}
				}
			}
		case .primitive(let handler):
			handler(animator, operation, transitionContext)
		}

		animator.addCompletion { _ in
			transitionContext.completeTransition(!transitionContext.transitionWasCancelled)

			fromUIView.isUserInteractionEnabled = true
			toUIView.isUserInteractionEnabled = true

			// iOS 16 workaround to nudge views into becoming responsive after transition
			if transitionContext.transitionWasCancelled {
				fromUIView.removeFromSuperview()
				container.addSubview(fromUIView)
			} else {
				toUIView.removeFromSuperview()
				container.addSubview(toUIView)
			}
		}

		return animator
	}

	private func transientViews(
		for handler: AnyNavigationTransition.TransientHandler,
		animator: any SwiftUINavigationTransitionAnimator,
		context: (container: UIView, fromUIView: UIView, toUIView: UIView)
	) -> (fromView: AnimatorTransientView, toView: AnimatorTransientView)? {
		let (container, fromUIView, toUIView) = context

		switch operation {
		case .push:
			container.insertSubview(toUIView, aboveSubview: fromUIView)
		case .pop:
			container.insertSubview(toUIView, belowSubview: fromUIView)
		}

		let fromView = AnimatorTransientView(fromUIView)
		let toView = AnimatorTransientView(toUIView)

		handler(fromView, toView, operation, container)

		return (fromView, toView)
	}
}
