# McWritely Project Task List

## Current Tasks

- [x] **UI-TASK-006: Remove auto-capture on open; Open McWritely shows empty panel** - ✅ **COMPLETED** - Prevents error flash; adds explicit reset; ignores stale capture results
- [ ] **RELEASE-TASK-011: Release 2.0.1 (version bump + changelog + rebuilt app/DMG)** - 📋 **NOT STARTED** (Est: 1-2h)
- [x] **CORE-TASK-008: Improve selection capture reliability in Electron/other apps** - ✅ **COMPLETED** - Frontmost app tracking + richer pasteboard extraction + clipboard capture retries
- [x] **CORE-TASK-009: Always keep corrected text in clipboard after Apply** - ✅ **COMPLETED** - Removed clipboard-restore on Apply; corrected text remains available on failure
- [x] **CORE-TASK-010: Verified replacement results + truthful UI behavior** - ✅ **COMPLETED** - “Apply” now returns verified/unverified/failed results; panel only auto-hides on verified success
- [x] **CORE-TASK-011: Add AX range/value replacement strategy before paste fallback** - ✅ **COMPLETED** - Uses `kAXSelectedTextRange` + `kAXValue` where available before falling back
- [x] **RELEASE-TASK-010: Release 2.0.0 (version bump + changelog + rebuilt app/DMG)** - ✅ **COMPLETED**

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
