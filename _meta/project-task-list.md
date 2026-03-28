# McWritely Project Task List

## Current Tasks

### Product / Core

- [x] **CORE-TASK-008: Improve selection capture reliability in Electron/other apps** - ✅ **COMPLETED** - Frontmost app tracking + richer pasteboard extraction + clipboard capture retries
- [x] **CORE-TASK-009: Always keep corrected text in clipboard after Apply** - ✅ **COMPLETED** - Removed clipboard-restore on Apply; corrected text remains available on failure
- [x] **CORE-TASK-010: Verified replacement results + truthful UI behavior** - ✅ **COMPLETED** - “Apply” now returns verified/unverified/failed results; panel only auto-hides on verified success
- [x] **CORE-TASK-011: Add AX range/value replacement strategy before paste fallback** - ✅ **COMPLETED** - Uses `kAXSelectedTextRange` + `kAXValue` where available before falling back
- [x] **CORE-TASK-012: Capture selection reliably in Codex app + VS Code** - ✅ **COMPLETED** - Added AX value+range capture, deterministic clipboard marker copy fallback, and AX menu-copy fallback
- [x] **CORE-TASK-015: Reduce false error states after Apply (Notion + Electron) and eliminate post-Apply selection animation** - ✅ **COMPLETED** - Close panel on unverified Apply, avoid intrusive verification, normalize clipboard reassert (Manual verified 2026-02-08)
  - [x] Ensure “unverified but likely applied” does not show a red error state (panel should close; clipboard has corrected text) (Est: 15-30m)
  - [x] Remove intrusive post-Apply verification that selects text via Shift+Left (avoid visible selection animation) (Est: 15-30m)
  - [x] Special-case Notion AX writes: no longer necessary after closing the panel on unverified Apply (Est: 15-30m)
  - [x] Strengthen clipboard final-state: after Apply returns, corrected text remains on clipboard (Est: 15-30m)
  - [x] Add/Update tests + test documentation (Est: 15-30m)
  - [x] Manual verification in Notion + Codex + VS Code (Est: 10-20m)
- [x] **CORE-TASK-014: Reduce false "unverified paste" in Notion by improving verification** - ✅ **COMPLETED** - Addressed via normalization + close-on-unverified Apply (Manual verified 2026-02-08)
  - [x] Add text normalization for verification comparisons (NBSP, CRLF, whitespace runs)
  - [x] After paste fallback, attempt verification by re-capturing selection from the target app (uses existing capture pipeline)
  - [x] Add/Update tests + test documentation
  - [x] Verify manual behavior in Notion (Est: 5-10m)
- [x] **CORE-TASK-013: Fix remaining selection capture failures in Electron editors (Codex, VS Code)** - ✅ **COMPLETED** - Capture + Apply verified in Codex/VS Code (Manual verified 2026-02-08)
  - [x] Add AX “walk up the focused element’s parent chain” to find a better text element
  - [x] Add `kAXStringForRangeParameterizedAttribute`/`kAXAttributedStringForRangeParameterizedAttribute` capture path when `selectedTextRange` is available
  - [x] Improve Cmd+C injection by posting a full key chord directly to the target PID (fallback to session tap)
  - [x] Add unit tests for selection text resolution precedence (pure logic) and update test docs
  - [x] Harden clipboard fallback for Electron: delay after hotkey, try multiple injection routes (menu copy, session-tap, pid), relax pasteboard gating, and run even when focused AX element is unavailable (Est: 1-2h)
  - [x] Ensure hotkey triggers a capture attempt even when capture fails (avoid empty no-op state); show spinner + actionable error (Est: 30-60m)
  - [x] Capture selection before showing panel (avoid clearing Electron selection before Cmd+C fallback) (Est: 30-60m)
  - [x] Keep panel visible when app deactivates during capture (avoid "blink then close"): set `CorrectionPanel.hidesOnDeactivate = false` (Est: 15-30m)
  - [x] Improve AX menu-copy fallback to reliably trigger Copy (avoid pressing wrong 'c' menu item): score candidates by cmdChar+modifiers+enabled, with title as tie-breaker (Est: 30-60m)
  - [x] Improve synthetic Cmd+C for Electron: post only `c` key with `.maskCommand`, and try `.cghidEventTap` as an extra fallback tap (Est: 15-30m)
  - [x] Fix Electron Apply appending (instead of replacing selection): show panel without activating McWritely so the target app keeps selection (Est: 30-60m)
  - [x] Prevent paste-fallback append in Electron: before Cmd+V, detect whether a selection is active (marker+Cmd+C). If selection is absent, attempt a safe reselect (Shift+Left by captured length) and verify inserted text via copy selection when possible (Est: 1-2h)
  - [x] Fix paste duplication in Electron: avoid multi-route/multi-attempt Cmd+V that can paste multiple times; paste should execute at most once per Apply (Est: 30-60m)
  - [x] Manual verification in Codex app + VS Code (Electron) (Est: 15-30m)

