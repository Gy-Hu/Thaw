//
//  CodeSigningInfo.swift
//  Project: Thaw
//
//  Copyright (Ice) © 2023–2025 Jordan Baird
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

import Foundation
import Security
import XPC

nonisolated enum CodeSigningInfo {
    enum PeerValidationError: Error {
        case invalidSignatureOrIdentifier
    }

    /// Local builds cannot use a same-team requirement. Pin the peer to the
    /// signed executable shipped in this installation instead of trusting
    /// every local process. Refuse to connect if the peer cannot be verified.
    static func pinnedPeerHash(at url: URL, identifier: String) throws -> Data {
        var code: SecStaticCode?
        guard SecStaticCodeCreateWithPath(url as CFURL, [], &code) == errSecSuccess,
              let code,
              SecStaticCodeCheckValidity(code, SecCSFlags(rawValue: kSecCSStrictValidate), nil) == errSecSuccess
        else { throw PeerValidationError.invalidSignatureOrIdentifier }
        var info: CFDictionary?
        guard SecCodeCopySigningInformation(code, SecCSFlags(rawValue: kSecCSSigningInformation), &info) == errSecSuccess,
              let dict = info as? [String: Any],
              dict[kSecCodeInfoIdentifier as String] as? String == identifier,
              let hash = dict[kSecCodeInfoUnique as String] as? Data,
              !hash.isEmpty
        else { throw PeerValidationError.invalidSignatureOrIdentifier }
        return hash
    }

    static func pinnedPeerRequirement(at url: URL, identifier: String) throws -> XPCPeerRequirement {
        let hash = try pinnedPeerHash(at: url, identifier: identifier)
        let dictionary = XPCDictionary()
        dictionary.withUnsafeUnderlyingDictionary { raw in
            hash.withUnsafeBytes { bytes in
                xpc_dictionary_set_data(raw, "cdhash", bytes.baseAddress, bytes.count)
            }
        }
        return XPCPeerRequirement(lightweightCodeRequirements: dictionary)
    }

    /// The team identifier of the current process, or `nil` when signed
    /// without one (ad-hoc). Teamless installations pin their bundled peers'
    /// code hashes; team-signed installations use the same-team requirement.
    static let processTeamIdentifier: String? = {
        var code: SecCode?
        guard SecCodeCopySelf([], &code) == errSecSuccess, let code else { return nil }
        var staticCode: SecStaticCode?
        guard SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess, let staticCode else { return nil }
        var info: CFDictionary?
        let flags = SecCSFlags(rawValue: kSecCSSigningInformation)
        guard SecCodeCopySigningInformation(staticCode, flags, &info) == errSecSuccess,
              let dict = info as? [String: Any]
        else {
            return nil
        }
        return dict[kSecCodeInfoTeamIdentifier as String] as? String
    }()
}
