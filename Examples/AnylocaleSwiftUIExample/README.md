# Anylocale SwiftUI Example

A SwiftUI app using the Anylocale SDK.

## What it shows

- Initializing the SDK with a distribution URL and debug logging (`AnylocaleSwiftUIExampleApp.swift`)
- Fetching remote translations with `remoteFetch()`
- `AnylocaleText` for translated text that re-renders on updates
- `Anylocale.shared.translate()` with the `locale` parameter, so SwiftUI previews render in several languages
- Swizzling: a plain `Text("Hello")` resolved through the SDK because the shared scheme sets `ANYLOCALE_ENABLE_SWIZZLING=true`
- Switching languages at runtime with `setCustomLocale()` (`LanguagePicker.swift`)
- `AnylocaleSwiftUIUpdater`, `onTranslationsUpdated()` and `onLogMessage()`

`Localizable.xcstrings` holds the bundled fallback strings.

## Running it

1. Open `AnylocaleSwiftUIExample.xcodeproj`; it references the SDK package at the repository root.
2. Replace the placeholder distribution URL in `AnylocaleSwiftUIExampleApp.swift` with your own `https://anylocale.com/ota/v1/<distribution-key>`. Until you do, the fetch logs an HTTP 404 and every string comes from the bundle.
3. Build and run. The scheme already carries `ANYLOCALE_ENABLE_SWIZZLING=true`; remove it under Product > Scheme > Edit Scheme... > Run > Arguments to see the difference.
