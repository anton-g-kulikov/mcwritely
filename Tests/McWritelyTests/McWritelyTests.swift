import XCTest
@testable import McWritely

final class McWritelyTests: XCTestCase {
    func testKeychainStoreRoundTrip() throws {
        let service = "com.antonkulikov.mcwritely.tests"
        let account = "test-\(UUID().uuidString)"
        let value = "test-key-\(UUID().uuidString)"
        
        let store = KeychainStore.shared
        _ = store.delete(service: service, account: account)
        guard store.save(value, service: service, account: account) else {
            throw XCTSkip("Keychain not available or denied for tests.")
        }
        XCTAssertEqual(store.read(service: service, account: account), value)
        _ = store.delete(service: service, account: account)
    }
    
    func testOpenAIResponseParsingSuccess() throws {
        let json = """
        {
            "choices": [
                {
                    "message": {
                        "content": "  Hello world  "
                    }
                }
            ]
        }
        """.data(using: .utf8)!
        
        let decoded = try JSONDecoder().decode(OpenAIService.OpenAIResponse.self, from: json)
        let content = decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(content, "Hello world")
    }
    
    func testOpenAIResponseParsingFailure() throws {
        let json = """
        {
            "choices": [
                {
                    "message": {}
                }
            ]
        }
        """.data(using: .utf8)!
        
        XCTAssertThrowsError(try JSONDecoder().decode(OpenAIService.OpenAIResponse.self, from: json))
    }
    
    func testKeychainServiceIdentifier() throws {
        // Since we are in a test environment, Bundle.main.bundleIdentifier might be nil
        // or the test runner's bundle ID. We just want to ensure it doesn't crash
        // and returns a reasonable string.
        let settings = Settings.shared
        // We can't easily access the private static keychainService, but we can verify
        // that KeychainStore operations don't fail when called via Settings.
        settings.apiKey = "test-key"
        XCTAssertEqual(settings.apiKey, "test-key")
        settings.apiKey = ""
        XCTAssertEqual(settings.apiKey, "")
    }
    
    func testKeepNewTextInClipboardDefaultIsFalse() throws {
        throw XCTSkip("Removed in 2.0.0: corrected text is always kept on the clipboard after Apply.")
    }

    func testSettingsMigrationRemovesLegacyClipboardKey() throws {
        let suiteName = "com.antonkulikov.mcwritely.tests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.set(true, forKey: "keep_new_text_in_clipboard")
        XCTAssertNotNil(defaults.object(forKey: "keep_new_text_in_clipboard"))

        SettingsMigration.migrate(userDefaults: defaults)
        XCTAssertNil(defaults.object(forKey: "keep_new_text_in_clipboard"))

        defaults.removePersistentDomain(forName: suiteName)
    }

    func testViewModelResetClearsState() throws {
        let vm = CorrectionViewModel()
        vm.originalText = "orig"
        vm.correctedText = "corr"
        vm.isProcessing = true
        vm.errorMessage = "err"
        vm.currentTarget = nil

        vm.reset()

        XCTAssertEqual(vm.originalText, "")
        XCTAssertEqual(vm.correctedText, "")
        XCTAssertFalse(vm.isProcessing)
        XCTAssertNil(vm.errorMessage)
        XCTAssertNil(vm.currentTarget)
    }

