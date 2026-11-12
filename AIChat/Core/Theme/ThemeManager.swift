import Foundation
import Observation

/// Хранит выбранную тему и сохраняет её между запусками приложения.
@MainActor
@Observable
final class ThemeManager {
    private static let storageKey = "appTheme"

    private let defaults: UserDefaults

    var theme: AppTheme {
        didSet {
            defaults.set(theme.rawValue, forKey: Self.storageKey)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.string(forKey: Self.storageKey)
        theme = stored.flatMap(AppTheme.init(rawValue:)) ?? .system
    }
}
