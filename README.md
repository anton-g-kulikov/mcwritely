# McWritely

McWritely is a lightweight macOS utility that provides AI-powered writing assistance in any application. It captures your selected text, refines it using OpenAI, and lets you replace the original text with a much better version instantly.

## 🚀 How it works

1.  **Select**: Highlight text in any app (Slack, Browser, Mail, etc.).
2.  **Trigger**: Press **`Cmd + Opt + Shift + G`**.
3.  **Refine**: McWritely captures the selection and shows a floating panel with an improved version.
4.  **Applied**: Click **"Apply"** to replace the original text with the AI suggestion.

## 🛠 Setup

1.  **API Key**: Open McWritely, go to **Settings** (click the menu bar icon or press `Cmd + ,`), and enter your OpenAI API Key. Your key is stored locally in macOS Keychain.
2.  **Permissions**: McWritely requires **Accessibility** permissions to capture and replace text in other apps, and **Input Monitoring** permissions for the global hotkey.
    - Go to **System Settings > Privacy & Security > Accessibility**.
    - Add and enable **McWritely**.
    - Go to **System Settings > Privacy & Security > Input Monitoring**.
    - Add and enable **McWritely**.
    - You can also initiate permission prompts from the McWritely Settings window.

## 📦 Installation & Distribution

You can build the app from source or create a portable DMG package.

### Build Locally
```bash
./build.sh
```
This creates `McWritely.app` in the root directory.

### Create a DMG
```bash
./package.sh
```
This generates `McWritely.dmg` for easy distribution and installation.

## 💡 Troubleshooting

### "The application can't be opened"
If you see this error when trying to open McWritely on another computer, it is usually because macOS has flagged the app as quarantined since it was downloaded from the internet and is unsigned.

**Solution 1 (Recommended):**
1.  **Right-click** (or Control-click) the `McWritely` app icon.
2.  Select **Open** from the menu.
3.  In the dialog that appears, click **Open** again. This bypasses Gatekeeper for this specific app.

**Solution 2 (Terminal):**
Run the following command in Terminal to clear the quarantine flag:
```bash
xattr -cr /Applications/McWritely.app
```

### Apple Silicon Build
The `package.sh` script builds the app for **Apple Silicon** (M1, M2, M3, M4) Macs. Intel-based Macs are not supported by the default build script.

## ⚙️ Customization

If you want to customize McWritely's behavior, you can modify the following in `Sources/McWritely/OpenAIService.swift`:

### Change the Model
Update the `model` property (default: `gpt-4o-mini`):
```swift
private let model: String = "gpt-4o"
```

### Custom Instructions
Current prompt:
```swift
let systemPrompt = """
You are an elite writing assistant. Correct the following text for grammar, spelling, style, and tone. 
Preserve the original meaning and formatting. 
If the text is already perfect, return it exactly as is. 
Only return the corrected text, no explanations.
"""
```

You can modify the `systemPrompt` variable to change how the AI refines your text (e.g., to focus on a specific tone or language):
```swift
let systemPrompt = """
You are a creative writing assistant. 
Focus on making the text more descriptive and evocative.
"""
```

## ⚙️ Technical Details

- **ML Backend**: Powered by OpenAI (`gpt-4o-mini`).
- **Hotkey**: `Cmd + Opt + Shift + G` (Global).
- **Efficiency**: Written in Swift for minimal memory footprint.

## 💰 Costs

Using `gpt-4o-mini`, the cost is extremely low:
- 100,000 words ≈ $0.50
- 1,000,000 words ≈ $5.00

## 📄 License

This project is licensed under [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/).

- **As is**: Shipped "as is" without warranty.
- **Modifications**: All modifications are allowed.
- **Commercial**: Commercial usage is **not allowed**.
