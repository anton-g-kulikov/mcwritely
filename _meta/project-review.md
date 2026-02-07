# McWritely Project Review (Architecture, Stability, Security)

Date: 2026-02-07
Scope: Source review of the current Swift codebase with emphasis on architecture, stability/reliability, and security. Includes investigation into why “Apply” sometimes fails to paste/replace text in apps like Notion and Slack.

## Executive Summary

McWritely is small and understandable, but several responsibilities are currently tightly coupled (UI, capture/replace, clipboard management, and OpenAI calls). The biggest reliability risk is that “Apply” can report success without verifying that the target app actually received the replacement, and the fallback paste logic is timing-based in a way that’s brittle for Electron-style apps (Slack/Notion).

The security posture is reasonable for a local utility (API key in Keychain, HTTPS to OpenAI), but there are some hardening gaps: sensitive error bodies may be surfaced directly to the user, Keychain items could be configured with more explicit access controls, and the project’s current distribution flow is unsigned/not notarized by default.

Uncertainty (Notion/Slack root cause): ~0.25. The failure modes below are strongly suggested by the code but were not reproduced interactively in this environment.

## Architecture Review

### Current Structure

Core components:
- UI shell: menu bar + panel: `/Users/antonkulikov/Projects/mcwritely/Sources/McWritely/McWritelyApp.swift`, `/Users/antonkulikov/Projects/mcwritely/Sources/McWritely/PanelManager.swift`, `/Users/antonkulikov/Projects/mcwritely/Sources/McWritely/CorrectionPanel.swift`, `/Users/antonkulikov/Projects/mcwritely/Sources/McWritely/CorrectionView.swift`
- Orchestration: `/Users/antonkulikov/Projects/mcwritely/Sources/McWritely/CorrectionViewModel.swift`
- OS integration: hotkey + accessibility + pasteboard: `/Users/antonkulikov/Projects/mcwritely/Sources/McWritely/HotkeyManager.swift`, `/Users/antonkulikov/Projects/mcwritely/Sources/McWritely/AccessibilityManager.swift`
- Networking: `/Users/antonkulikov/Projects/mcwritely/Sources/McWritely/OpenAIService.swift`
- Secrets/settings: `/Users/antonkulikov/Projects/mcwritely/Sources/McWritely/Settings.swift`, `/Users/antonkulikov/Projects/mcwritely/Sources/McWritely/KeychainStore.swift`

### Architectural Strengths
- Minimal surface area and few dependencies (`Package.swift` is dependency-free).
- Key storage is isolated into `KeychainStore`.
- The selection pipeline is asynchronous, reducing UI lock-ups (`async` usage in view model and accessibility manager).

### Architectural Risks / Opportunities

1. Single “God path” for capture/replace behavior
The app’s most complex logic (frontmost app targeting, AX read/write, clipboard snapshot/restore, synthetic input) sits in `AccessibilityManager` with limited observability and no abstraction boundaries. This makes it hard to:
- test it deterministically
- add per-app workarounds (Slack/Notion/etc.)
- add diagnostics without spamming logs

2. Missing domain model for “selection”
`CaptureTarget` includes `AXUIElement` and `selectedText` but not the selection range, editability, element role, or which mechanism succeeded (AX vs clipboard). That reduces the ability to implement robust re-selection and verification later. `/Users/antonkulikov/Projects/mcwritely/Sources/McWritely/AccessibilityManager.swift`

Suggested refactor boundaries (incremental, low risk):
- `SelectionCaptureService`: returns `SelectionContext` with `pid`, `bundleId`, `axElement`, `selectedText`, `selectedTextRange` (if available), and `captureMethod`.
- `ReplacementService`: attempts replacement with strategy chain and returns `ReplacementResult` with `method`, `verified`, `errors`.
- `AppFocusService`: centralizes “bring-to-front” and re-check semantics.
- `ClipboardTransaction`: snapshot/restore + lifetime guarantees.

## Stability / Reliability Review

### High Severity Findings (can cause user-visible failure)

