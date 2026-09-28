import SwiftUI
import Anylocale

struct ContentView: View {

    // This will automatically re-render the view when
    // the localization cache is updated from a CDN.
    @StateObject private var updater = AnylocaleSwiftUIUpdater()

    @Environment(\.locale) var locale

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack {
                AnylocaleText("Language switcher:")
                LanguagePicker(onLanguageChange: { language in
                    Task {
                        if let language {
                            try Anylocale.shared.setCustomLocale(Locale(identifier: language))
                        } else {
                            try Anylocale.shared.setCustomLocale(.current)
                        }

                        await Anylocale.shared.remoteFetch()
                    }
                })
                .pickerStyle(.menu)
            }

            Divider()

            // Use AnylocaleText instead of Text for convenience
            AnylocaleText("My name is %@ and I have %lld apples", "John", 3)

            // Use the SDK directly
            // note: the locale param is only used for SwiftUI preview purposes
            Text(Anylocale.shared.translate("My name is %@ and I have %lld apples", "John", 3, locale: locale))

            // Plain SwiftUI Text, served by the SDK because the scheme sets ANYLOCALE_ENABLE_SWIZZLING=true
            Text("Hello")

            Divider()

            // Keys published by the local anylocale server (see README, "Local server").
            // Each is shown through a different lookup path; the bundled value is prefixed [local]
            // so a string still coming from the bundle is visible at a glance.
            LabeledRow("AnylocaleText") { AnylocaleText("home.feels_like") }
            LabeledRow("Text (swizzled)") { Text("home.hourly_forecast") }
            LabeledRow("NSLocalizedString") { Text(NSLocalizedString("error.no_connection", comment: "")) }
            LabeledRow("plural, 1") { AnylocaleText("home.rain_alerts_count", 1) }
            LabeledRow("plural, 3") { AnylocaleText("home.rain_alerts_count", 3) }
        }
        .padding()
    }
}

private struct LabeledRow<Content: View>: View {
    let label: String
    let content: Content

    init(_ label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: label).font(.caption).foregroundStyle(.secondary)
            content.accessibilityIdentifier(label)
        }
    }
}

#Preview("English") {
    ContentView()
        .environment(\.locale, Locale(identifier: "en"))
}

#Preview("German") {
    ContentView()
        .environment(\.locale, Locale(identifier: "de"))
}
