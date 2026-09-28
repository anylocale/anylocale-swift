import SwiftUI
import Anylocale

@main
struct AnylocaleSwiftUIExampleApp: App {

    init() {
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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await Anylocale.shared.remoteFetch()
                }
        }
    }
}