1. “Apply” can return success even if paste did nothing
In `AccessibilityManager.replaceText(...)`, the paste fallback returns `true` unconditionally, and the UI closes on `true`. If Slack/Notion ignore the synthetic paste event, the user sees a “successful apply” but nothing changes. `/Users/antonkulikov/Projects/mcwritely/Sources/McWritely/AccessibilityManager.swift`

2. Timing-based clipboard restore can race with slow paste handlers
When `keepNewTextInClipboard` is disabled, the pasteboard is restored after a fixed delay (`500ms`). Electron apps can process paste asynchronously; restoring too early can lead to:
- old clipboard content being pasted
- nothing being pasted
- intermittent behavior depending on system load
This matches the observed “improved text isn’t pasted back” reports in Slack/Notion. `/Users/antonkulikov/Projects/mcwritely/Sources/McWritely/AccessibilityManager.swift`

3. Panel focus steal risks selection loss in target apps
The correction UI uses a borderless `NSPanel` that can become key/main (`canBecomeKey = true`). Showing the panel makes McWritely the active app (`NSApp.activate(ignoringOtherApps: true)`), which can cause selection to be cleared in some editors. The replacement logic assumes the selection is still present when the user clicks “Apply”. `/Users/antonkulikov/Projects/mcwritely/Sources/McWritely/PanelManager.swift`, `/Users/antonkulikov/Projects/mcwritely/Sources/McWritely/CorrectionPanel.swift`

### Medium Severity Findings (degrades reliability, hard to debug)

4. Target app selection heuristics can pick the wrong app
`captureSelectedText()` scans `runningApplications` looking for an active app that isn’t McWritely, then falls back to the first visible regular app. This is not guaranteed to be the app the user intends, especially after menu bar interactions or multi-window workflows. `/Users/antonkulikov/Projects/mcwritely/Sources/McWritely/AccessibilityManager.swift`

5. AX write may be conceptually wrong for many controls
Writing to `kAXSelectedTextAttribute` is often not supported as a setter; many controls require setting `kAXValueAttribute` plus `kAXSelectedTextRangeAttribute`, or using app-specific semantics. Right now, the code only tries `kAXSelectedTextAttribute` then jumps to paste. Slack/Notion often don’t expose standard macOS text attributes the way native controls do. `/Users/antonkulikov/Projects/mcwritely/Sources/McWritely/AccessibilityManager.swift`

### Suggested Reliability Fixes (prioritized)

1. Add verification to replacement
- After AX write: read back selection/value and verify it changed to `correctedText` (or at least that selected text equals it).
- After paste fallback: wait for a change in the AX value/selected text (with a bounded timeout) before returning success.

2. Improve the paste fallback to be more deterministic
- Prefer “pasteboard transaction” scoped to replacement, and don’t restore until verification passes or a timeout expires.
- Consider using `CGEvent.postToPid` to target the app PID (reduces focus dependency) when possible.
- Consider an “optionally keep corrected text in clipboard for N seconds” mode for problematic apps.

3. Preserve selection range (when possible)
Capture and store `kAXSelectedTextRangeAttribute` (and/or insertion point) so replacement can reselect the original range right before applying.

4. Reduce UI focus stealing
Consider a non-activating UI approach for the suggestion panel (or a mode that doesn’t activate on show), so the target app retains focus/selection until “Apply” is invoked.

## Security Review

### Strengths
- API key stored in Keychain, not plaintext. `/Users/antonkulikov/Projects/mcwritely/Sources/McWritely/KeychainStore.swift`, `/Users/antonkulikov/Projects/mcwritely/Sources/McWritely/Settings.swift`
- API calls use HTTPS to OpenAI. `/Users/antonkulikov/Projects/mcwritely/Sources/McWritely/OpenAIService.swift`
- No external analytics or third-party SDKs.

### Risks / Hardening Opportunities

