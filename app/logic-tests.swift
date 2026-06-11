import Foundation

// Standalone regression tests for the pure logic in ClaudeUsageBar.swift.
// This single-binary app has no XCTest target, so these mirror the pure
// helpers and assert their behavior. Run: `swift app/logic-tests.swift`.
// Keep these copies in sync with the originals in ClaudeUsageBar.swift.

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

var failures = 0
func check(_ label: String, _ got: (fire: [Int], newLast: Int), _ wantFire: [Int], _ wantLast: Int) {
    if got.fire != wantFire || got.newLast != wantLast {
        failures += 1
        print("FAIL  \(label): got (fire: \(got.fire), newLast: \(got.newLast)), want (fire: \(wantFire), newLast: \(wantLast))")
    } else {
        print("PASS  \(label)")
    }
}
func eqInt(_ label: String, _ got: Int, _ want: Int) {
    if got != want { failures += 1; print("FAIL  \(label): got \(got), want \(want)") }
    else { print("PASS  \(label)") }
}

// thresholdsToFire: crossing up from zero fires every newly-passed threshold
check("75% from 0",      thresholdsToFire(percent: 75, lastNotified: 0),  [25, 50, 75], 75)
check("95% from 0",      thresholdsToFire(percent: 95, lastNotified: 0),  [25, 50, 75, 90], 90)
// Incremental crossing fires only the new one
check("75% from 50",     thresholdsToFire(percent: 75, lastNotified: 50), [75], 75)
// No re-fire at the same level
check("75% from 75",     thresholdsToFire(percent: 75, lastNotified: 75), [], 75)
// Dropping below re-arms to the highest still-passed threshold
check("30% from 75",     thresholdsToFire(percent: 30, lastNotified: 75), [], 25)
check("10% from 25",     thresholdsToFire(percent: 10, lastNotified: 25), [], 0)
// Zero stays quiet
check("0% from 0",       thresholdsToFire(percent: 0,  lastNotified: 0),  [], 0)

// thresholdBucket: the first-observation baseline (seed without firing)
eqInt("bucket 0",   thresholdBucket(percent: 0),  0)
eqInt("bucket 24",  thresholdBucket(percent: 24), 0)
eqInt("bucket 25",  thresholdBucket(percent: 25), 25)
eqInt("bucket 78",  thresholdBucket(percent: 78), 75)
eqInt("bucket 90",  thresholdBucket(percent: 90), 90)
eqInt("bucket 100", thresholdBucket(percent: 100), 90)

print("\n\(failures == 0 ? "ALL PASS" : "\(failures) FAILURE(S)")")
exit(failures == 0 ? 0 : 1)
