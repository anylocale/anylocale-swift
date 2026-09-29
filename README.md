# Anylocale Swift SDK

Over-the-air localization for iOS, macOS, tvOS and watchOS apps. Your app ships
its `.xcstrings` / `.strings` files as usual; the SDK downloads updated
translations from your anylocale distribution, caches them on the device and
serves them either through its own API or, when enabled, through Apple's own
`NSLocalizedString` and SwiftUI `Text` lookups.

## Requirements

| Platform | Minimum version |
| -------- | --------------- |
| iOS      | 16.0            |
| macOS    | 13.0            |
| tvOS     | 16.0            |
| watchOS  | 6.0             |

Swift 6.0 and Xcode 16 or newer.

## Installation

Swift Package Manager, in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/anylocale/anylocale-swift", from: "1.1.0")
]
```

Or in Xcode: File > Add Package Dependencies..., enter
`https://github.com/anylocale/anylocale-swift`, and add the `Anylocale` library
to your target.

## Initialisation

Every anylocale distribution has a URL of the form
`https://anylocale.com/ota/v1/<distribution-key>`. Pass it once, early in the
app's life, then fetch:

```swift
import Anylocale

Anylocale.shared.initialize(
    cdn: URL(string: "https://anylocale.com/ota/v1/<distribution-key>")!)

await Anylocale.shared.remoteFetch()
```

`initialize` loads whatever is already cached on the device synchronously.
`remoteFetch` downloads the current language (and every configured namespace)
from the distribution, honouring ETags, and updates the cache and the in-memory
translations. Call it again whenever you want to pick up changes, for example
when the app returns to the foreground.

All options:

```swift
Anylocale.shared.initialize(
    cdn: URL(string: "https://anylocale.com/ota/v1/<distribution-key>")!,
    locale: Locale(identifier: "pt_BR"),     // override the system locale
    language: "pt-BR",                       // override the language code used on the CDN
    namespaces: ["buttons", "errors"],       // additional string tables, see below
    enableDebugLogs: true
)
```

## Usage

```swift
let title = Anylocale.shared.translate("app_title")
let greeting = Anylocale.shared.translate("welcome_user", "John")
let count = Anylocale.shared.translate("items_count", 5)
let both = Anylocale.shared.translate("My name is %@ and I'm %lld years old", "John", 30)
```

Arguments are `CVarArg` and are formatted with the active locale. When the key
is not in the remote translations, the lookup falls back to the bundled
localization, so a partially translated distribution still works.

### Plurals

Plural forms are chosen by CLDR rules for the active locale, using the first
numeric argument. A string with more than one pluralized parameter (for example
`"I have %lld apples and %lld oranges"`) is not supported.

### Tables and namespaces

Strings in a table other than `Localizable` are addressed with `table:`. For
`.xcstrings` files the table name is the file name without the extension. To
have those tables updated over the air, list them as `namespaces` when
initializing; the SDK then fetches `<namespace>/<language>.json` for each.

```swift
Anylocale.shared.initialize(cdn: cdnURL, namespaces: ["common", "auth"])

let hello = Anylocale.shared.translate("hello", table: "common")
AnylocaleText("hello", tableName: "common")
```

### Custom bundles

When the strings live in a framework or a Swift package rather than the main
bundle:

```swift
let hello = Anylocale.shared.translate("hello", bundle: someBundle)
AnylocaleText("hello", bundle: someBundle)
```

## SwiftUI

`AnylocaleText` is a `Text` that re-renders when translations change and
respects the environment locale, which makes previews in several languages
straightforward:

```swift
import SwiftUI
import Anylocale

struct ContentView: View {
    var body: some View {
        AnylocaleText("welcome_title")
    }
}

#Preview("English") {
    ContentView().environment(\.locale, Locale(identifier: "en"))
}

#Preview("Czech") {
    ContentView().environment(\.locale, Locale(identifier: "cs"))
}
```

`translate(...)` also takes a `locale:` parameter for the same purpose:

```swift
struct ContentView: View {
    @Environment(\.locale) var locale

    var body: some View {
        Text(Anylocale.shared.translate("welcome_title", locale: locale))
    }
}
```

The `locale` parameter is meant for previews. When it differs from the current
locale, remote translations are ignored and only bundled strings are used. A
custom locale set on the SDK (`initialize(locale:)` or `setCustomLocale`) takes
precedence over it.

## Reactive updates

`onTranslationsUpdated()` yields after every successful `remoteFetch` and every
locale change:

```swift
Task {
    for await _ in Anylocale.shared.onTranslationsUpdated() {
        // refresh your UI
    }
}
```

