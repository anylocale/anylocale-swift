import Foundation
import Testing

@testable import Anylocale

@Suite(.serialized)
@MainActor
struct BundleSwizzlingTests {

    let cdnURL = URL(string: "https://cdn.example.com")!

    let cachedTranslationsJSON = """
        {
          "Hello, world!": "[remote] Hello, world!",
          "My name is %@": "[remote] My name is **%@**",
          "I have %lld apples": {
            "variations": {
              "plural": {
                "one": "[remote] I have %lld apple",
                "other": "[remote] I have %lld apples"
              }
            }
          }
        }
        """

    private func makeSwizzledContext() -> TestContext {
        let context = TestContext()
        context.cache.preload(
            Data(cachedTranslationsJSON.utf8),
            for: CacheDescriptor(
                language: "en", appVersionSignature: "1.0.0-1", cdn: cdnURL.absoluteString))
        context.anylocale.initialize(cdn: cdnURL, locale: Locale(identifier: "en_US"))
        Bundle.swizzle(translator: context.anylocale)
        return context
    }

    @Test func localizedStringReturnsRemoteTranslation() throws {
        let context = makeSwizzledContext()
        defer { Bundle.unswizzle() }
        _ = context

        #expect(
            Bundle.module.localizedString(forKey: "Hello, world!", value: nil, table: nil)
                == "[remote] Hello, world!")
    }

    @Test func localizedStringFallsThroughToBundleForUnknownKey() throws {
        let context = makeSwizzledContext()
        defer { Bundle.unswizzle() }
        _ = context

        #expect(
            Bundle.module.localizedString(forKey: "name_and_num_apples", value: nil, table: nil)
                == "[local] My name is %@ and I have %lld apples")
    }

    @Test func localizedAttributedStringReturnsRemoteTranslation() throws {
        let context = makeSwizzledContext()
        defer { Bundle.unswizzle() }
        _ = context

        let attributed = Bundle.module.__localizedAttributedString(
            forKey: "Hello, world!", value: nil, table: nil)

        #expect(attributed.string == "[remote] Hello, world!")
    }

    @Test func localizedAttributedStringRendersMarkdownEmphasis() throws {
        let context = makeSwizzledContext()
        defer { Bundle.unswizzle() }
        _ = context

        let attributed = Bundle.module.__localizedAttributedString(
            forKey: "My name is %@", value: nil, table: nil)

        #expect(attributed.string == "[remote] My name is %@")
        let boldRange = (attributed.string as NSString).range(of: "%@")
        let intent = attributed.attribute(
            .inlinePresentationIntent, at: boldRange.location, effectiveRange: nil)
        let rawIntent = try #require(intent as? UInt)
        #expect(InlinePresentationIntent(rawValue: rawIntent).contains(.stronglyEmphasized))
    }

    @Test func localizedAttributedStringFallsThroughToBundleForUnknownKey() throws {
        let context = makeSwizzledContext()
        defer { Bundle.unswizzle() }
        _ = context

        let attributed = Bundle.module.__localizedAttributedString(
            forKey: "name_and_num_apples", value: nil, table: nil)

        #expect(attributed.string == "[local] My name is %@ and I have %lld apples")
    }

    @Test func localizedAttributedStringFallsThroughToBundleForPluralKey() throws {
        let context = makeSwizzledContext()
        defer { Bundle.unswizzle() }
        _ = context

        let attributed = Bundle.module.__localizedAttributedString(
            forKey: "I have %lld apples", value: nil, table: nil)

        #expect(attributed.string == "%#@apples@")
    }

    @Test func localizedAttributedStringReturnsKeyWhenNothingKnowsIt() throws {
        let context = makeSwizzledContext()
        defer { Bundle.unswizzle() }
        _ = context

        let attributed = Bundle.module.__localizedAttributedString(
            forKey: "nonexistent.key", value: nil, table: nil)

        #expect(attributed.string == "nonexistent.key")
    }

    @Test func unswizzledBundleIsUntouched() throws {
        Bundle.unswizzle()

        #expect(
            Bundle.module.localizedString(forKey: "Hello, world!", value: nil, table: nil)
                == "[local] Hello, world!")
        #expect(
            Bundle.module.__localizedAttributedString(forKey: "Hello, world!", value: nil, table: nil)
                .string == "[local] Hello, world!")
    }
}
