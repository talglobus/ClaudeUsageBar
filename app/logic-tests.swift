import Foundation

// Standalone regression tests for the pure logic in ClaudeUsageBar.swift.
// This single-binary app has no XCTest target, so these mirror the pure
// helpers and assert their behavior. Run: `swift app/logic-tests.swift`.
// Keep these copies in sync with the originals in ClaudeUsageBar.swift.

// MARK: - Helpers mirrored from ClaudeUsageBar.swift

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

func thresholdBucket(percent: Int, thresholds: [Int] = [25, 50, 75, 90]) -> Int {
    thresholds.filter { $0 <= percent }.last ?? 0
}

func thresholdsToFire(percent: Int, lastNotified: Int, thresholds: [Int] = [25, 50, 75, 90]) -> (fire: [Int], newLast: Int) {
    var last = lastNotified
    var fire: [Int] = []
    for t in thresholds where percent >= t && last < t {
        fire.append(t)
        last = t
    }
    if percent < last {
        last = thresholdBucket(percent: percent, thresholds: thresholds)
    }
    return (fire, last)
}

func sessionLooksExpired(status: Int, accountIsNull: Bool) -> Bool {
    if status == 401 || status == 403 { return true }
    if status == 200 && accountIsNull { return true }
    return false
}

func clampedPercent(_ value: Double) -> Int {
    guard value.isFinite else { return 0 }
    return Int(min(max(value, 0), 100))
}

// MARK: - Assertions

var failures = 0
func eqStr(_ label: String, _ got: String, _ want: String) {
    if got != want { failures += 1; print("FAIL  \(label): got \(got), want \(want)") } else { print("PASS  \(label)") }
}
func eqInt(_ label: String, _ got: Int, _ want: Int) {
    if got != want { failures += 1; print("FAIL  \(label): got \(got), want \(want)") } else { print("PASS  \(label)") }
}
func eqBool(_ label: String, _ got: Bool, _ want: Bool) {
    if got != want { failures += 1; print("FAIL  \(label): got \(got), want \(want)") } else { print("PASS  \(label)") }
}
func check(_ label: String, _ got: (fire: [Int], newLast: Int), _ wantFire: [Int], _ wantLast: Int) {
    if got.fire != wantFire || got.newLast != wantLast {
        failures += 1
        print("FAIL  \(label): got (fire: \(got.fire), newLast: \(got.newLast)), want (fire: \(wantFire), newLast: \(wantLast))")
    } else { print("PASS  \(label)") }
}

// MARK: - PR1: menu-bar title + badge basis

eqStr("title session only",     menuBarTitle(sessionPercent: 35, timeRemaining: nil, weeklyPercent: nil), " 35%")
eqStr("title session + time",   menuBarTitle(sessionPercent: 35, timeRemaining: "2h30", weeklyPercent: nil), " 35% · 2h30")
eqStr("title session + weekly", menuBarTitle(sessionPercent: 35, timeRemaining: nil, weeklyPercent: 78), " 35% / 78%")
eqStr("title all three",        menuBarTitle(sessionPercent: 35, timeRemaining: "2h30", weeklyPercent: 78), " 35% · 2h30 / 78%")
eqInt("badge weekly off",       menuBarBadgeBasis(sessionPercent: 35, weeklyPercent: nil), 35)
eqInt("badge weekly worse",     menuBarBadgeBasis(sessionPercent: 35, weeklyPercent: 92), 92)
eqInt("badge session worse",    menuBarBadgeBasis(sessionPercent: 92, weeklyPercent: 35), 92)

// MARK: - PR2: notification thresholds + first-observation bucket

check("75% from 0",   thresholdsToFire(percent: 75, lastNotified: 0),  [25, 50, 75], 75)
check("95% from 0",   thresholdsToFire(percent: 95, lastNotified: 0),  [25, 50, 75, 90], 90)
check("75% from 50",  thresholdsToFire(percent: 75, lastNotified: 50), [75], 75)
check("75% from 75",  thresholdsToFire(percent: 75, lastNotified: 75), [], 75)
check("30% from 75",  thresholdsToFire(percent: 30, lastNotified: 75), [], 25)
check("10% from 25",  thresholdsToFire(percent: 10, lastNotified: 25), [], 0)
check("0% from 0",    thresholdsToFire(percent: 0,  lastNotified: 0),  [], 0)
eqInt("bucket 24",  thresholdBucket(percent: 24), 0)
eqInt("bucket 25",  thresholdBucket(percent: 25), 25)
eqInt("bucket 78",  thresholdBucket(percent: 78), 75)
eqInt("bucket 100", thresholdBucket(percent: 100), 90)

// MARK: - PR3: expired-session detection

eqBool("401 expired",        sessionLooksExpired(status: 401, accountIsNull: false), true)
eqBool("403 expired",        sessionLooksExpired(status: 403, accountIsNull: false), true)
eqBool("200 + null account", sessionLooksExpired(status: 200, accountIsNull: true),  true)
eqBool("200 + real account", sessionLooksExpired(status: 200, accountIsNull: false), false)
eqBool("500 not expired",    sessionLooksExpired(status: 500, accountIsNull: false), false)
eqBool("0 not expired",      sessionLooksExpired(status: 0,   accountIsNull: false), false)
eqBool("500 + null account", sessionLooksExpired(status: 500, accountIsNull: true),  false)

// MARK: - NaN-safe utilization clamping

eqInt("clamp normal",    clampedPercent(42.7), 42)
eqInt("clamp NaN",       clampedPercent(Double.nan), 0)
eqInt("clamp +inf → 0",  clampedPercent(Double.infinity), 0)
eqInt("clamp negative",  clampedPercent(-5), 0)
eqInt("clamp over 100",  clampedPercent(150), 100)

print("\n\(failures == 0 ? "ALL PASS" : "\(failures) FAILURE(S)")")
exit(failures == 0 ? 0 : 1)
