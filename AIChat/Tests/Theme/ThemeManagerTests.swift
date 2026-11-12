import SwiftUI
import XCTest
@testable import AI_Chat

@MainActor
final class ThemeManagerTests: XCTestCase {
    func testDefaultsToSystemTheme() throws {
        let (defaults, suite) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }

        XCTAssertEqual(ThemeManager(defaults: defaults).theme, .system)
    }

    func testChosenThemeIsRestoredLater() throws {
        let (defaults, suite) = try makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }

        let manager = ThemeManager(defaults: defaults)
        manager.theme = .dark

        XCTAssertEqual(ThemeManager(defaults: defaults).theme, .dark)
    }

    func testColorSchemeMatchesTheme() {
        XCTAssertNil(AppTheme.system.colorScheme)
        XCTAssertEqual(AppTheme.light.colorScheme, .light)
        XCTAssertEqual(AppTheme.dark.colorScheme, .dark)
    }

    private func makeDefaults() throws -> (UserDefaults, String) {
        let suite = "ThemeManagerTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        return (defaults, suite)
    }
}