1. Error body surfacing
On non-2xx responses, `OpenAIService` throws an error whose message is the raw response body as a string. This can:
- reveal internal details to users
- create confusing UX
- risk logging/leaking if later persisted
Suggested: parse OpenAI error schema if present; otherwise show a generic error and optionally provide a “Copy diagnostics” button. `/Users/antonkulikov/Projects/mcwritely/Sources/McWritely/OpenAIService.swift`

2. Keychain item access controls are implicit
Keychain writes do not specify `kSecAttrAccessible` or additional constraints. Consider explicitly setting:
- `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` (typical for API keys)
- optionally an access group if you ever add helper tools
This is defense-in-depth, not a blocker. `/Users/antonkulikov/Projects/mcwritely/Sources/McWritely/KeychainStore.swift`

3. Over-broad OS permissions (inevitable but important)
Accessibility permission is powerful. The app should continue to:
- avoid collecting data unless user initiates (currently true by design)
- minimize logging and avoid logging selected text
Current logs include app name/bundle id, which is fine; ensure future changes don’t log user text. `/Users/antonkulikov/Projects/mcwritely/Sources/McWritely/AccessibilityManager.swift`

4. Distribution hardening
The packaging script describes signing/notarization as “next steps” but doesn’t enforce it. For real distribution, require:
- codesigning with hardened runtime
- notarization
Without that, users are instructed to bypass Gatekeeper/quarantine, which increases security risk. `/Users/antonkulikov/Projects/mcwritely/package.sh`, `/Users/antonkulikov/Projects/mcwritely/README.md`

## Notion/Slack “Apply Doesn’t Paste Back” Root Cause Analysis

Most likely causes given current implementation:

1. Clipboard restore race
- For problematic apps, the paste handler may read from pasteboard after McWritely has restored the original clipboard (because restore happens after a fixed delay). Result: old clipboard pasted or nothing happens.

2. Selection/focus loss due to panel activation
- Showing the panel activates McWritely and makes the panel key, which can clear selection in editors. By the time “Apply” is clicked, there may be no active selection to replace, so `Cmd+V` inserts in an unexpected location or is ignored.

3. Synthetic `Cmd+V` not accepted
- Some apps ignore `CGEvent`-posted key events depending on security settings, focus state, or event tap choice. If the first paste is ignored, the retry may still be ignored, but the code returns success anyway.

4. AX setter mismatch
- Slack/Notion frequently won’t allow setting `kAXSelectedTextAttribute`. If AX fails and paste also fails, there is no third fallback path (like set value + selection range, or app-specific strategies).

Recommended concrete next steps to fix (engineering order):
- Implement “verified replacement” (don’t close UI until verified).
- Extend `CaptureTarget` to store selection range + capture method.
- Implement replacement strategy chain:
  - Strategy A: set `kAXValueAttribute` + `kAXSelectedTextRangeAttribute` (when available)
  - Strategy B: set `kAXSelectedTextAttribute` (current)
  - Strategy C: paste fallback with longer transactional pasteboard lifetime and verification
  - Strategy D: per-bundle-id tweaks (Slack/Notion) if required

## Testing / Observability Gaps

Current tests cover Keychain and JSON decoding, but not the OS integration paths. `/Users/antonkulikov/Projects/mcwritely/Tests/McWritelyTests/McWritelyTests.swift`, `/Users/antonkulikov/Projects/mcwritely/test/test-documentation.md`

Recommended additions:
- A small “fixture” test app (native NSTextView) used for manual/integration testing of capture/replace.
- Logging improvements behind a debug flag to capture:
  - which strategy was used (AX vs clipboard vs paste)
  - whether replacement was verified
  - how long pasteboard transaction was held

## Top Recommendations (Impact/Effort)

1. Add replacement verification and only return success when verified (High impact, Medium effort).
2. Make pasteboard restore conditional on verification/timeout, not a fixed delay (High impact, Low-Medium effort).
3. Capture selection range when possible and reapply it before replacement (High impact, Medium effort).
4. Add strategy for `kAXValueAttribute` + `kAXSelectedTextRangeAttribute` replacement (Medium-High impact, Medium effort).
5. Make the suggestion panel less disruptive to focus (Medium impact, Medium effort).

