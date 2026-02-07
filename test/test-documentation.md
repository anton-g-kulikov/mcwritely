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

### UI-TEST-018: ViewModel Reset Clears UI State

- **Status**: ✅ COMPLETED
- **Description**: Verify that resetting the correction view model clears user-visible state (texts, error, target, processing flag).
- **Expected**: All fields are reset to defaults without crashing.

### CORE-TEST-019: Extract Substring From NSRange (Happy Path)

- **Status**: ✅ COMPLETED
- **Description**: Verify that selected text can be extracted from a full value string using a valid `NSRange`.
- **Expected**: Extracted substring equals expected.

### CORE-TEST-020: Extract Substring From NSRange (Invalid Range)

- **Status**: ✅ COMPLETED
- **Description**: Verify that invalid ranges are rejected safely.
- **Expected**: Helper returns `nil` (or equivalent) without crashing.

### CORE-TEST-021: Selection Text Resolution Precedence

- **Status**: ✅ COMPLETED
- **Description**: Verify that selection-capture logic chooses the best available text representation deterministically.
- **Inputs**:
  - `selectedText` present vs empty
  - `stringForRange`/`attributedStringForRange` present vs empty
  - `value` + `selectedTextRange` present vs missing/out-of-bounds
- **Expected**:
  - Prefer non-empty `selectedText` when available.
  - Else prefer non-empty `stringForRange`/`attributedStringForRange` output when available.
  - Else fall back to `substring(value, selectedTextRange)` when valid.
  - Else return `nil`.
- **Test File**: `Tests/McWritelyTests/McWritelyTests.swift:testSelectionTextResolverPrefersSelectedText` and related resolver tests

### CORE-TEST-022: Selection Text Resolution Handles Trimming

- **Status**: ✅ COMPLETED
- **Description**: Verify that resolved selection text is trimmed and empty results are treated as absent.
- **Expected**: Whitespace-only candidates should be ignored and the resolver should proceed to the next candidate.
- **Test File**: `Tests/McWritelyTests/McWritelyTests.swift:testSelectionTextResolverFallsBackToStringForRange` and `testSelectionTextResolverReturnsNilWhenNothingUsable`

### CORE-TEST-005: Selection Capture Validation

- **Status**: 📋 NOT STARTED
- **Description**: Verify that the accessibility-based text capture correctly retrieves highlighted text from a target application.
- **Expected**: The captured string should match the actual selection in a controlled test app.

### CORE-TEST-023: Manual Validation in Electron Editors (Codex, VS Code)

- **Status**: 📋 NOT STARTED
- **Description**: Validate that clipboard-fallback capture retrieves selected text in Electron-based editors where AX selection APIs are missing or unreliable.
- **Steps**:
  - In Codex app: select a short snippet (include non-ASCII), trigger `Cmd+Opt+Shift+G`, ensure McWritely shows the selection.
  - In VS Code: select a short snippet in the editor, trigger `Cmd+Opt+Shift+G`, ensure McWritely shows the selection.
- **Expected**: McWritely’s panel populates with the selected text (no “No text selected” error).

### CORE-TEST-028: Hotkey Capture Failure Shows Error (Manual)

- **Status**: 📋 NOT STARTED
- **Description**: Verify that if capture fails, the hotkey still triggers a capture attempt and shows an actionable error (not a silent empty panel).
- **Steps**:
  - Trigger McWritely hotkey in an app with no selection.
  - Confirm McWritely shows a spinner briefly and then shows a red error message.
  - Trigger McWritely hotkey in Codex/VS Code with a selection.
  - If it fails, confirm it shows a red error message (including the app name) rather than staying silently empty.
- **Expected**: No silent empty state after hotkey; failures are visible and actionable.

### CORE-TEST-029: Capture Before Panel Preserves Electron Selection (Manual)

- **Status**: 📋 NOT STARTED
- **Description**: Verify that selection capture happens before McWritely activates and shows its panel, preserving selection in Electron apps.
- **Steps**:
  - In VS Code: select text, trigger McWritely hotkey; confirm the selection remains in VS Code during capture and McWritely shows the captured text.
  - In Codex: select text, trigger McWritely hotkey; confirm the selection remains and McWritely shows the captured text.
- **Expected**: No “focus hop” that clears selection prior to capture; captured text appears in McWritely.

### CORE-TEST-030: Panel Does Not Auto-Hide During Capture (Manual)

- **Status**: 📋 NOT STARTED
- **Description**: Verify McWritely does not close itself immediately when the originating app regains focus during a hotkey-triggered capture.
- **Steps**:
  - In Codex/VS Code: select text, trigger hotkey.
  - Observe whether McWritely panel remains visible (even if it shows an error).
- **Expected**: Panel stays open until the user closes it or Apply succeeds.

### CORE-TEST-032: Electron Apply Replaces Selection (Manual)

