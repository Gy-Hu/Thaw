#!/bin/bash
# One-time setup. Adds a non-extractable local key and a certificate trusted
# only for code signing in the current user's keychain/trust domain.
set -euo pipefail
umask 077
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
identity_name="Thaw Local Code Signing"
keychain_path="$HOME/Library/Keychains/login.keychain-db"

if security find-certificate -c "$identity_name" "$keychain_path" >/dev/null 2>&1; then
  if security find-identity -v -p codesigning "$keychain_path" | grep -F -- "\"$identity_name\"" >/dev/null; then
    printf 'Existing signing identity is ready: %s\n' "$identity_name"
    exit 0
  fi
  printf 'A certificate with this name already exists but is not a valid signing identity. Inspect it in Keychain Access before retrying.\n' >&2
  exit 1
fi

mkdir -p "$repo_root/build"
cert_work_dir="$(mktemp -d "$repo_root/build/local-signing.XXXXXX")"
trap 'rm -rf -- "$cert_work_dir"' EXIT
openssl req -new -newkey rsa:3072 -x509 -sha256 -days 1825 -noenc \
  -subj "/CN=$identity_name/" \
  -addext 'basicConstraints=critical,CA:FALSE' \
  -addext 'keyUsage=critical,digitalSignature' \
  -addext 'extendedKeyUsage=critical,codeSigning' \
  -keyout "$cert_work_dir/private.pem" -out "$cert_work_dir/certificate.pem" \
  2>"$cert_work_dir/key-generation.log"
# Validate the staged certificate before touching the user's keychain.
security verify-cert -c "$cert_work_dir/certificate.pem" \
  -r "$cert_work_dir/certificate.pem" -p codeSign
openssl rand -base64 24 > "$cert_work_dir/import-passphrase"
openssl pkcs12 -export -legacy -macalg sha1 -name "$identity_name" \
  -inkey "$cert_work_dir/private.pem" -in "$cert_work_dir/certificate.pem" \
  -out "$cert_work_dir/identity.p12" -passout "file:$cert_work_dir/import-passphrase"
# The temporary PKCS#12 and key live in a 0700 directory under umask 077.
# No all-applications ACL, keychain password, or partition-list override is used.
security import "$cert_work_dir/identity.p12" -k "$keychain_path" -f pkcs12 \
  -P "$(cat "$cert_work_dir/import-passphrase")" -x -T /usr/bin/codesign
# User-domain trust, constrained to code signing (not TLS or other policies).
# macOS may present its own authentication dialog here.
security add-trusted-cert -r trustRoot -p codeSign -k "$keychain_path" \
  "$cert_work_dir/certificate.pem"
security find-identity -v -p codesigning "$keychain_path" \
  | grep -F -- "\"$identity_name\""
printf 'Ready: %s. Keep this keychain identity for future Thaw builds.\n' "$identity_name"