    func testRTFConversionToPlainText() throws {
        let attributed = NSAttributedString(string: "Hello RTF")
        let rtfData = try attributed.data(
            from: NSRange(location: 0, length: attributed.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )

        let extracted = PasteboardTextExtractor.plainText(fromRTF: rtfData)
        XCTAssertEqual(extracted, "Hello RTF")
    }

    func testHTMLConversionToPlainText() throws {
        let html = "<html><body><b>Hello</b> world</body></html>"
        let data = try XCTUnwrap(html.data(using: .utf8))

        let extracted = PasteboardTextExtractor.plainText(fromHTML: data)
        let s = try XCTUnwrap(extracted)
        XCTAssertTrue(s.contains("Hello"))
        XCTAssertTrue(s.contains("world"))
    }

    func testReadObjectsCoercionExtractsString() throws {
        let objects: [Any] = [NSString(string: "Hello from coercion")]
        let extracted = PasteboardTextExtractor.plainText(fromReadObjects: objects)
        XCTAssertEqual(extracted, "Hello from coercion")
    }

    func testExtractSubstringFromRangeHappyPath() throws {
        let value = "Hello world"
        let extracted = StringRangeExtractor.substring(in: value, range: NSRange(location: 6, length: 5))
        XCTAssertEqual(extracted, "world")
    }

    func testExtractSubstringFromRangeInvalidRange() throws {
        XCTAssertNil(StringRangeExtractor.substring(in: "Hi", range: NSRange(location: 0, length: 9)))
        XCTAssertNil(StringRangeExtractor.substring(in: "Hi", range: NSRange(location: -1, length: 1)))
    }

    func testReplacementVerificationSelectedTextMatch() throws {
        let ok = ReplacementVerifier.isVerified(
            selectedText: "  Hello  ",
            value: nil,
            correctedText: "Hello"
        )
        XCTAssertTrue(ok)
    }

    func testReplacementVerificationValueContainsCorrectedText() throws {
        let ok = ReplacementVerifier.isVerified(
            selectedText: nil,
            value: "prefix Hello suffix",
            correctedText: "Hello"
        )
        XCTAssertTrue(ok)
    }

    func testReplacementVerificationNegativeCases() throws {
        XCTAssertFalse(ReplacementVerifier.isVerified(selectedText: nil, value: nil, correctedText: "Hello"))
        XCTAssertFalse(ReplacementVerifier.isVerified(selectedText: "Something else", value: "Other", correctedText: "Hello"))
    }

    func testReplacementResultShouldClosePanelForUnverifiedButNotFailed() throws {
        XCTAssertTrue(ReplacementResult(method: .paste, state: .verified, detail: nil).shouldClosePanel)
        XCTAssertTrue(ReplacementResult(method: .paste, state: .unverified, detail: "could not verify").shouldClosePanel)
        XCTAssertFalse(ReplacementResult(method: .paste, state: .failed, detail: "did not apply").shouldClosePanel)
    }

    func testRangeReplacementHappyPath() throws {
        let s = "Hello world"
        let replaced = StringRangeReplacer.replacing(in: s, range: NSRange(location: 6, length: 5), with: "there")
        XCTAssertEqual(replaced, "Hello there")
    }

    func testRangeReplacementRejectsInvalidRanges() throws {
        XCTAssertNil(StringRangeReplacer.replacing(in: "Hi", range: NSRange(location: 0, length: 9), with: "x"))
        XCTAssertNil(StringRangeReplacer.replacing(in: "Hi", range: NSRange(location: -1, length: 1), with: "x"))
    }

    func testSelectionTextResolverPrefersSelectedText() throws {
        let resolved = SelectionTextResolver.resolve(
            selectedText: "  direct  ",
            stringForRange: "range",
            value: "Hello world",
            selectedRange: NSRange(location: 6, length: 5)
        )
        XCTAssertEqual(resolved, "direct")
    }

    func testSelectionTextResolverFallsBackToStringForRange() throws {
        let resolved = SelectionTextResolver.resolve(
            selectedText: "   ",
            stringForRange: "  from range  ",
            value: "Hello world",
            selectedRange: NSRange(location: 6, length: 5)
        )
        XCTAssertEqual(resolved, "from range")
    }

    func testSelectionTextResolverFallsBackToValueAndRange() throws {
        let resolved = SelectionTextResolver.resolve(
            selectedText: nil,
            stringForRange: nil,
            value: "Hello world",
            selectedRange: NSRange(location: 6, length: 5)
        )
        XCTAssertEqual(resolved, "world")
    }

    func testSelectionTextResolverReturnsNilWhenNothingUsable() throws {
        let resolved = SelectionTextResolver.resolve(
            selectedText: "   ",
            stringForRange: "\n",
            value: "Hi",
            selectedRange: NSRange(location: 0, length: 9)
        )
        XCTAssertNil(resolved)
    }

    func testNormalizeForVerificationNBSPAndNewlines() throws {
        let s1 = "Hello\u{00A0}world\r\nNext"
        let s2 = "Hello world\nNext"
        XCTAssertEqual(TextNormalizer.normalizeForVerification(s1), TextNormalizer.normalizeForVerification(s2))
    }

    func testNormalizeForVerificationWhitespaceRuns() throws {
        let s1 = "Hello   world\t\t!"
        let s2 = "Hello world !"
        XCTAssertEqual(TextNormalizer.normalizeForVerification(s1), TextNormalizer.normalizeForVerification(s2))
    }

    func testClipboardReassertPolicyUsesNormalization() throws {
        XCTAssertFalse(ClipboardReassertPolicy.shouldReassert(
            currentClipboardText: "corrected",
            correctedText: "corrected",
            originalSelectedText: "original"
        ))

        XCTAssertTrue(ClipboardReassertPolicy.shouldReassert(
            currentClipboardText: "MCWR_SOMETHING",
            correctedText: "corrected",
            originalSelectedText: "original"
        ))

        // Clipboard may get a normalized version of the original selection (NBSP -> space, CRLF -> LF).
        XCTAssertTrue(ClipboardReassertPolicy.shouldReassert(
            currentClipboardText: "Hello world\nNext",
            correctedText: "corrected",
            originalSelectedText: "Hello\u{00A0}world\r\nNext"
        ))
    }

    func testReplacementVerificationUsesNormalization() throws {
        // Notion/Electron often normalize whitespace; verification should treat these as equivalent.
        let ok = ReplacementVerifier.isVerified(
            selectedText: "Hello\u{00A0}world",
            value: nil,
            correctedText: "Hello world"
        )
        XCTAssertTrue(ok)
    }

    func testMenuCopyCandidateSelectorPrefersCmdC() throws {
        let candidates: [(MenuCopyCandidate, Int)] = [
            (MenuCopyCandidate(title: "Copy Style", cmdChar: "c", cmdModifiers: 256 | 2048, enabled: true), 0), // Cmd+Opt+C
            (MenuCopyCandidate(title: "Copy", cmdChar: "c", cmdModifiers: 256, enabled: true), 1), // Cmd+C
            (MenuCopyCandidate(title: "Copy Link", cmdChar: "c", cmdModifiers: 256 | 512, enabled: true), 2) // Cmd+Shift+C
        ]

        let picked = MenuCopyCandidateSelector.chooseBest(from: candidates.map { (candidate: $0.0, index: $0.1) })
        XCTAssertEqual(picked?.1, 1)
    }

    func testMenuCopyCandidateSelectorIgnoresDisabled() throws {
        let candidates: [(MenuCopyCandidate, Int)] = [
            (MenuCopyCandidate(title: "Copy", cmdChar: "c", cmdModifiers: 256, enabled: false), 0),
            (MenuCopyCandidate(title: "Copy Style", cmdChar: "c", cmdModifiers: 256 | 2048, enabled: true), 1)
        ]

        let picked = MenuCopyCandidateSelector.chooseBest(from: candidates.map { (candidate: $0.0, index: $0.1) })
        XCTAssertEqual(picked?.1, 1)
    }

    func testMenuCopyCandidateSelectorUsesTitleAsTieBreaker() throws {
        let candidates: [(MenuCopyCandidate, Int)] = [
            (MenuCopyCandidate(title: "Copy Something", cmdChar: "c", cmdModifiers: 256, enabled: true), 0),
            (MenuCopyCandidate(title: "Copy", cmdChar: "c", cmdModifiers: 256, enabled: true), 1),
            (MenuCopyCandidate(title: nil, cmdChar: "c", cmdModifiers: 256, enabled: true), 2)
        ]

        let picked = MenuCopyCandidateSelector.chooseBest(from: candidates.map { (candidate: $0.0, index: $0.1) })
        XCTAssertEqual(picked?.1, 1)
    }

    func testMenuPasteCandidateSelectorPrefersCmdV() throws {
        let candidates: [(MenuCopyCandidate, Int)] = [
            (MenuCopyCandidate(title: "Paste and Match Style", cmdChar: "v", cmdModifiers: 256 | 2048 | 512, enabled: true), 0), // Cmd+Opt+Shift+V
            (MenuCopyCandidate(title: "Paste", cmdChar: "v", cmdModifiers: 256, enabled: true), 1), // Cmd+V
            (MenuCopyCandidate(title: "Paste Special", cmdChar: "v", cmdModifiers: 256 | 512, enabled: true), 2) // Cmd+Shift+V
        ]

        let picked = MenuPasteCandidateSelector.chooseBest(from: candidates.map { (candidate: $0.0, index: $0.1) })
        XCTAssertEqual(picked?.1, 1)
    }

    func testMenuPasteCandidateSelectorIgnoresDisabled() throws {
        let candidates: [(MenuCopyCandidate, Int)] = [
            (MenuCopyCandidate(title: "Paste", cmdChar: "v", cmdModifiers: 256, enabled: false), 0),
            (MenuCopyCandidate(title: "Paste and Match Style", cmdChar: "v", cmdModifiers: 256 | 512, enabled: true), 1)
        ]

        let picked = MenuPasteCandidateSelector.chooseBest(from: candidates.map { (candidate: $0.0, index: $0.1) })
        XCTAssertEqual(picked?.1, 1)
    }

    func testMenuPasteCandidateSelectorUsesTitleAsTieBreaker() throws {
        let candidates: [(MenuCopyCandidate, Int)] = [
            (MenuCopyCandidate(title: "Paste Something", cmdChar: "v", cmdModifiers: 256, enabled: true), 0),
            (MenuCopyCandidate(title: "Paste", cmdChar: "v", cmdModifiers: 256, enabled: true), 1),
            (MenuCopyCandidate(title: nil, cmdChar: "v", cmdModifiers: 256, enabled: true), 2)
        ]

        let picked = MenuPasteCandidateSelector.chooseBest(from: candidates.map { (candidate: $0.0, index: $0.1) })
        XCTAssertEqual(picked?.1, 1)
    }
}
