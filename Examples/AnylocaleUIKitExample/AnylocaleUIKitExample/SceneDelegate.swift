import UIKit
import Anylocale

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        Task {
            await Anylocale.shared.remoteFetch()
        }
    }
}

