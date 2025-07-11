// import NavigationTransition - removed (flattened)
// import RuntimeAssociation - removed (flattened)
// import RuntimeSwizzling - removed (flattened)
import UIKit

public struct UISplitViewControllerColumns: OptionSet {
	public static let primary = Self(rawValue: 1)
	public static let supplementary = Self(rawValue: 1 << 1)
	public static let secondary = Self(rawValue: 1 << 2)

	public static let compact = Self(rawValue: 1 << 3)

	public static let all: Self = [compact, primary, supplementary, secondary]

	public let rawValue: Int8

	public init(rawValue: Int8) {
		self.rawValue = rawValue
	}
}

extension UISplitViewController {
	public func setNavigationTransition(
		_ transition: AnyNavigationTransition,
		forColumns columns: UISplitViewControllerColumns,
		interactivity: AnyNavigationTransition.Interactivity = .default
	) {
		if columns.contains(.compact), let compact = compactViewController as? UINavigationController {
			compact.setNavigationTransition(transition, interactivity: interactivity)
		}
		if columns.contains(.primary), let primary = primaryViewController as? UINavigationController {
			primary.setNavigationTransition(transition, interactivity: interactivity)
		}
		if columns.contains(.supplementary),
			let supplementary = supplementaryViewController as? UINavigationController
		{
			supplementary.setNavigationTransition(transition, interactivity: interactivity)
		}
		if columns.contains(.secondary),
			let secondary = secondaryViewController as? UINavigationController
		{
			secondary.setNavigationTransition(transition, interactivity: interactivity)
		}
	}
}

extension UISplitViewController {
	var compactViewController: UIViewController? {
		if #available(iOS 14, tvOS 14, *) {
			viewController(for: .compact)
		} else {
			if isCollapsed {
				viewControllers.first
			} else {
				nil
			}
		}
	}

	var primaryViewController: UIViewController? {
		if #available(iOS 14, tvOS 14, *) {
			viewController(for: .primary)
		} else {
			if !isCollapsed {
				viewControllers.first
			} else {
				nil
			}
		}
	}

	var supplementaryViewController: UIViewController? {
		if #available(iOS 14, tvOS 14, *) {
			viewController(for: .supplementary)
		} else {
			if !isCollapsed {
				if viewControllers.count >= 3 {
					viewControllers[safe: 1]
				} else {
					nil
				}
			} else {
				nil
			}
		}
	}

	var secondaryViewController: UIViewController? {
		if #available(iOS 14, tvOS 14, *) {
			viewController(for: .secondary)
		} else {
			if !isCollapsed {
				if viewControllers.count >= 3 {
					viewControllers[safe: 2]
				} else {
					viewControllers[safe: 1]
				}
			} else {
				nil
			}
		}
	}
}

extension RandomAccessCollection where Index == Int {
	subscript(safe index: Index) -> Element? {
		self.dropFirst(index).first
	}
}

