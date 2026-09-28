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
2. Replace the distribution URL in `AnylocaleSwiftUIExampleApp.swift` with your own `https://anylocale.com/ota/v1/<distribution-key>`. Until the URL answers, the fetch logs an error and every string comes from the bundle.
3. Build and run. The scheme already carries `ANYLOCALE_ENABLE_SWIZZLING=true`; remove it under Product > Scheme > Edit Scheme... > Run > Arguments to see the difference.

## Local server

The app currently points at a local anylocale server, `http://127.0.0.1:3005/ota/v1/<key>`,
with the key of a Swift distribution of the `localdev` project (locales de, en, es, fr). The
simulator reaches the Mac's loopback address directly and App Transport Security allows it,
so no Info.plist exception is needed.

The bottom section of `ContentView` shows four keys that server publishes, each through a
different lookup: `AnylocaleText("home.feels_like")`, a plain `Text("home.hourly_forecast")`
(the swizzled path), `NSLocalizedString("error.no_connection")` and the plural
`home.rain_alerts_count` with counts 1 and 3. The bundled values in `Localizable.xcstrings`
are prefixed `[local]`, so a string that still comes from the bundle is visible at a glance.
Launch with `-AppleLanguages "(de)"` to see the German file instead of the English one:

```bash
SIMCTL_CHILD_ANYLOCALE_ENABLE_SWIZZLING=true xcrun simctl launch --terminate-running-process \
  booted com.anylocale.AnylocaleSwiftUIExample -AppleLanguages "(de)" -AppleLocale de_DE
```