`AnylocaleText` subscribes to it on its own. For views that call `translate`
directly, `AnylocaleSwiftUIUpdater` re-renders the view on every update:

```swift
struct ContentView: View {
    @StateObject private var updater = AnylocaleSwiftUIUpdater()

    var body: some View {
        Text(Anylocale.shared.translate("welcome_title"))
    }
}
```

## Swizzling Apple's lookups

Optionally, the SDK can serve Apple's own localization APIs, so existing code
and plain SwiftUI views pick up remote translations without being rewritten.
Pass `enableSwizzling: true` to `initialize`:

```swift
Anylocale.shared.initialize(cdn: cdnURL, enableSwizzling: true)
```

The environment variable `ANYLOCALE_ENABLE_SWIZZLING=true` in your scheme
(Product > Scheme > Edit Scheme... > Run > Arguments) enables it as well, for
trying it out without touching code; a scheme variable is not present in a
release build, so a shipped app uses the parameter. Two `Bundle` methods are
swizzled:

- `localizedString(forKey:value:table:)`, which backs `NSLocalizedString` and
  `String(localized:)`. Used by UIKit and AppKit code.
- `localizedAttributedString(forKey:value:table:)`, which backs
  `LocalizedStringKey`, and with it `Text("key")`, `Button("key")`,
  `Label("key", systemImage:)` and every other SwiftUI initializer that takes
  a string literal.

```swift
NSLocalizedString("welcome_message", comment: "")
Bundle.main.localizedString(forKey: "welcome_message", value: nil, table: nil)
Text("welcome_message")
```

A remote translation served through the attributed lookup is parsed as inline
markdown on iOS 15, macOS 12, tvOS 15, watchOS 8 and newer, so `**bold**` and
`*italic*` in a translation render the way they do in bundled strings. When
parsing fails, the plain string is returned. A key the distribution does not
know falls through to the original implementation, and so does a plural
string, since the lookup carries no number to choose a form with; both come
from the bundle, as before.

Both swizzles resolve the language the same way as `translate(...)`,
including a custom locale set on the SDK.

A SwiftUI view built with `Text("key")` resolves its string when it first
renders and keeps it: a translation that arrives from the network during that
session shows on the next launch, because SwiftUI does not re-resolve a
`LocalizedStringKey`. `AnylocaleText` updates in place as soon as the
download completes, and `NSLocalizedString` and `translate(...)` return the
new text on their next call. Verified with the SwiftUI example against a
local server: first launch shows the bundled string in `Text`, the relaunch
shows the remote one.

## Language override

```swift
// At initialization
Anylocale.shared.initialize(cdn: cdnURL, locale: Locale(identifier: "pt_BR"))

// At runtime, then fetch that language
try Anylocale.shared.setCustomLocale(Locale(identifier: "fr"))
await Anylocale.shared.remoteFetch()

// Back to the system language
try Anylocale.shared.setCustomLocale(.current)
await Anylocale.shared.remoteFetch()
```

The `language:` parameter on both calls overrides the language code sent to
the CDN when it differs from what the locale implies. `setCustomLocale` throws
`AnylocaleError.sdkNotInitialized` before `initialize`, and
`AnylocaleError.unsupportedLocale` for a locale the app has no localization
for.

To have every language ready before the user switches:

```swift
await withTaskGroup(of: Void.self) { group in
    for language in Bundle.main.localizations {
        group.addTask { await Anylocale.shared.remoteFetch(language: language) }
    }
}
```

## Caching

Downloads are cached per distribution, language, namespace and app version in
`Application Support/AnylocaleCache` on iOS, tvOS and watchOS, and in
`Caches/<bundle identifier>/AnylocaleCache` on macOS. ETags are stored next to
them and sent as `If-None-Match`. `clearCaches()` removes everything and
forces a full download on the next fetch.

## Logging

Logs go to the unified logging system under the subsystem
`com.anylocale.sdk`. They can also be observed, for example to forward errors
to analytics:

```swift
for await message in Anylocale.shared.onLogMessage() {
    // message.level, message.message, message.timestamp
}
```

## Thread safety

The SDK is bound to the main actor; everything except `remoteFetch` is
synchronous there. From another actor, await it:

```swift
Task.detached {
    let text = await Anylocale.shared.translate("key")
}
```

## Examples

- [SwiftUI](Examples/AnylocaleSwiftUIExample), with swizzling enabled in the scheme
- [UIKit](Examples/AnylocaleUIKitExample)

Both reference the package at the repository root and use a placeholder
distribution URL; replace it with your own to see remote translations.

## License

MIT, see [LICENSE](LICENSE).
