# Writely

Writely is a lightweight macOS utility that provides AI-powered writing assistance in any application. It captures your selected text, refines it using OpenAI, and lets you replace the original text with a much better version instantly.

## 🚀 How it works

1.  **Select**: Highlight text in any app (Slack, Browser, Mail, etc.).
2.  **Trigger**: Press **`Cmd + Opt + Shift + G`**.
3.  **Refine**: Writely captures the selection and shows a floating panel with an improved version.
4.  **Applied**: Click **"Apply"** to replace the original text with the AI suggestion.

## 🛠 Setup

1.  **API Key**: Open Writely, go to **Settings** (click the menu bar icon or press `Cmd + ,`), and enter your OpenAI API Key.
2.  **Permissions**: Writely requires **Accessibility** permissions to capture and replace text in other apps.
    - Go to **System Settings > Privacy & Security > Accessibility**.
    - Add and enable **Writely**.
    - You can also initiate this from the Writely Settings window.

## 📦 Installation & Distribution

You can build the app from source or create a portable DMG package.

### Build Locally
```bash
./build.sh
```
This creates `Writely.app` in the root directory.

### Create a DMG
```bash
./package.sh
```
This generates `Writely.dmg` for easy distribution and installation.

## ⚙️ Technical Details

- **ML Backend**: Powered by OpenAI (`gpt-4o-mini`).
- **Hotkey**: `Cmd + Opt + Shift + G` (Global).
- **Efficiency**: Written in Swift for minimal memory footprint.

## 💰 Costs

Using `gpt-4o-mini`, the cost is extremely low:
- 100,000 words ≈ $0.50
- 1,000,000 words ≈ $5.00
Your budget of $144/year is more than enough for heavy professional use.

