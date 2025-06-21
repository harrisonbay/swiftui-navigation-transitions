import SwiftUI
import UIKit

public struct AnyNavigationTransition {
	internal typealias TransientHandler = (
		AnimatorTransientView,
		AnimatorTransientView,
		NavigationTransitionOperation,
		UIView
	) -> Void

	internal typealias PrimitiveHandler = (
		any SwiftUINavigationTransitionAnimator,
		NavigationTransitionOperation,
		any UIViewControllerContextTransitioning
	) -> Void

	internal enum Handler {
		case transient(TransientHandler)
		case primitive(PrimitiveHandler)
	}

	internal let isDefault: Bool
	internal let handler: Handler
	internal var animation: SwiftUINavigationTransitionAnimation? = .default

	public init(_ transition: some NavigationTransitionProtocol) {
		self.isDefault = false
		self.handler = .transient(transition.transition(from:to:for:in:))
	}

	public init(_ transition: some PrimitiveNavigationTransition) {
		self.isDefault = transition is Default
		self.handler = .primitive(transition.transition(with:for:in:))
	}
}

public typealias _Animation = SwiftUINavigationTransitionAnimation

extension AnyNavigationTransition {
	/// Typealias for `SwiftUINavigationTransitionAnimation`.
	public typealias Animation = _Animation

	/// Attaches an animation to this transition.
	public func animation(_ animation: SwiftUINavigationTransitionAnimation?) -> Self {
		var copy = self
		copy.animation = animation
		return copy
	}
}

// MARK: - Default

extension AnyNavigationTransition {
	/// The system-default transition.
	///
	/// Use this transition if you wish to modify the interactivity of the transition without altering the
	/// system-provided transition itself. For example:
	///
	///   ```swift
	///   NavigationStack {
	///     // ...
	///   }
	///   .navigationStackTransition(.default, interactivity: .pan) // enables full-screen panning for system-provided pop
	///   ```
	///
	/// - Note: The animation for `default` cannot be customized via ``animation(_:)``.
	public static var `default`: Self {
		.init(Default())
	}
}

internal struct Default: PrimitiveNavigationTransition {
	init() {}

	internal func transition(
		with animator: any SwiftUINavigationTransitionAnimator, for operation: TransitionOperation,
		in context: any Context
	) {
		// NO-OP
	}
}

// MARK: - Fade

extension AnyNavigationTransition {
	/// A transition that fades the pushed view in, fades the popped view out, or cross-fades both views.
	public static func fade(_ style: Fade.Style) -> Self {
		.init(Fade(style))
	}
}

/// A transition that fades the pushed view in, fades the popped view out, or cross-fades both views.
public struct Fade: NavigationTransitionProtocol {
	public enum Style {
		case `in`
		case out
		case cross
	}

	private let style: Style

	public init(_ style: Style) {
		self.style = style
	}

	public var body: some NavigationTransitionProtocol {
		switch style {
		case .in:
			MirrorPush {
				OnInsertion {
					ZPosition(1)
					Opacity()
				}
			}
		case .out:
			MirrorPush {
				OnRemoval {
					ZPosition(1)
					Opacity()
				}
			}
		case .cross:
			MirrorPush {
				Opacity()
			}
		}
	}
}

extension Fade: Hashable {}

// MARK: - Slide

extension AnyNavigationTransition {
	/// A transition that moves both views in and out along the specified axis.
	///
	/// This transition:
	/// - Pushes views right-to-left and pops views left-to-right when `axis` is `horizontal`.
	/// - Pushes views bottom-to-top and pops views top-to-bottom when `axis` is `vertical`.
	public static func slide(axis: Axis) -> Self {
		.init(Slide(axis: axis))
	}
}

extension AnyNavigationTransition {
	/// Equivalent to `slide(axis: .horizontal)`.
	@inlinable
	public static var slide: Self {
		.slide(axis: .horizontal)
	}
}

/// A transition that moves both views in and out along the specified axis.
///
/// This transition:
/// - Pushes views right-to-left and pops views left-to-right when `axis` is `horizontal`.
/// - Pushes views bottom-to-top and pops views top-to-bottom when `axis` is `vertical`.
public struct Slide: NavigationTransitionProtocol {
	private let axis: Axis

	public init(axis: Axis) {
		self.axis = axis
	}

	/// Equivalent to `Move(axis: .horizontal)`.
	@inlinable
	public init() {
		self.init(axis: .horizontal)
	}

	public var body: some NavigationTransitionProtocol {
		switch axis {
		case .horizontal:
			MirrorPush {
				OnInsertion {
					Move(edge: .trailing)
				}
				OnRemoval {
					Move(edge: .leading)
				}
			}
		case .vertical:
			MirrorPush {
				OnInsertion {
					Move(edge: .bottom)
				}
				OnRemoval {
					Move(edge: .top)
				}
			}
		}
	}
}

extension Slide: Hashable {}

// MARK: - Interactivity

extension AnyNavigationTransition {
	public enum Interactivity {
		case disabled
		case edgePan
		case pan
		case edgePanVertical
		case panVertical

		@inlinable
		public static var `default`: Self {
			.edgePan
		}
	}
}
