import Foundation

// Standalone regression tests for the pure logic in ClaudeUsageBar.swift.
// This single-binary app has no XCTest target, so these mirror the pure
// helpers and assert their behavior. Run: `swift app/logic-tests.swift`.
// Keep these copies in sync with the originals in ClaudeUsageBar.swift.

func sessionLooksExpired(status: Int, accountIsNull: Bool) -> Bool {
    if status == 401 || status == 403 { return true }
    if status == 200 && accountIsNull { return true }
    return false
}

var failures = 0
func eq(_ label: String, _ got: Bool, _ want: Bool) {
    if got != want { failures += 1; print("FAIL  \(label): got \(got), want \(want)") }
    else { print("PASS  \(label)") }
}

// Strong auth-failure signals → expired
eq("401 expired",            sessionLooksExpired(status: 401, accountIsNull: false), true)
eq("403 expired",            sessionLooksExpired(status: 403, accountIsNull: false), true)
eq("200 + null account",     sessionLooksExpired(status: 200, accountIsNull: true),  true)
// Healthy / transient → not expired
eq("200 + real account",     sessionLooksExpired(status: 200, accountIsNull: false), false)
eq("500 not expired",        sessionLooksExpired(status: 500, accountIsNull: false), false)
eq("0 (network) not expired", sessionLooksExpired(status: 0,  accountIsNull: false), false)
eq("404 not expired",        sessionLooksExpired(status: 404, accountIsNull: false), false)
// null account only counts on a 200 (not on an error status)
eq("403 + null account",     sessionLooksExpired(status: 403, accountIsNull: true),  true)
eq("500 + null account",     sessionLooksExpired(status: 500, accountIsNull: true),  false)

print("\n\(failures == 0 ? "ALL PASS" : "\(failures) FAILURE(S)")")
exit(failures == 0 ? 0 : 1)
