# Writely

Writely is a lightweight macOS menu bar utility that provides AI-powered writing assistance in any application.

## How it works
1. **Selection**: Select text in any app (Slack, Email, Browser, etc.).
2. **Review**: Click the Writely icon in your Menu Bar.
3. **Correct**: Writely sends the text to OpenAI (`gpt-4o-mini`).
4. **Apply**: Review the suggestion and click "Apply" to replace your selection automatically.

## Setup
1. **API Key**: Run the app, go to **Settings**, and enter your OpenAI API Key.
2. **Permissions**: Go to **System Settings > Privacy & Security > Accessibility** and add/enable Writely. 
   - You can also click "Request Access" in the Writely Settings window.

## Building from source
Run the included build script:
```bash
chmod +x build.sh
./build.sh
```

## Running
After building, run the binary:
```bash
.build/release/Writely
```
## To clear the app from the menu bar
```bash
cp -R /Users/antonkulikov/Projects/writely/Writely.app /Applications/
```

## Costs
Using `gpt-4o-mini`, the cost is extremely low.
- 100,000 words ~ $0.50
- 1,000,000 words ~ $5.00
Your budget of $144/year is more than enough for professional-level daily use.

