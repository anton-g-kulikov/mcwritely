# Refactoring Plan (Reliability, Clipboard, App Compatibility)

Date: 2026-02-07
Based on: `_meta/project-review.md`

## Goal

Make capture + apply reliably work across common apps (Slack, Notion, browsers, editors) with clear, truthful success/failure reporting. If replacement fails, the corrected text should still be immediately usable by the user.

## Key Product Decision: Clipboard Behavior

Replacement should always leave the corrected text on the clipboard (default behavior).

Rationale:
- It directly addresses the common “paste didn’t happen” failure mode: the user can immediately paste manually.
- It removes timing races caused by “restore original clipboard after N ms”.
- It reduces complexity in the replacement path.

Notes:
- We can still preserve the clipboard during *capture* (Cmd+C fallback) so merely triggering McWritely does not clobber the user’s clipboard.
- Leaving corrected text on the clipboard has privacy implications; treat as an explicit product choice and document it.

## Phase 0: Make Outcomes Observable (Low Risk, High Leverage)

Deliverables:
- Introduce a `ReplacementResult` (success, method, verified, error) instead of `Bool`.
- Introduce a `CaptureResult` (success, method, error, pasteboardTypesSeen) instead of returning `nil`.
- Add structured debug logging behind a flag (no selected text logging).

Acceptance:
- UI only hides on verified success.
- When failure happens, UI explains which step failed (AX read, clipboard read, paste event, verification timeout).

## Phase 1: Clipboard Policy Update (Simplify Replacement)

Changes:
- On Apply (paste fallback or AX success), set clipboard to corrected text and do not restore the previous clipboard contents.
- Keep (or add) a user-facing option only if you want it; default should be “keep corrected text”.

Acceptance:
- After Apply, clipboard contains the corrected text 100% of the time (regardless of replacement method).

## Phase 2: Verified Replacement (Stop Lying About Success)

Changes:
- After AX write attempt: read back `kAXSelectedTextAttribute` or `kAXValueAttribute` (depending on element) and verify it matches expected.
- After paste fallback: wait for a detectable change in the target element’s value/selected text (bounded timeout; retry loop).
- If verification fails: keep panel open, show error, keep corrected text on clipboard.

Acceptance:
- If the UI says “Applied”, the target app actually contains the corrected text.
- If it fails, the UI remains visible with actionable error and the corrected text is already in clipboard.

## Phase 3: Replacement Strategy Chain (Broader AX Support)

Implement a strategy chain that is explicit and reports which one succeeded:
1. Set `kAXSelectedTextRangeAttribute` + `kAXValueAttribute` (preferred for many native text controls).
2. Set `kAXSelectedTextAttribute` (current approach; works in some cases).
3. Paste fallback (synthetic Cmd+V) with verification and bounded retries.

Acceptance:
- Fewer fallbacks to paste for native editors.
- Electron apps still succeed via paste fallback and verification.

## Phase 4: Capture Improvements (Fix “No Text Selected” in Some Apps)

Hypotheses for the screenshot symptom (“No text selected” even when text is highlighted):
- The app doesn’t expose `kAXSelectedTextAttribute`, and the clipboard fallback copies rich formats without a `public.utf8-plain-text` flavor.
- The current capture only reads `NSPasteboard.PasteboardType.string`; it may miss other text representations.
- The copy->clipboard delay (`200ms`) may be too short under load, causing `changeCount` checks to fail intermittently.

Changes:
- On clipboard fallback capture, read text using coercion:
  - `pasteboard.readObjects(forClasses: [NSString.self], options: nil)` (lets AppKit coerce to plain text).
  - If needed, attempt RTF/HTML -> string conversion when plain string is absent.
- Add a short retry loop for clipboard capture (for example 3-5 attempts over 500-800ms total).
- Record pasteboard types present (for diagnostics only).

Acceptance:
- Selection capture works in the user-reported failing app (screenshot scenario) and in at least: Slack, Notion, Safari/Chrome, Notes/TextEdit.

## Phase 5: Focus and UI Behavior (Reduce Selection Loss)

Changes:
- Reduce focus stealing: avoid activating McWritely in a way that clears selection before Apply.
- Alternatively: store selection range (when available) and reassert selection right before replacement.
- Make `ensureAppIsFrontmost` more deterministic (and measure its effectiveness).

Acceptance:
- Selecting text, triggering hotkey, and applying suggestion does not require the user to reselect text.

## Testing Plan (Pragmatic)

Add:
- A tiny native “TestHost” app (NSTextView) used for manual/integration tests of capture + replace.
- A manual test matrix checklist (Slack, Notion, browser, native editor).
- Unit tests for:
  - pasteboard extraction/coercion helpers
  - parsing/format conversion helpers (RTF/HTML -> plain text)

## Deliverables Checklist

- `_meta/refactoring-plan.md` (this doc)
- Update code to match new clipboard policy (corrected text always in clipboard)
- Replacement verification + accurate UI status
- Improved capture for rich pasteboard formats + retries