### UI

- [x] **UI-TASK-006: Remove auto-capture on open; Open McWritely shows empty panel** - ✅ **COMPLETED** - Prevents error flash; adds explicit reset; ignores stale capture results
- [x] **UI-TASK-007: Reset-before-show + prevent stale tasks from leaving spinner on** - ✅ **COMPLETED**
- [x] **UI-TASK-016: Fix non-blue Apply and oversized empty footer area** - ✅ **COMPLETED** - Apply now uses explicit blue AppKit-layer styling and panel height budget is tightened to remove dead space below Close
  - [x] Force primary Apply rendering to explicit blue in the non-key panel (Est: 15-30m)
  - [x] Reduce panel/footer reserved height constants so short content does not leave a large empty footer area (Est: 15-30m)
- [x] **UI-TASK-015: Force a visibly active native Apply button in the non-key panel** - ✅ **COMPLETED** - Apply now forces active Aqua appearance while staying AppKit-native
  - [x] Keep the Apply button AppKit-native but force an active Aqua appearance so it does not stay flat gray (Est: 15-30m)
  - [x] Return Apply sizing to a standard native scale with a clearer primary/secondary contrast (Est: 15-30m)
  - [x] Update release notes for the active native button rendering change (Est: 5-10m)
- [x] **UI-TASK-014: Refine native footer button hierarchy after oversizing Apply** - ✅ **COMPLETED** - Apply is back to a more normal native scale with tighter footer spacing
  - [x] Reduce Apply icon/text/button height to a more normal native scale while keeping it primary (Est: 15-30m)
  - [x] Tighten footer spacing so the action stack feels less bloated (Est: 15-30m)
  - [x] Update release notes for the toned-down native footer hierarchy (Est: 5-10m)
- [x] **UI-TASK-013: Make the native Apply button larger and more prominent** - ✅ **COMPLETED** - Apply now uses a much taller AppKit-native button with larger icon/title while Close remains secondary
  - [x] Increase the AppKit-native Apply button height and font size for stronger visual priority (Est: 15-30m)
  - [x] Keep the Close button secondary so the footer hierarchy stays clear (Est: 15-30m)
  - [x] Update release notes for the stronger Apply affordance (Est: 5-10m)
- [x] **UI-TASK-012: Make panel height adapt to short loading/results states** - ✅ **COMPLETED** - Panel height now follows loading/result state, keeping short content compact while preserving scroll space for longer corrections
  - [x] Compute content/window height from the current panel state instead of a single fixed height (Est: 15-30m)
  - [x] Reduce result-area height for short corrected text while preserving scroll for long text (Est: 15-30m)
  - [x] Add/update tests and verification notes for compact loading/result layouts (Est: 15-30m)
- [x] **UI-TASK-011: Make the primary Apply button visible on non-activating panels** - ✅ **COMPLETED** - Primary action now uses an AppKit-native button bridge so it renders in the non-key floating panel
  - [x] Replace SwiftUI prominent styling with an AppKit-native button bridge that renders correctly in a non-key panel (Est: 15-30m)
  - [x] Keep footer action spacing consistent when the panel is inactive/non-key (Est: 15-30m)
  - [x] Add/update verification notes for primary button visibility in packaged builds (Est: 15-30m)
- [x] **UI-TASK-010: Keep the primary Apply action in a fixed footer** - ✅ **COMPLETED** - `Apply Suggestion` now renders in the footer above `Close`, with a shorter panel height budget for empty/error states
  - [x] Move `Apply Suggestion` out of the scrollable result area and into the bottom action stack (Est: 15-30m)
  - [x] Reduce oversized empty-state/corrected-state panel height so the layout does not leave dead space (Est: 15-30m)
  - [x] Add/update tests and manual verification notes for footer action visibility (Est: 15-30m)
- [x] **UI-TASK-009: Fix correction panel clipping after recent macOS updates** - ✅ **COMPLETED** - Shared panel sizing constants now keep the primary action visible on newer macOS layout behavior
  - [x] Replace mismatched hard-coded panel/hosting sizes with shared layout constants (Est: 15-30m)
  - [x] Keep the primary action visible when corrected text is present (Est: 15-30m)
  - [x] Add/update unit tests and test documentation for panel layout sizing (Est: 15-30m)
