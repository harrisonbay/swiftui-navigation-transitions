internal import UIKit

extension UINavigationController {
	@objc func handleInteraction(_ gestureRecognizer: UIPanGestureRecognizer, isVertical: Bool = false) {
		guard let delegate = customDelegate else {
			return
		}
		guard let gestureRecognizerView = gestureRecognizer.view else {
			delegate.interactionController = nil
			return
		}

		let translation = isVertical ? gestureRecognizer.translation(in: gestureRecognizerView).y : gestureRecognizer.translation(in: gestureRecognizerView).x
		let dimension = isVertical ? gestureRecognizerView.bounds.size.height : gestureRecognizerView.bounds.size.width
		let percent = translation / dimension

		switch gestureRecognizer.state {
		case .possible:
			break

		case .began:
			delegate.interactionController = UIPercentDrivenInteractiveTransition()
			popViewController(animated: true)
			delegate.interactionController?.update(percent)

		case .changed:
			delegate.interactionController?.update(percent)

		case .ended:
			let velocity = isVertical ? gestureRecognizer.velocity(in: gestureRecognizerView).y : gestureRecognizer.velocity(in: gestureRecognizerView).x

			if velocity > 675 || (percent >= 0.2 && velocity > -200) {
				let resistance: Double = 800
				let maxSpeed: Double = 2.25
				let nominalSpeed = max(0.99, velocity / resistance)
				let speed = min(nominalSpeed, maxSpeed)

				delegate.interactionController?.completionSpeed = speed
				delegate.interactionController?.finish()
			} else {
				delegate.interactionController?.cancel()
			}

			delegate.interactionController = nil

		case .failed, .cancelled:
			delegate.interactionController?.cancel()
			delegate.interactionController = nil

		@unknown default:
			break
		}
	}
	
	@objc func handleVerticalInteraction(_ gestureRecognizer: UIPanGestureRecognizer) {
		handleInteraction(gestureRecognizer, isVertical: true)
	}
}
