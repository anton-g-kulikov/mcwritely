# McWritely Test Documentation

## Test Framework Configuration

**Framework**: XCTest
**Test Command**: `swift test` or `./scripts/test.sh`

## Test Cases

### CORE-TEST-001: Keychain Store Round-Trip

- **Status**: ✅ COMPLETED
- **Description**: Verify that the `KeychainStore` can safely save, read, and delete values from the macOS Keychain.
- **Expected**: A string saved to the keychain should be retrieved exactly as it was stored, and successfully deleted afterward.
- **Test File**: `Tests/McWritelyTests/McWritelyTests.swift:testKeychainStoreRoundTrip`

### API-TEST-002: OpenAI Response Parsing Success

- **Status**: ✅ COMPLETED
- **Description**: Verify that the `OpenAIService` correctly parses a successful JSON response from the OpenAI API.
- **Expected**: The system should extract the `content` string from the first choice and trim whitespace.
- **Test File**: `Tests/McWritelyTests/McWritelyTests.swift:testOpenAIResponseParsingSuccess`

### API-TEST-003: OpenAI Response Parsing Failure

- **Status**: ✅ COMPLETED
- **Description**: Verify that the `OpenAIService` throws an error when encountering an invalid or empty response structure.
- **Expected**: An error should be thrown when the expected JSON path is missing.
- **Test File**: `Tests/McWritelyTests/McWritelyTests.swift:testOpenAIResponseParsingFailure`

### UTIL-TEST-004: Default Clipboard Settings

- **Status**: ✅ COMPLETED
- **Description**: Verify that the default value for `keepNewTextInClipboard` is `false`.
- **Expected**: `Settings.shared.keepNewTextInClipboard` should initialize to `false`.
- **Test File**: `Tests/McWritelyTests/McWritelyTests.swift:testKeepNewTextInClipboardDefaultIsFalse`

### CORE-TEST-005: Selection Capture Validation

- **Status**: 📋 NOT STARTED
- **Description**: Verify that the accessibility-based text capture correctly retrieves highlighted text from a target application.
- **Expected**: The captured string should match the actual selection in a controlled test app.

### CORE-TEST-006: Prompt Construction Logic

- **Status**: 📋 NOT STARTED
- **Description**: Verify that the system prompt and user content are correctly formatted before being sent to the API.
- **Expected**: The resulting payload contains both the correct system instructions and the input text.

### CORE-TEST-007: Keychain Service Identification

- **Status**: ✅ COMPLETED
- **Description**: Verify that the keychain service identifier is correctly derived from the bundle identifier.
- **Expected**: The system should use the bundle ID if available, or a sensible default.
- **Test File**: `Tests/McWritelyTests/McWritelyTests.swift:testKeychainServiceIdentifier`

### UI-TEST-008: Version Info Display

- **Status**: ✅ COMPLETED
- **Description**: Verify that the current application version is displayed at the bottom of the Settings screen.
- **Expected**: The text "Version 1.3.1" (or current bundle version) is visible and styled as small secondary text.

## Test Coverage Goals

- **Unit Tests**: Coverage for all core logic including selection handlers and API services.
- **Integration Tests**: Verification of the full hotkey-capture-process-replace cycle.

## Notes

This documentation follows the TDD approach of the 7-step workflow. All new test cases must be documented here before implementation.
