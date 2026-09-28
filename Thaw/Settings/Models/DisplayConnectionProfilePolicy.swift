import Foundation

/// Selects one global layout from the connected display topology, never focus.
nonisolated enum DisplayConnectionProfilePolicy {
    enum ConnectionState: Equatable {
        case builtInOnly
        case externalConnected
    }

    static func connectionState(displayIsBuiltIn: [Bool]) -> ConnectionState? {
        guard !displayIsBuiltIn.isEmpty else { return nil }
        return displayIsBuiltIn.contains(false) ? .externalConnected : .builtInOnly
    }

    static func targetProfileID(
        state: ConnectionState?,
        externalProfileID: UUID?,
        builtInProfileID: UUID?,
        availableProfileIDs: Set<UUID>,
        activeProfileID: UUID? = nil
    ) -> UUID? {
        let selected: UUID?
        switch state {
        case .externalConnected: selected = externalProfileID
        case .builtInOnly: selected = builtInProfileID
        case nil: return nil
        }
        guard let selected, availableProfileIDs.contains(selected), selected != activeProfileID else { return nil }
        return selected
    }
}
