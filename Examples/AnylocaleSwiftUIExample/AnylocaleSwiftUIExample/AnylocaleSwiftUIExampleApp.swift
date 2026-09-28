import SwiftUI
import Anylocale

@main
struct AnylocaleSwiftUIExampleApp: App {

    init() {
        Anylocale.shared.initialize(
            cdn: URL(string: "http://127.0.0.1:3005/ota/v1/dk_25cfd507a4b20f8bba75ca1520f7e5b19c5f5a3271644059e554e1da3ed660ca")!,
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
