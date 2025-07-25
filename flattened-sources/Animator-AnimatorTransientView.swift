import UIKit

/// An animation-transient view.
///
/// This view's interface vaguely resembles that of a `UIView`,
/// however it's scoped to a subset of animatable properties exclusively.
///
/// It also acts as a property container rather than an actual
/// view being animated, which helps compound mutating values across
/// different defined transitions before actually submitting them
/// to the animator. This helps ensure no jumpy behavior in animations occurs.
@dynamicMemberLookup
public class AnimatorTransientView {
	/// Typealias for `AnimatorTransientViewProperties`.
	public typealias Properties = AnimatorTransientViewProperties

	/// The initial set of properties that sets up the animation's initial state.
	///
	/// Use this to prepare the view before the animation starts.
	public var initial: Properties

	/// The set of property changes that get submitted to the animator.
	///
	/// Use this to define the desired animation.
	public var animation: Properties

	/// The set of property changes that occur after the animation finishes.
	///
	/// Use this to clean up any messy view state or to make any final view
	/// alterations before presentation.
	///
	/// Note: these changes are *not* animated.
	public var completion: Properties

	internal let uiView: UIView

	/// Read-only proxy to underlying `UIView` properties.
	public subscript<T>(dynamicMember keyPath: KeyPath<UIView, T>) -> T {
		uiView[keyPath: keyPath]
	}

	internal init(_ uiView: UIView) {
		self.initial = Properties(of: uiView)
		self.animation = Properties(of: uiView)
		self.completion = Properties(of: uiView)

		self.uiView = uiView
	}

	internal func setUIViewProperties(
		to properties: KeyPath<AnimatorTransientView, Properties>,
		force: Bool = false
	) {
		self[keyPath: properties].assignToUIView(uiView, force: force)
	}

	internal func resetUIViewProperties() {
		Properties.default.assignToUIView(uiView, force: true)
	}
}