- [ ] **UI-TASK-008: Permissions UI should reflect granted Accessibility access** - 🟡 **IN PROGRESS** (Est: 30-60m)
  - [x] Re-check `AXIsProcessTrusted` on Settings open and when app becomes active
  - [x] Make "Request Access" open the Accessibility settings pane and refresh status
  - [ ] Manual validation: after granting permission, Settings shows checkmark without restart when possible

### RELEASE

- [x] **RELEASE-TASK-010: Release 2.0.0 (version bump + changelog + rebuilt app/DMG)** - ✅ **COMPLETED**
- [x] **RELEASE-TASK-011: Release 2.0.1 (version bump + changelog + rebuilt app/DMG)** - ✅ **COMPLETED**
- [x] **RELEASE-TASK-012: Release 2.0.2 (version bump + changelog + rebuilt app/DMG)** - ✅ **COMPLETED**
- [x] **RELEASE-TASK-013: Release 2.0.3 (version bump + changelog + rebuilt app/DMG)** - ✅ **COMPLETED**
- [x] **RELEASE-TASK-014: Release 2.0.4 (version bump + changelog + rebuilt app/DMG)** - ✅ **COMPLETED**
- [x] **RELEASE-TASK-015: Release 2.0.5 (version bump + changelog + rebuilt app/DMG)** - ✅ **COMPLETED**
- [x] **RELEASE-TASK-016: Release 2.0.6 (version bump + changelog + rebuilt app/DMG)** - ✅ **COMPLETED**
- [x] **RELEASE-TASK-017: Release 2.0.7 (version bump + changelog + rebuilt app/DMG)** - ✅ **COMPLETED**
- [x] **RELEASE-TASK-018: Release 2.0.8 (version bump + changelog + rebuilt app/DMG)** - ✅ **COMPLETED**
- [x] **RELEASE-TASK-019: Release 2.0.9 (version bump + changelog + rebuilt app/DMG)** - ✅ **COMPLETED**
- [x] **RELEASE-TASK-020: Release 2.0.10 (version bump + changelog + rebuilt app/DMG)** - ✅ **COMPLETED**
- [x] **RELEASE-TASK-021: Release 2.0.11 (version bump + changelog + rebuilt app/DMG)** - ✅ **COMPLETED**
- [x] **RELEASE-TASK-022: Release 2.0.12 (version bump + changelog + rebuilt app/DMG)** - ✅ **COMPLETED**
- [x] **RELEASE-TASK-023: Release 2.0.13 (version bump + changelog + rebuilt app/DMG)** - ✅ **COMPLETED**
  - [x] Smoke-test in Codex + VS Code: no post-Apply selection animation; clipboard ends as corrected text
  - [x] Smoke-test in Notion: successful Apply does not show red verification error
  - [x] Rebuild `McWritely.app` and `McWritely.dmg` via `./package.sh`
- [x] **RELEASE-TASK-024: Release 2.1.0 (version bump + changelog + rebuilt app/DMG + tag)** - ✅ **COMPLETED**
  - [x] Bump `Info.plist` + README badge to 2.1.0
  - [x] Update `CHANGELOG.md` with 2.1.0 notes
  - [x] Rebuild `McWritely.app` and `McWritely.dmg` via `./package.sh`
  - [x] Create and push git tag `v2.1.0`
- [x] **RELEASE-TASK-025: Release 2.1.1 (version bump + changelog + rebuilt app/DMG)** - ✅ **COMPLETED**
  - [x] Bump `Info.plist` + README badge to 2.1.1
  - [x] Update `CHANGELOG.md` with 2.1.1 notes
  - [x] Rebuild `McWritely.app` and `McWritely.dmg` via `./package.sh`
- [x] **RELEASE-TASK-026: Release 2.1.2 (footer Apply visibility fix + rebuilt app/DMG)** - ✅ **COMPLETED**
  - [x] Bump `Info.plist` + README badge to 2.1.2
  - [x] Update `CHANGELOG.md` with 2.1.2 notes
  - [x] Rebuild `McWritely.app` and `McWritely.dmg` via `./package.sh`
- [x] **RELEASE-TASK-027: Release 2.1.3 (explicit Apply button rendering fix + rebuilt app/DMG)** - ✅ **COMPLETED**
  - [x] Bump `Info.plist` + README badge to 2.1.3
  - [x] Update `CHANGELOG.md` with 2.1.3 notes
  - [x] Rebuild `McWritely.app` and `McWritely.dmg` via `./package.sh`
