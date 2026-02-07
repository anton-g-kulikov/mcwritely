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
- **Description**: (Legacy) This test used to verify `keepNewTextInClipboard` defaulted to `false`.
- **Expected**: As of v2.0.0, this setting no longer exists; corrected text is always kept on the clipboard after Apply.
- **Test File**: `Tests/McWritelyTests/McWritelyTests.swift:testKeepNewTextInClipboardDefaultIsFalse` (skipped)

### UTIL-TEST-012: Settings Migration Removes Legacy Clipboard Key

- **Status**: ✅ COMPLETED
- **Description**: Verify that legacy UserDefaults key `keep_new_text_in_clipboard` is removed during settings migration, since clipboard behavior is now always "keep corrected text after Apply".
- **Expected**: After migration, `keep_new_text_in_clipboard` is absent from the specified UserDefaults store.

### CORE-TEST-013: Replacement Verification (Selected Text Match)

- **Status**: ✅ COMPLETED
- **Description**: Verify that replacement is considered verified when the target app's selected text matches the corrected text (trimmed).
- **Expected**: Verified = true.

### CORE-TEST-014: Replacement Verification (Value Contains Corrected Text)

- **Status**: ✅ COMPLETED
- **Description**: Verify that replacement can be treated as verified when the target app's value contains the corrected text (fallback verification).
- **Expected**: Verified = true.

### CORE-TEST-015: Replacement Verification Negative Cases

- **Status**: ✅ COMPLETED
- **Description**: Verify that replacement is not verified when neither selected text nor value indicate the corrected text was applied.
- **Expected**: Verified = false.

### CORE-TEST-016: Range Replacement Helper (Happy Path)

- **Status**: ✅ COMPLETED
- **Description**: Verify that a helper can replace a substring in a string given a valid `NSRange`.
- **Expected**: Output string equals expected with range replaced.

### CORE-TEST-017: Range Replacement Helper (Bounds Checks)

- **Status**: ✅ COMPLETED
- **Description**: Verify that invalid ranges (negative/out of bounds) are rejected safely.
- **Expected**: Helper returns `nil` (or equivalent) without crashing.

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

### CORE-TEST-009: Rich Text Conversion (RTF -> Plain Text)

- **Status**: ✅ COMPLETED
- **Description**: Verify that RTF data can be converted into a plain text string for clipboard fallback capture.
- **Inputs**: RTF `Data` produced from an attributed string (for example "Hello RTF").
- **Expected**: Extracted plain text equals the original string.

### CORE-TEST-010: Rich Text Conversion (HTML -> Plain Text)

- **Status**: ✅ COMPLETED
- **Description**: Verify that HTML data can be converted into a plain text string for clipboard fallback capture.
- **Inputs**: HTML `Data` such as `<b>Hello</b> world`.
- **Expected**: Extracted plain text is non-empty and contains "Hello" and "world" in the correct order.

### CORE-TEST-011: Clipboard Coercion Fallback (NSString Read)

- **Status**: ✅ COMPLETED
- **Description**: Verify that the clipboard extraction logic can fall back to AppKit coercion (`readObjects(forClasses: [NSString.self])`) when a direct `.string` flavor is missing.
- **Expected**: The helper path returns a non-empty plain string when provided a string-like object.

## Test Coverage Goals

- **Unit Tests**: Coverage for all core logic including selection handlers and API services.
- **Integration Tests**: Verification of the full hotkey-capture-process-replace cycle.

## Notes

This documentation follows the TDD approach of the 7-step workflow. All new test cases must be documented here before implementation.
