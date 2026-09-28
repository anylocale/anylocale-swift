# Anylocale UIKit Example

A UIKit app using the Anylocale SDK.

## What it shows

- Initializing the SDK in `AppDelegate` with a distribution URL and debug logging
- Fetching remote translations with `remoteFetch()` when the scene enters the foreground (`SceneDelegate.swift`)
- `Anylocale.shared.translate()` feeding a `UILabel` (`ViewController.swift`)
- Swizzling: `NSLocalizedString` resolved through the SDK because the shared scheme sets `ANYLOCALE_ENABLE_SWIZZLING=true`
- Switching languages at runtime with `setCustomLocale()` and a segmented control
- Re-rendering on `onTranslationsUpdated()`, forwarding logs with `onLogMessage()`

`Localizable.xcstrings` holds the bundled fallback strings.

## Running it

1. Open `AnylocaleUIKitExample.xcodeproj`; it references the SDK package at the repository root.
2. Replace the placeholder distribution URL in `AppDelegate.swift` with your own `https://anylocale.com/ota/v1/<distribution-key>`. Until you do, the fetch logs an HTTP 404 and every string comes from the bundle.
3. Build and run. The scheme already carries `ANYLOCALE_ENABLE_SWIZZLING=true` (Product > Scheme > Edit Scheme... > Run > Arguments).

Pluralized strings are not served through swizzling and come from the bundle.
