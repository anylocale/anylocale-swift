import SwiftUI
import Anylocale

struct ContentView: View {
    
    // This will automatically re-render the view when
    // the localization cache is updated from a CDN.
    @StateObject private var updater = AnylocaleSwiftUIUpdater()
    
    @Environment(\.locale) var locale
    
    var body: some View {
        VStack(spacing: 20) {
            
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
        }
        .padding()
    }
}

#Preview("English") {
    ContentView()
        .environment(\.locale, Locale(identifier: "en"))
}

#Preview("Czech") {
    ContentView()
        .environment(\.locale, Locale(identifier: "cs"))
}
