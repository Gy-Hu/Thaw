# Local display-profile fix

Based on Thaw 2.0.1 (build 56), commit `d5eab80b`. Branch:
`fix/display-profile-switching`.

## Changes

- Select one global profile from connected displays: any online non-built-in
  display selects the external rule; built-in-only selects the laptop rule.
  A transient empty display list preserves the current layout. The same target
  profile is never reapplied merely because focus or resolution changed.
- No focus polling. Display-parameter notifications are debounced for 1.5 seconds;
  startup and leaving a Focus Filter also evaluate the connection rule.
- Configure the two rules in Settings > Profiles > Auto-Switch. They are stored
  as profile IDs (`ExternalDisplayProfileID` and `BuiltInDisplayProfileID`), so
  renaming a profile does not break its rule. A missing rule/profile does nothing.
- Feed current section membership to the LCS fallback. A relative order can remain
  unchanged while an item must move from hidden to visible, or the reverse.
  Misplaced items cannot be kept as stable anchors before their own move.
- Do not count a deferred, off-screen divider operation as a failed move before
  the section-aware fallback has run. Real fallback failures still block saving.
- Authenticate ad-hoc XPC peers using the validated code hash of the app/service
  bundled with this installation. Team-signed builds retain the same-team check;
  invalid or missing peer code fails closed.

The captured regression fixture contains anonymous item IDs only.

## Validation

Run the isolated function-level tests (no menu-bar changes):

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer python3 scripts/run-display-regressions.py
```

The harness extracts production functions directly from this checkout and reuses
existing/new tests. It does not run the GUI app. `--baseline` runs the original
planner, with three intentionally failing cross-section regression cases.

Compile the application and full test target without launching the test host:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild build-for-testing \
  -project Thaw.xcodeproj -scheme Thaw -configuration Debug \
  -destination 'platform=macOS' -derivedDataPath build/TestDerivedData \
  CODE_SIGNING_ALLOWED=NO
```

## Build and install

```sh
scripts/build-local-display-fix.sh > build/local-build.log 2>&1
```

Output: `build/DerivedData/Build/Products/Release/Thaw.app`, version
`2.0.1-local.2`. This local app uses ad-hoc signing because a Developer ID
certificate is not required for a personal build. It is not notarized.

Before replacement, archive the installed `.app` as a ZIP (to avoid duplicate app registration), the `com.stonerl.Thaw`
preferences and `~/Library/Application Support/Thaw`. Quit Thaw, replace the app,
and reopen it. macOS may require the user to grant Accessibility/Screen Recording
again because the signing identity differs. Do not alter the TCC database or
bypass Gatekeeper to make permissions appear granted.

Disable automatic Sparkle updates for this local installation so an upstream
release does not silently replace the fork. Preserve the original preference in
the backup. To roll back, quit the local app, restore the original app and saved
preferences/profile files, and launch the original app.

## Scope and limitations

This uses the same native menu-bar layout on every display. It does not provide
independent simultaneous native layouts. While an external display is attached,
clicking the laptop's screen does not select the laptop profile. Disconnecting
the final external display selects the laptop profile.

For a fixed external layout, turn off menu-bar item overflow in that profile so
notch-based automatic rearrangement does not override it when the built-in screen
gets focus. A smaller screen may not physically fit every item; it still shares
the same logical layout. Focus Filter profiles retain their existing priority.

A complete build and function-level tests do not establish that WindowServer
will accept every live drag. Verify both directions of a real display switch,
rapid switches, relaunch, and the exact visible/hidden assignments.

The later upstream parked-release fix in `a691df93` targets the newer transport
strategy implementation. The 2.0.1 mover already constructs its release point
before pressing; that later patch is not applicable to this baseline and is not
included here.
