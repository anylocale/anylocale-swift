import Foundation
import SwiftUI

public struct AnylocaleText: View {

    private let key: String
    private let tableName: String?
    private let arguments: [CVarArg]
    private let bundle: Bundle
    @Environment(\.locale) private var locale
    @StateObject private var updater = AnylocaleSwiftUIUpdater()

    public init(
        _ key: String, _ arguments: CVarArg..., tableName: String? = nil, bundle: Bundle = .main
    ) {
        self.key = key
        self.tableName = tableName
        self.arguments = arguments
        self.bundle = bundle
    }

    public var body: some View {
        Text(
            Anylocale.shared.translate(
                key, arguments, table: tableName, bundle: bundle, locale: locale))
    }
}