- **Status**: 📋 NOT STARTED
- **Description**: Verify that Apply replaces the selected text in Electron editors (Codex, VS Code) rather than appending at the caret.
- **Steps**:
  - In Codex app: select a sentence, trigger `Cmd+Opt+Shift+G`, wait for improved text, click Apply.
  - Confirm the original selection is replaced (not duplicated/appended).
  - Repeat in VS Code (in an editor buffer).
- **Expected**: Resulting text equals the corrected text (single copy), and the original text is not left behind.

### CORE-TEST-033: Paste Fallback Verifies In Notion (Manual)

- **Status**: 📋 NOT STARTED
- **Description**: Verify that when Apply succeeds in Notion, McWritely does not incorrectly show the red “could not verify” warning.
- **Steps**:
  - In Notion: select a short snippet, trigger `Cmd+Opt+Shift+G`, click Apply.
  - Confirm the Notion document updates to the corrected text.
  - Confirm McWritely closes automatically (verified) or at minimum does not show a red error for a successful replacement.
- **Expected**: Successful Notion paste yields a verified outcome (or a non-red warning if verification is impossible).

### CORE-TEST-034: Paste Fallback Does Not Duplicate (Manual)

- **Status**: 📋 NOT STARTED
- **Description**: Verify paste fallback executes at most once per Apply and does not duplicate the corrected text (especially in Electron editors).
- **Steps**:
  - In Codex/VS Code: select a short snippet, run McWritely, click Apply.
  - Confirm the corrected text appears exactly once (not repeated).
  - Repeat with a longer selection (2-3 sentences).
- **Expected**: No repeated/duplicated insertions from a single Apply.

### CORE-TEST-035: Menu Paste Candidate Scoring (Unit)

- **Status**: 📋 NOT STARTED
- **Description**: Verify that menu Paste selection chooses the most likely Edit -> Paste menu item when multiple items use cmdChar "v" (Paste vs Paste and Match Style / etc).
- **Cases**:
  - Prefer `Cmd+V` over `Cmd+Opt+Shift+V` and other modifier combos.
  - Ignore disabled menu items.
  - Use the menu item title only as a tie-breaker (prefer exact "Paste" when available).
- **Expected**: The selector returns the best candidate deterministically for the provided inputs.
- **Test File**: `Tests/McWritelyTests/McWritelyTests.swift:testMenuPasteCandidateSelectorPrefersCmdV` and related tests

### CORE-TEST-031: Menu Copy Candidate Scoring (Unit)

- **Status**: ✅ COMPLETED
- **Description**: Verify that menu Copy selection chooses the most likely Edit -> Copy menu item when multiple `cmdChar == "c"` items exist (Copy vs Copy Style / Copy Link / etc).
- **Cases**:
  - Prefer `Cmd+C` over `Cmd+Opt+C` and other modifier combos.
  - Ignore disabled menu items.
  - Use the menu item title only as a tie-breaker (prefer exact "Copy" when available).
- **Expected**: The selector returns the best candidate deterministically for the provided inputs.
- **Test File**: `Tests/McWritelyTests/McWritelyTests.swift:testMenuCopyCandidateSelectorPrefersCmdC` and related tests

### CORE-TEST-024: Text Normalization For Verification

- **Status**: ✅ COMPLETED
- **Description**: Verify that text normalization makes verification resilient to platform/editor formatting differences.
- **Cases**:
  - NBSP (`\\u{00A0}`) vs regular spaces
  - CRLF vs LF
  - Multiple whitespace runs vs single spaces
- **Expected**: Normalized strings compare equal when they are visually equivalent.
- **Test File**: `Tests/McWritelyTests/McWritelyTests.swift:testNormalizeForVerificationNBSPAndNewlines` and `testNormalizeForVerificationWhitespaceRuns`

### CORE-TEST-025: Notion Paste Verification Fallback (Manual)

- **Status**: 📋 NOT STARTED
- **Description**: Verify that after successful paste into Notion, McWritely does not show a red “could not verify” warning and the panel closes automatically.
- **Steps**:
  - In Notion: select a short snippet, run McWritely, press Apply.
  - Confirm the document updates.
  - Confirm McWritely closes (verified) instead of showing an unverified warning.
- **Expected**: Verified outcome for successful paste in Notion.

### UI-TEST-026: Accessibility Permission UI Refresh (Manual)

- **Status**: 📋 NOT STARTED
- **Description**: Verify that Settings reflects Accessibility permission changes.
- **Steps**:
  - Ensure McWritely is enabled in System Settings -> Privacy & Security -> Accessibility.
  - Open McWritely Settings.
  - Confirm the Permissions row shows a green checkmark (not "Request Access").
  - If it initially shows "Request Access", toggle permission off/on in System Settings and return to McWritely; confirm the UI updates on app-activate.
- **Expected**: The row updates without requiring a full app restart (best effort), or provides a clear indication if macOS requires restart.

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
