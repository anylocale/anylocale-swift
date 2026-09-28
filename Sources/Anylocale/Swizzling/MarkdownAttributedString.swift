import Foundation

extension NSAttributedString {
    convenience init(translationMarkdown markdown: String) {
        if #available(iOS 15, macOS 12, tvOS 15, watchOS 8, *),
            let parsed = try? AttributedString(
                markdown: markdown,
                options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        {
            self.init(parsed)
        } else {
            self.init(string: markdown)
        }
    }
}
