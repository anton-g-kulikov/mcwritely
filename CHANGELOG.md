# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.4] - 2026-02-05
### Changed
- Built updated DMG.

## [2.0.0] - 2026-02-07
### Added
- Improved selection capture for Electron/other apps via frontmost app tracking and richer pasteboard extraction.
- Added verified/unverified Apply results; the panel only auto-hides on verified success.
- Added an AX range/value replacement strategy before falling back to paste.

### Changed
- Corrected text is always kept on the clipboard after Apply.

## [2.0.1] - 2026-02-07
### Fixed
- Opening McWritely from the menu bar no longer triggers an automatic capture attempt (prevents brief "No text selected" flash).
- Reduced stale async state updates while capturing selection.

## [1.4.3] - 2026-02-05
### Changed
- Rebuilt installation package with latest robust text replacement logic.

## [1.4.2] - 2026-02-05
### Fixed
- Text replacement reliability. Improved focus management and re-ordered "Apply" logic to ensure replacement completes before McWritely hides.

## [1.4.1] - 2026-02-05
### Fixed
- Application focus not returning to the original app after applying a suggestion.

## [1.4.0] - 2026-02-05
### Removed
- "Input Monitoring" permission requirement. The app now uses Carbon HotKeys which do not require this permission.

## [1.3.3] - 2026-02-05
### Fixed
- Input Monitoring "Request Access" button now properly opens System Preferences to the Input Monitoring pane.

## [1.3.2] - 2026-02-04
### Fixed
- Slack text replacement reliability by adding focus delays and more robust paste fallback.
- Clipboard persistence bug where new text was not saved when Accessibility API reported success.

## [1.3.1] - 2026-02-04
### Added
- Added version info to the bottom of the Settings screen.

### Removed
- Failing GitHub workflow (`build.yml`) due to Keychain access restrictions in CI.
- Stray `package-lock.json` file.

### Changed
- Refactored Keychain service identification to use `Bundle.main.bundleIdentifier` dynamically.
- Improved project portability by removing hardcoded personal domains.

### Fixed
- Outdated `OpenAIService` unit tests to align with current implementation.
- Added tests for Keychain service identification.

## [1.2] - 2026-02-03
### Added
- Shields.io badges to README (Swift version, macOS platform, License, Version).
- Dedicated `CONTRIBUTING.md` guide.
- `CHANGELOG.md` file.
- Security section to README detailing Keychain usage and privacy.
- GitHub Actions workflow for build verification.

### Changed
- Refactored `OpenAIService` to use `Codable` for JSON handling.
- Improved error handling in `OpenAIService` with a custom `OpenAIError` enum.
- Bumped version to 1.2 in `Info.plist`.

### Fixed
- Removed force unwraps in `AccessibilityManager` for safer URL handling and increased stability.

## [1.1] - 2026-02-03
### Added
- Rebranded project to "McWritely".
- New app icon (mustache pencil).
- Added license information to README (CC BY-NC 4.0).

## [1.0] - 2026-02-02
### Added
- Initial release of Writely (now McWritely).
- Core accessibility-based capture and replacement logic.
- OpenAI GPT-4o-mini integration.
- Keychain storage for API keys.
- Settings UI for configuration.
