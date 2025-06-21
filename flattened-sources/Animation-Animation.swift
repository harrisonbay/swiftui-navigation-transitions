import UIKit

public struct SwiftUINavigationTransitionAnimation {
	static var defaultDuration: Double { 0.35 }

	internal var duration: Double
	internal let timingParameters: any UITimingCurveProvider

	init(duration: Double, timingParameters: any UITimingCurveProvider) {
		self.duration = duration
		self.timingParameters = timingParameters
	}

	init(duration: Double, curve: UIView.AnimationCurve) {
		self.init(duration: duration, timingParameters: UICubicTimingParameters(animationCurve: curve))
	}
}

extension SwiftUINavigationTransitionAnimation {
	public func speed(_ speed: Double) -> Self {
		var copy = self
		copy.duration /= speed
		return copy
	}
}

// MARK: - Default
extension SwiftUINavigationTransitionAnimation {
	public static var `default`: Self {
		.init(duration: defaultDuration, curve: .easeInOut)
	}
}

// MARK: - Ease In
extension SwiftUINavigationTransitionAnimation {
	public static func easeIn(duration: Double) -> Self {
		.init(duration: duration, curve: .easeIn)
	}

	public static var easeIn: Self {
		.easeIn(duration: defaultDuration)
	}
}

// MARK: - Ease In Out
extension SwiftUINavigationTransitionAnimation {
	public static func easeInOut(duration: Double) -> Self {
		.init(duration: duration, curve: .easeInOut)
	}

	public static var easeInOut: Self {
		.easeInOut(duration: defaultDuration)
	}
}

// MARK: - Ease Out
extension SwiftUINavigationTransitionAnimation {
	public static func easeOut(duration: Double) -> Self {
		.init(duration: duration, curve: .easeOut)
	}

	public static var easeOut: Self {
		.easeOut(duration: defaultDuration)
	}
}

// MARK: - Linear
extension SwiftUINavigationTransitionAnimation {
	public static func linear(duration: Double) -> Self {
		.init(duration: duration, curve: .linear)
	}

	public static var linear: Self {
		.linear(duration: defaultDuration)
	}
}

// MARK: - Interpolating Spring
extension SwiftUINavigationTransitionAnimation {
	public static func interpolatingSpring(
		mass: Double = 1.0,
		stiffness: Double,
		damping: Double,
		initialVelocity: Double = 0.0
	) -> Self {
		.init(
			duration: defaultDuration,
			timingParameters: UISpringTimingParameters(
				mass: mass,
				stiffness: stiffness,
				damping: damping,
				initialVelocity: CGVector(dx: initialVelocity, dy: initialVelocity)
			)
		)
	}
}
// MARK: - Timing Curve

extension SwiftUINavigationTransitionAnimation {
	public static func timingCurve(
		_ c0x: Double,
		_ c0y: Double,
		_ c1x: Double,
		_ c1y: Double,
		duration: Double
	) -> Self {
		.init(
			duration: duration,
			timingParameters: UICubicTimingParameters(
				controlPoint1: CGPoint(x: c0x, y: c0y),
				controlPoint2: CGPoint(x: c1x, y: c1y)
			)
		)
	}

	public static func timingCurve(
		_ c0x: Double,
		_ c0y: Double,
		_ c1x: Double,
		_ c1y: Double
	) -> Self {
		.timingCurve(c0x, c0y, c1x, c1y, duration: defaultDuration)
	}
}
