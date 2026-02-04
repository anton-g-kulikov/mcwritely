# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