- [x] **RELEASE-TASK-028: Release 2.1.4 (adaptive panel height + rebuilt app/DMG)** - ✅ **COMPLETED**
  - [x] Bump `Info.plist` + README badge to 2.1.4
  - [x] Update `CHANGELOG.md` with 2.1.4 notes
  - [x] Rebuild `McWritely.app` and `McWritely.dmg` via `./package.sh`
- [x] **RELEASE-TASK-029: Release 2.1.5 (larger native Apply button + rebuilt app/DMG)** - ✅ **COMPLETED**
  - [x] Bump `Info.plist` + README badge to 2.1.5
  - [x] Update `CHANGELOG.md` with 2.1.5 notes
  - [x] Rebuild `McWritely.app` and `McWritely.dmg` via `./package.sh`
- [x] **RELEASE-TASK-030: Release 2.1.6 (refined native footer button hierarchy + rebuilt app/DMG)** - ✅ **COMPLETED**
  - [x] Bump `Info.plist` + README badge to 2.1.6
  - [x] Update `CHANGELOG.md` with 2.1.6 notes
  - [x] Rebuild `McWritely.app` and `McWritely.dmg` via `./package.sh`
- [x] **RELEASE-TASK-031: Release 2.1.7 (active native Apply appearance + rebuilt app/DMG)** - ✅ **COMPLETED**
  - [x] Bump `Info.plist` + README badge to 2.1.7
  - [x] Update `CHANGELOG.md` with 2.1.7 notes
  - [x] Rebuild `McWritely.app` and `McWritely.dmg` via `./package.sh`
- [x] **RELEASE-TASK-032: Release 2.1.8 (blue Apply + compact footer height + rebuilt app/DMG)** - ✅ **COMPLETED**
  - [x] Bump `Info.plist` + README badge to 2.1.8
  - [x] Update `CHANGELOG.md` with 2.1.8 notes
  - [x] Rebuild `McWritely.app` and `McWritely.dmg` via `./package.sh`
- [x] **RELEASE-TASK-033: Release 2.1.9 (blue Apply style lock + compact footer reserve + rebuilt app/DMG)** - ✅ **COMPLETED**
  - [x] Bump `Info.plist` + README badge to 2.1.9
  - [x] Update `CHANGELOG.md` with 2.1.9 notes
  - [x] Rebuild `McWritely.app` and `McWritely.dmg` via `./package.sh`

### CONFIG

- [x] **CONFIG-TASK-005: Restore Applications alias in DMG installer** - ✅ **COMPLETED** - Ensure `McWritely.dmg` is built from a folder containing `McWritely.app` and an `/Applications` symlink

## Completed Tasks

### CORE

- [x] **CORE-TASK-001: Initial project architecture and structure** - ✅ **COMPLETED** - Initial setup of the McWritely Swift project
- [x] **CORE-TASK-002: Implement accessibility-based selection capture and replacement** - ✅ **COMPLETED** - Core logic for interacting with other applications
- [x] **CORE-TASK-003: Implement asynchronous capture/replacement and clipboard safety** - ✅ **COMPLETED** - Improving reliability and user experience
- [x] **CORE-TASK-004: Implement unit tests and test runner script** - ✅ **COMPLETED** - Added XCTest targets and helper scripts for verification
- [x] **CORE-TASK-005: Conduct Codebase Review (Security & Best Practices)** - ✅ **COMPLETED** - Reviewing codebase for security and style compliance
- [x] **CORE-TASK-006: Remove force unwraps in AccessibilityManager** - ✅ **COMPLETED** - Replace force unwraps with safe optional binding to prevent crashes
- [x] **CORE-TASK-007: Fix Slack Apply text replacement and clipboard persistence** - ✅ **COMPLETED** - Improve reliability of text replacement and fix clipboard retention bug.
- [x] **UI-TASK-005: Fix Input Monitoring Request Access button** - ✅ **COMPLETED** - Button now opens System Preferences to Input Monitoring pane

### API

- [x] **API-TASK-001: Integrate OpenAI GPT-4o-mini for writing assistance** - ✅ **COMPLETED** - Backend service for text refinement
- [x] **API-TASK-002: Refactor OpenAIService to use Codable** - ✅ **COMPLETED** - Replace JSONSerialization with native Swift Codable structs
- [x] **API-TASK-003: Implement idiomatic OpenAIError enum** - ✅ **COMPLETED** - Replace generic NSError with strongly typed OpenAIError

### UI

