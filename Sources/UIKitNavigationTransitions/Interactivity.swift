public import NavigationTransition

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
