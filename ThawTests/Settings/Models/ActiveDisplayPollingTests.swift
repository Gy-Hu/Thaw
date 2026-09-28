import Foundation
import Testing
@testable import Thaw

@Suite("Active display polling")
@MainActor
struct ActiveDisplayPollingTests {
    @Test("An active display change is observed without a screen-parameter notification")
    func focusChangeWithoutTopologyChange() async throws {
        var display = "built-in"
        var lastDisplay = "built-in"
        var transitions = [String]()
        var checks = 0
        let task = ProfileManager.observeActiveDisplay(interval: .milliseconds(5)) {
            checks += 1
            if display != lastDisplay {
                lastDisplay = display
                transitions.append(display)
            }
        }
        defer { task.cancel() }
        // No NotificationCenter post: this is the missing event path.
        display = "external"
        for _ in 0 ..< 100 where transitions.isEmpty {
            try await Task.sleep(for: .milliseconds(5))
        }
        #expect(transitions == ["external"])
        display = "built-in"
        for _ in 0 ..< 100 where transitions.count < 2 {
            try await Task.sleep(for: .milliseconds(5))
        }
        #expect(transitions == ["external", "built-in"])
        task.cancel()
        await task.value
        let checksAtCancellation = checks
        try await Task.sleep(for: .milliseconds(20))
        #expect(checks == checksAtCancellation)
    }
}
