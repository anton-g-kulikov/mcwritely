# McWritely Project Task List

## Current Tasks

- [x] **CORE-TASK-019: Remove force unwraps in AccessibilityManager** - ✅ **COMPLETED** - Replace force unwraps with safe optional binding to prevent crashes
- [x] **API-TASK-020: Refactor OpenAIService to use Codable** - ✅ **COMPLETED** - Replace JSONSerialization with native Swift Codable structs
- [x] **API-TASK-021: Implement idiomatic OpenAIError enum** - ✅ **COMPLETED** - Replace generic NSError with strongly typed OpenAIError
- [x] **DOC-TASK-023: Add Shields.io badges (Swift, macOS, License) to README** - ✅ **COMPLETED** - Add "flare" to the top of README
- [x] **DOC-TASK-024: Extract CONTRIBUTING.md and initialize CHANGELOG.md** - ✅ **COMPLETED** - Standardize project documentation
- [ ] **RELEASE-TASK-025: Tag v1.2 and establish release process** - 🟡 **IN PROGRESS** - Create git tag and define release workflow
- [ ] **CONFIG-TASK-026: Implement GitHub Actions for build verification** - 🟡 **IN PROGRESS** - Add CI workflow for automated builds
- [x] **RELEASE-TASK-022: Bump version to 1.2 and commit changes** - ✅ **COMPLETED** - Bump version in Info.plist and create granular commits
- [x] **DOC-TASK-018: Update Documentation with Security Findings** - ✅ **COMPLETED** - Add security notes to README based on review
- [x] **CORE-TASK-017: Conduct Codebase Review (Security & Best Practices)** - ✅ **COMPLETED** - Reviewing codebase for security and style compliance
- [x] **DOC-TASK-014: Add CC BY-NC 4.0 license information to README** - ✅ **COMPLETED** - Added license link and terms as requested
- [x] **DOC-TASK-013: Update test documentation and define test cases** - ✅ **COMPLETED** - Aligned test documentation with Swift/XCTest and documented current/planned tests
- [x] **DOC-TASK-016: Add app icon to README.md** - ✅ **COMPLETED** - Included the new mustache pencil icon in the project documentation.
- [x] **UI-TASK-015: Generate and implement new "McWritely" app icon** - ✅ **COMPLETED** - Created a pencil with a mustache icon and updated the app bundle.
- [x] **CONFIG-TASK-013: Rename project from Writely to McWritely** - ✅ **COMPLETED** - Updated all project assets, documentation, and source code.

## Completed Tasks

- [x] **CORE-TASK-001: Initial project architecture and structure** - ✅ **COMPLETED** - Initial setup of the McWritely Swift project
- [x] **CORE-TASK-012: Implement unit tests and test runner script** - ✅ **COMPLETED** - Added XCTest targets and helper scripts for verification
- [x] **CORE-TASK-002: Implement accessibility-based selection capture and replacement** - ✅ **COMPLETED** - Core logic for interacting with other applications
- [x] **AUTH-TASK-003: Implement secure API key storage using macOS Keychain** - ✅ **COMPLETED** - Secure storage for user credentials
- [x] **API-TASK-004: Integrate OpenAI GPT-4o-mini for writing assistance** - ✅ **COMPLETED** - Backend service for text refinement
- [x] **CONFIG-TASK-005: Develop build and DMG packaging scripts** - ✅ **COMPLETED** - Automation for building and distribution
- [x] **DOC-TASK-006: Document setup, usage, and customization in README** - ✅ **COMPLETED** - Comprehensive user and developer documentation
- [x] **CORE-TASK-007: Implement asynchronous capture/replacement and clipboard safety** - ✅ **COMPLETED** - Improving reliability and user experience
- [x] **UI-TASK-008: Implement Settings UI for API keys and permissions** - ✅ **COMPLETED** - User-facing configuration interface
- [x] **UTIL-TASK-009: Add clipboard retention toggle for user control** - ✅ **COMPLETED** - New feature for clipboard management
- [x] **UI-TASK-010: Refine UI aesthetics (window shadows, alignment)** - ✅ **COMPLETED** - Polishing the application interface

## Task Status Legend

- 🟡 **IN PROGRESS** - Currently being worked on
- ✅ **COMPLETED** - Task finished and verified
- ❌ **BLOCKED** - Task cannot proceed due to dependency or issue
- ⏸️ **ON HOLD** - Task paused for specific reason
- 📋 **NOT STARTED** - Task identified but not yet begun

## Notes

This task list follows the 7-step development workflow. All tasks must be documented here before implementation begins.
