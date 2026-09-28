import Foundation
import Testing
@testable import Thaw

@Suite("Connected display profile policy")
struct DisplayConnectionProfilePolicyTests {
    private let laptop = UUID()
    private let external = UUID()

    private func target(_ displays: [Bool], active: UUID? = nil) -> UUID? {
        DisplayConnectionProfilePolicy.targetProfileID(
            state: DisplayConnectionProfilePolicy.connectionState(displayIsBuiltIn: displays),
            externalProfileID: external, builtInProfileID: laptop,
            availableProfileIDs: [laptop, external], activeProfileID: active
        )
    }

    @Test("The built-in display alone selects the laptop profile")
    func builtInOnly() { #expect(target([true]) == laptop) }

    @Test("An attached external display controls the shared layout")
    func externalAttached() { #expect(target([true, false]) == external) }

    @Test("Clamshell mode still selects the external profile")
    func clamshell() { #expect(target([false]) == external) }

    @Test("Removing only one of two external displays does not select laptop")
    func multipleExternalDisplays() {
        #expect(target([true, false, false]) == external)
        #expect(target([true, false], active: external) == nil)
    }

    @Test("Disconnecting the final external display selects laptop")
    func lastExternalDisconnected() { #expect(target([true], active: external) == laptop) }

    @Test("Repeated focus or resolution notifications do not reapply the layout")
    func repeatedNotifications() {
        for _ in 0 ..< 20 {
            #expect(target([true, false], active: external) == nil)
        }
    }

    @Test("A transient empty display list preserves the current layout")
    func emptySnapshot() { #expect(target([], active: external) == nil) }

    @Test("An unconfigured external rule never falls back to laptop")
    func unconfiguredExternalRule() {
        #expect(DisplayConnectionProfilePolicy.targetProfileID(
            state: .externalConnected, externalProfileID: nil, builtInProfileID: laptop,
            availableProfileIDs: [laptop]
        ) == nil)
    }

    @Test("A deleted profile is not applied")
    func missingProfile() {
        #expect(DisplayConnectionProfilePolicy.targetProfileID(
            state: .externalConnected, externalProfileID: external, builtInProfileID: laptop,
            availableProfileIDs: [laptop]
        ) == nil)
    }

    @Test("A shared choice for both rules needs no transition")
    func identicalRules() {
        #expect(DisplayConnectionProfilePolicy.targetProfileID(
            state: .builtInOnly, externalProfileID: external, builtInProfileID: external,
            availableProfileIDs: [external], activeProfileID: external
        ) == nil)
    }
}
