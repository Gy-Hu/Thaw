import Foundation
import Testing
@testable import Thaw

@Suite("Local build peer signing")
struct LocalPeerSigningTests {
    @Test("A valid signed executable has a code hash")
    func validSignedPeer() throws {
        let hash = try CodeSigningInfo.pinnedPeerHash(
            at: URL(fileURLWithPath: "/usr/bin/true"), identifier: "com.apple.true"
        )
        #expect(!hash.isEmpty)
        _ = try CodeSigningInfo.pinnedPeerRequirement(
            at: URL(fileURLWithPath: "/usr/bin/true"), identifier: "com.apple.true"
        )
    }

    @Test("A signed executable with the wrong identity is refused")
    func wrongIdentifier() {
        #expect(throws: (any Error).self) {
            try CodeSigningInfo.pinnedPeerHash(
                at: URL(fileURLWithPath: "/usr/bin/true"), identifier: "com.stonerl.Thaw"
            )
        }
    }

    @Test("Missing peer code fails closed")
    func missingPeer() {
        #expect(throws: (any Error).self) {
            try CodeSigningInfo.pinnedPeerHash(
                at: URL(fileURLWithPath: "/nonexistent-thaw-peer-\(UUID())"), identifier: "com.stonerl.Thaw"
            )
        }
    }
}
