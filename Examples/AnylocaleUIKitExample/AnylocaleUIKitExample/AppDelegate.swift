import Anylocale
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        Anylocale.shared.initialize(
            cdn: URL(string: "https://anylocale.com/ota/v1/your-distribution-key")!,
            enableDebugLogs: true)

        Task {
            for await _ in Anylocale.shared.onTranslationsUpdated() {
                // Gets triggered when the translation cache is updated
            }

            for await logMessage in Anylocale.shared.onLogMessage() {
                // Here you can forward logs from Anylocale SDK to your analytics SDK.
            }
        }

        return true
    }
}
