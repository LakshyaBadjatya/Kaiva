import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

    override func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        super.scene(scene, willConnectTo: session, options: connectionOptions)

        // Wire up the Live Activity Flutter channel once we have a window + controller.
        if let windowScene = scene as? UIWindowScene,
           let window = windowScene.windows.first,
           let controller = window.rootViewController as? FlutterViewController,
           let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.setupLiveActivityChannel(controller: controller)
        }
    }
}
