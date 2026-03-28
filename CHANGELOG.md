# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.9] - 2026-03-28

### Fixed

- Switched primary button rendering to an explicit blue AppKit-layer style so `Apply Suggestion` remains visibly primary.
- Reduced panel footer/height reserve constants to remove the large empty area under `Close` for short results.

## [2.1.8] - 2026-03-28

### Fixed

- Ensured `Apply Suggestion` renders as explicitly blue (primary) in the non-key floating panel.
- Reduced reserved panel/footer height so short content no longer leaves a large empty area below `Close`.

## [2.1.7] - 2026-03-28

### Changed

- Kept `Apply Suggestion` AppKit-native but forced its control appearance to active Aqua so it reads as the primary action even inside McWritely’s non-key floating panel.

## [2.1.6] - 2026-03-28

### Changed

- Refined the native footer hierarchy by toning the oversized `Apply Suggestion` button back down to a more normal AppKit scale and tightening footer spacing.

## [2.1.5] - 2026-03-28

### Changed

- Made the AppKit-native `Apply Suggestion` button much larger and more prominent with a taller target and larger title/icon while keeping `Close` visually secondary.

## [2.1.4] - 2026-03-28

### Fixed

- Made the panel height adapt to loading, short-result, and long-result states so short text no longer leaves large empty areas.

## [2.1.3] - 2026-03-28

### Fixed

- Switched the primary `Apply Suggestion` control to an AppKit-native button so it renders correctly in McWritely’s non-activating floating panel.

## [2.1.2] - 2026-03-28

### Fixed

- Moved `Apply Suggestion` into the fixed footer so the primary action remains visible even for multiline results.
- Reduced excess correction panel height so the empty and error states no longer leave large dead space.

## [2.1.1] - 2026-03-28

### Fixed

- Fixed correction panel sizing so the primary `Apply Suggestion` button is not clipped after recent macOS layout changes.

## [1.4.4] - 2026-02-05

### Changed

- Built updated DMG.

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