- [x] **UI-TASK-001: Implement Settings UI for API keys and permissions** - ✅ **COMPLETED** - User-facing configuration interface
- [x] **UI-TASK-002: Refine UI aesthetics (window shadows, alignment)** - ✅ **COMPLETED** - Polishing the application interface
- [x] **UI-TASK-003: Generate and implement new "McWritely" app icon** - ✅ **COMPLETED** - Created a pencil with a mustache icon and updated the app bundle.
- [x] **UI-TASK-004: Add version info to Settings screen** - ✅ **COMPLETED** - Display current app version at the bottom of Settings view.

### AUTH

- [x] **AUTH-TASK-001: Implement secure API key storage using macOS Keychain** - ✅ **COMPLETED** - Secure storage for user credentials

### UTIL

- [x] **UTIL-TASK-001: Add clipboard retention toggle for user control** - ✅ **COMPLETED** - New feature for clipboard management
- [x] **UTIL-TASK-002: Remove failing GitHub workflow and clean up stray files** - ✅ **COMPLETED** - Remove `.github/workflows/build.yml` and `package-lock.json`.

### CONFIG

- [x] **CONFIG-TASK-001: Develop build and DMG packaging scripts** - ✅ **COMPLETED** - Automation for building and distribution
- [x] **CONFIG-TASK-002: Rename project from Writely to McWritely** - ✅ **COMPLETED** - Updated all project assets, documentation, and source code.
- [x] **CONFIG-TASK-003: Implement GitHub Actions for build verification** - ✅ **COMPLETED** - Add CI workflow for automated builds
- [x] **CONFIG-TASK-004: Make Keychain Service identifier generic** - ✅ **COMPLETED** - Refactor `Settings.swift` to avoid hardcoded domain

### DOC

- [x] **DOC-TASK-001: Document setup, usage, and customization in README** - ✅ **COMPLETED** - Comprehensive user and developer documentation
- [x] **DOC-TASK-002: Update test documentation and define test cases** - ✅ **COMPLETED** - Aligned test documentation with Swift/XCTest and documented current/planned tests
- [x] **DOC-TASK-003: Add CC BY-NC 4.0 license information to README** - ✅ **COMPLETED** - Added license link and terms as requested
- [x] **DOC-TASK-004: Add app icon to README.md** - ✅ **COMPLETED** - Included the new mustache pencil icon in the project documentation.
- [x] **DOC-TASK-005: Update Documentation with Security Findings** - ✅ **COMPLETED** - Add security notes to README based on review
- [x] **DOC-TASK-006: Add Shields.io badges (Swift, macOS, License) to README** - ✅ **COMPLETED** - Add "flare" to the top of README
- [x] **DOC-TASK-007: Extract CONTRIBUTING.md and initialize CHANGELOG.md** - ✅ **COMPLETED** - Standardize project documentation
- [x] **DOC-TASK-008: Create refactoring plan (reliability + clipboard + app compatibility)** - ✅ **COMPLETED** - Prioritized plan based on `project-review.md` findings

### RELEASE

- [x] **RELEASE-TASK-001: Bump version to 1.2 and commit changes** - ✅ **COMPLETED** - Bump version in Info.plist and create granular commits
- [x] **RELEASE-TASK-002: Tag v1.2 and establish release process** - ✅ **COMPLETED** - Create git tag and define release workflow
- [x] **RELEASE-TASK-003: Bump version to 1.3.1 and rebuild DMG** - ✅ **COMPLETED** - Update Info.plist and CHANGELOG.md, then package the application.
- [x] **RELEASE-TASK-004: Bump version to 1.3.2 and rebuild DMG** - ✅ **COMPLETED** - Update Info.plist and CHANGELOG.md, then package the application.
- [x] **RELEASE-TASK-006: Bump version to 1.4.0 and rebuild DMG** - ✅ **COMPLETED** - Major cleanup of permissions.
- [x] **RELEASE-TASK-007: Bump version to 1.4.1 and rebuild DMG** - ✅ **COMPLETED** - Maintenance release for focus fix.
- [x] **RELEASE-TASK-008: Bump version to 1.4.2 (Robust Replacement Fix)** - ✅ **COMPLETED**
- [x] **RELEASE-TASK-009: Bump version to 1.4.3 and rebuild DMG** - ✅ **COMPLETED**

## Task Status Legend

- 🟡 **IN PROGRESS** - Currently being worked on
- ✅ **COMPLETED** - Task finished and verified
- ❌ **BLOCKED** - Task cannot proceed due to dependency or issue
- ⏸️ **ON HOLD** - Task paused for specific reason
- 📋 **NOT STARTED** - Task identified but not yet begun

## Notes

This task list follows the 7-step development workflow. All tasks must be documented here before implementation begins.
