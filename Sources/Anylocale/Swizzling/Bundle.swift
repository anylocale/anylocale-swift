import Foundation

@MainActor
private struct SwizzledMethod {
    let original: Method
    let swizzled: Method
    let originalImplementation: IMP

    init?(on cls: AnyClass, original originalSelector: Selector, swizzled swizzledSelector: Selector) {
        guard let original = class_getInstanceMethod(cls, originalSelector),
            let swizzled = class_getInstanceMethod(cls, swizzledSelector)
        else {
            return nil
        }
        self.original = original
        self.swizzled = swizzled
        self.originalImplementation = method_getImplementation(original)
        method_exchangeImplementations(original, swizzled)
    }

    func restore() {
        method_exchangeImplementations(swizzled, original)
    }
}

private func onMainActor<T: Sendable>(_ body: @MainActor () -> T) -> T {
    if Thread.isMainThread {
        return MainActor.assumeIsolated(body)
    }
    return DispatchQueue.main.sync {
        MainActor.assumeIsolated(body)
    }
}

extension Bundle {
    @MainActor private static var translator: Anylocale?
    @MainActor private static var localizedStringSwizzle: SwizzledMethod?
    @MainActor private static var localizedAttributedStringSwizzle: SwizzledMethod?

    @MainActor
    static var isSwizzled: Bool {
        localizedStringSwizzle != nil
    }

    @MainActor
    class func swizzle(translator: Anylocale) {
        guard !isSwizzled else { return }
        self.translator = translator
        localizedStringSwizzle = SwizzledMethod(
            on: self,
            original: #selector(Bundle.localizedString(forKey:value:table:)),
            swizzled: #selector(Bundle.swizzled_LocalizedString(forKey:value:table:)))
        if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *) {
            localizedAttributedStringSwizzle = SwizzledMethod(
                on: self,
                original: #selector(Bundle.__localizedAttributedString(forKey:value:table:)),
                swizzled: #selector(Bundle.swizzled_LocalizedAttributedString(forKey:value:table:)))
        }
    }

    @MainActor
    class func unswizzle() {
        localizedStringSwizzle?.restore()
        localizedStringSwizzle = nil
        localizedAttributedStringSwizzle?.restore()
        localizedAttributedStringSwizzle = nil
        translator = nil
    }

    @objc func swizzled_LocalizedAttributedString(
        forKey key: String, value: String?, table tableName: String?
    ) -> NSAttributedString {
        // NSAttributedString is not Sendable, so the main-actor hop hands it back through a capture.
        nonisolated(unsafe) var result = NSAttributedString()
        onMainActor {
            result = self.translatedAttributedString(forKey: key, value: value, table: tableName)
        }
        return result
    }

    @MainActor
    private func translatedAttributedString(
        forKey key: String, value: String?, table tableName: String?
    ) -> NSAttributedString {
        guard let translator = Bundle.translator else {
            return originalLocalizedAttributedString(forKey: key, value: value, table: tableName)
        }
        if let remote = translator.remoteTranslation(forKey: key, table: tableName) {
            return NSAttributedString(translationMarkdown: remote)
        }
        return translator.localizedBundle(for: self).originalLocalizedAttributedString(
            forKey: key, value: value, table: tableName)
    }

    @MainActor
    private func originalLocalizedAttributedString(
        forKey key: String, value: String?, table tableName: String?
    ) -> NSAttributedString {
        guard let swizzle = Bundle.localizedAttributedStringSwizzle else {
            return NSAttributedString(
                string: originalLocalizedString(forKey: key, value: value, table: tableName))
        }
        typealias OriginalFunction = @convention(c) (
            AnyObject, Selector, NSString, NSString?, NSString?
        ) -> NSAttributedString
        let originalFunction = unsafeBitCast(swizzle.originalImplementation, to: OriginalFunction.self)
        return originalFunction(
            self,
            method_getName(swizzle.original),
            key as NSString,
            value as NSString?,
            tableName as NSString?
        )
    }

    @objc func swizzled_LocalizedString(
        forKey key: String, value: String?, table tableName: String?
    ) -> String {
        onMainActor {
            guard let translator = Bundle.translator else {
                return self.originalLocalizedString(forKey: key, value: value, table: tableName)
            }
            return translator.translate(key, table: tableName, bundle: self)
        }
    }

    @MainActor
    func originalLocalizedString(
        forKey key: String, value: String? = nil, table tableName: String? = nil
    ) -> String {
        guard let swizzle = Bundle.localizedStringSwizzle else {
            return localizedString(forKey: key, value: value, table: tableName)
        }
        typealias OriginalFunction = @convention(c) (
            AnyObject, Selector, NSString, NSString?, NSString?
        ) -> NSString
        let originalFunction = unsafeBitCast(swizzle.originalImplementation, to: OriginalFunction.self)
        return originalFunction(
            self,
            #selector(Bundle.localizedString(forKey:value:table:)),
            key as NSString,
            value as NSString?,
            tableName as NSString?
        ).description
    }
}
