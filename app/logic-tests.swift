import Foundation

// Standalone regression tests for the pure logic in ClaudeUsageBar.swift.
// This single-binary app has no XCTest target, so these mirror the pure
// helpers and assert their behavior. Run: `swift app/logic-tests.swift`.
// Keep these copies in sync with the originals in ClaudeUsageBar.swift.

func menuBarTitle(sessionPercent: Int, timeRemaining: String?, weeklyPercent: Int?) -> String {
    var title = " \(sessionPercent)%"
    if let timeRemaining = timeRemaining { title += " · \(timeRemaining)" }
    if let weeklyPercent = weeklyPercent { title += " / \(weeklyPercent)%" }
    return title
}

func menuBarBadgeBasis(sessionPercent: Int, weeklyPercent: Int?) -> Int {
    guard let weeklyPercent = weeklyPercent else { return sessionPercent }
    return max(sessionPercent, weeklyPercent)
}

var failures = 0
func eq<T: Equatable>(_ label: String, _ got: T, _ want: T) {
    if got != want { failures += 1; print("FAIL  \(label): got \(got), want \(want)") }
    else { print("PASS  \(label)") }
}

// menuBarTitle composition
eq("title session only",       menuBarTitle(sessionPercent: 35, timeRemaining: nil, weeklyPercent: nil), " 35%")
eq("title session + time",     menuBarTitle(sessionPercent: 35, timeRemaining: "2h30", weeklyPercent: nil), " 35% · 2h30")
eq("title session + weekly",   menuBarTitle(sessionPercent: 35, timeRemaining: nil, weeklyPercent: 78), " 35% / 78%")
eq("title all three",          menuBarTitle(sessionPercent: 35, timeRemaining: "2h30", weeklyPercent: 78), " 35% · 2h30 / 78%")

// badge basis = worse of the two when weekly shown
eq("badge weekly off",         menuBarBadgeBasis(sessionPercent: 35, weeklyPercent: nil), 35)
eq("badge weekly worse",       menuBarBadgeBasis(sessionPercent: 35, weeklyPercent: 92), 92)
eq("badge session worse",      menuBarBadgeBasis(sessionPercent: 92, weeklyPercent: 35), 92)
eq("badge equal",              menuBarBadgeBasis(sessionPercent: 70, weeklyPercent: 70), 70)

print("\n\(failures == 0 ? "ALL PASS" : "\(failures) FAILURE(S)")")
exit(failures == 0 ? 0 : 1)