extension UINavigationController {
	private var defaultDelegate: (any UINavigationControllerDelegate)! {
		get { self[runtimeAssociatedValue: #function] }
		set { self[runtimeAssociatedValue: #function] = newValue }
	}

	var customDelegate: NavigationTransitionDelegate! {
		get { self[runtimeAssociatedValue: #function] }
		set {
			self[runtimeAssociatedValue: #function] = newValue
			delegate = newValue
		}
	}

	public func setNavigationTransition(
		_ transition: AnyNavigationTransition,
		interactivity: AnyNavigationTransition.Interactivity = .default
	) {
		if defaultDelegate == nil {
			defaultDelegate = delegate
		}

		if customDelegate == nil {
			customDelegate = NavigationTransitionDelegate(
				transition: transition, baseDelegate: defaultDelegate)
		} else {
			customDelegate.transition = transition
		}

		swizzle(
			UINavigationController.self,
			#selector(UINavigationController.setViewControllers),
			#selector(UINavigationController.setViewControllers_animateIfNeeded)
		)

		swizzle(
			UINavigationController.self,
			#selector(UINavigationController.pushViewController),
			#selector(UINavigationController.pushViewController_animateIfNeeded)
		)

		swizzle(
			UINavigationController.self,
			#selector(UINavigationController.popViewController),
			#selector(UINavigationController.popViewController_animateIfNeeded)
		)

		swizzle(
			UINavigationController.self,
			#selector(UINavigationController.popToViewController),
			#selector(UINavigationController.popToViewController_animateIfNeeded)
		)

		swizzle(
			UINavigationController.self,
			#selector(UINavigationController.popToRootViewController),
			#selector(UINavigationController.popToRootViewController_animateIfNeeded)
		)

		#if !os(tvOS) && !os(visionOS)
			if defaultEdgePanRecognizer.strongDelegate == nil {
				defaultEdgePanRecognizer.strongDelegate = NavigationGestureRecognizerDelegate(
					controller: self)
			}

			if defaultPanRecognizer == nil {
				defaultPanRecognizer = UIPanGestureRecognizer()
				defaultPanRecognizer.targets = defaultEdgePanRecognizer.targets  // https://stackoverflow.com/a/60526328/1922543
				defaultPanRecognizer.strongDelegate = NavigationGestureRecognizerDelegate(controller: self)
				view.addGestureRecognizer(defaultPanRecognizer)
			}

			if edgePanRecognizer == nil {
				edgePanRecognizer = UIScreenEdgePanGestureRecognizer()
				if interactivity == .edgePanVertical {
					edgePanRecognizer.edges = .top
					edgePanRecognizer.addTarget(self, action: #selector(handleVerticalInteraction))
				} else {
					edgePanRecognizer.edges = .left
					edgePanRecognizer.addTarget(self, action: #selector(handleInteraction))
				}
				edgePanRecognizer.strongDelegate = NavigationGestureRecognizerDelegate(controller: self)
				view.addGestureRecognizer(edgePanRecognizer)
			}

			if panRecognizer == nil {
				panRecognizer = UIPanGestureRecognizer()
				if interactivity == .panVertical {
					print("panVertical")
					panRecognizer.addTarget(self, action: #selector(handleVerticalInteraction))
				} else {
					panRecognizer.addTarget(self, action: #selector(handleInteraction))
				}
				panRecognizer.strongDelegate = NavigationGestureRecognizerDelegate(controller: self)
				view.addGestureRecognizer(panRecognizer)
			}

			switch interactivity {
			case .disabled:
				exclusivelyEnableGestureRecognizer(.none)
			case .edgePan, .edgePanVertical:
				exclusivelyEnableGestureRecognizer(
					transition.isDefault ? defaultEdgePanRecognizer : edgePanRecognizer)
			case .pan, .panVertical:
				exclusivelyEnableGestureRecognizer(
					transition.isDefault ? defaultPanRecognizer : panRecognizer)
			}

		#endif
	}

	@available(tvOS, unavailable)
	@available(visionOS, unavailable)
	private func exclusivelyEnableGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer?) {
		for recognizer in [
			defaultEdgePanRecognizer!, defaultPanRecognizer!, edgePanRecognizer!, panRecognizer!,
		] {
			if let gestureRecognizer, recognizer === gestureRecognizer {
				recognizer.isEnabled = true
			} else {
				recognizer.isEnabled = false
			}
		}
	}
}

extension UINavigationController {
	@objc private func setViewControllers_animateIfNeeded(
		_ viewControllers: [UIViewController], animated: Bool
	) {
		if let transitionDelegate = customDelegate {
			setViewControllers_animateIfNeeded(
				viewControllers, animated: transitionDelegate.transition.animation != nil)
		} else {
			setViewControllers_animateIfNeeded(viewControllers, animated: animated)
		}
	}

	@objc private func pushViewController_animateIfNeeded(
		_ viewController: UIViewController, animated: Bool
	) {
		if let transitionDelegate = customDelegate {
			pushViewController_animateIfNeeded(
				viewController, animated: transitionDelegate.transition.animation != nil)
		} else {
			pushViewController_animateIfNeeded(viewController, animated: animated)
		}
	}

	@objc private func popViewController_animateIfNeeded(animated: Bool) -> UIViewController? {
		if let transitionDelegate = customDelegate {
			popViewController_animateIfNeeded(animated: transitionDelegate.transition.animation != nil)
		} else {
			popViewController_animateIfNeeded(animated: animated)
		}
	}

	@objc private func popToViewController_animateIfNeeded(
		_ viewController: UIViewController, animated: Bool
	) -> [UIViewController]? {
		if let transitionDelegate = customDelegate {
			popToViewController_animateIfNeeded(
				viewController, animated: transitionDelegate.transition.animation != nil)
		} else {
			popToViewController_animateIfNeeded(viewController, animated: animated)
		}
	}

	@objc private func popToRootViewController_animateIfNeeded(animated: Bool) -> UIViewController? {
		if let transitionDelegate = customDelegate {
			popToRootViewController_animateIfNeeded(
				animated: transitionDelegate.transition.animation != nil)
		} else {
			popToRootViewController_animateIfNeeded(animated: animated)
		}
	}
}

@available(tvOS, unavailable)
@available(visionOS, unavailable)
extension UINavigationController {
	var defaultEdgePanRecognizer: UIScreenEdgePanGestureRecognizer! {
		interactivePopGestureRecognizer as? UIScreenEdgePanGestureRecognizer
	}

	var defaultPanRecognizer: UIPanGestureRecognizer! {
		get { self[runtimeAssociatedValue: #function] }
		set { self[runtimeAssociatedValue: #function] = newValue }
	}

	var edgePanRecognizer: UIScreenEdgePanGestureRecognizer! {
		get { self[runtimeAssociatedValue: #function] }
		set { self[runtimeAssociatedValue: #function] = newValue }
	}

	var panRecognizer: UIPanGestureRecognizer! {
		get { self[runtimeAssociatedValue: #function] }
		set { self[runtimeAssociatedValue: #function] = newValue }
	}
}

@available(tvOS, unavailable)
extension UIGestureRecognizer {
	var strongDelegate: (any UIGestureRecognizerDelegate)? {
		get { self[runtimeAssociatedValue: #function] }
		set {
			self[runtimeAssociatedValue: #function] = newValue
			delegate = newValue
		}
	}

	var targets: Any? {
		get {
			value(forKey: #function)
		}
		set {
			if let newValue {
				setValue(newValue, forKey: #function)
			} else {
				setValue(NSMutableArray(), forKey: #function)
			}
		}
	}
}

@available(tvOS, unavailable)
final class NavigationGestureRecognizerDelegate: NSObject, UIGestureRecognizerDelegate {
	private unowned let navigationController: UINavigationController

	init(controller: UINavigationController) {
		self.navigationController = controller
	}

	// TODO: swizzle instead
	func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		let isNotOnRoot = navigationController.viewControllers.count > 1
		let noModalIsPresented = navigationController.presentedViewController == nil  // TODO: check if this check is still needed after iOS 17 public release
		return isNotOnRoot && noModalIsPresented
	}
}
