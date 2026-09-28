import SwiftUI
import Anylocale

enum LanguageOption: Hashable {
    case system
    case language(String)
}

struct LanguagePicker: View {
    @State private var selectedOption: LanguageOption = .system
    
    let availableLanguages: [String]
    let onLanguageChange: ((String?) -> Void)?
    
    init(onLanguageChange: ((String?) -> Void)? = nil) {
        self.availableLanguages = Bundle.main.localizations
        self.onLanguageChange = onLanguageChange
    }
    
    var body: some View {
        Picker("Language", selection: $selectedOption) {
            AnylocaleText("System Default")
                .tag(LanguageOption.system)
            
            ForEach(availableLanguages, id: \.self) { languageCode in
                let languageName = languageCode.uppercased()
                Text(languageName)
                    .tag(LanguageOption.language(languageCode))
            }
        }
        .onChange(of: selectedOption) { value in
            switch value {
            case .system:
                onLanguageChange?(nil)
            case .language(let code):
                onLanguageChange?(code)
            }
        }
    }
}

#Preview {
    Form {
        LanguagePicker()
    }
}
