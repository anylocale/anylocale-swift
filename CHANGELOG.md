# Changelog

## Unreleased

- First release of the anylocale Swift SDK: over-the-air strings for iOS,
  macOS, tvOS and watchOS from an anylocale distribution key.
- Swizzling covers `Bundle.localizedString(forKey:value:table:)` and
  `Bundle.localizedAttributedString(forKey:value:table:)`, so `NSLocalizedString`,
  storyboards, and SwiftUI `Text("key")`, `Button("key")`, `Label` and other
  `LocalizedStringKey` lookups resolve through the SDK. Remote translations are
  rendered as inline markdown where the OS supports it. Opt in with
  `ANYLOCALE_ENABLE_SWIZZLING=true`.
