# ✨ Chrome Gemini & Auto Browse Enabler 🚀

[![Platform Support](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-blue?style=for-the-badge)](https://github.com/fjrtdk/chrome-gemini-enabler)
[![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)](https://choosealicense.com/licenses/mit/)
[![Chrome Compatibility](https://img.shields.io/badge/Chrome-Stable%20%7C%20Dev%20%7C%20Beta%20%7C%20Canary-orange?style=for-the-badge)](https://www.google.com/chrome/)

Unleash the hidden power of Google's next-gen AI companion! This script automatically unlocks **Gemini (Glic)** and the revolutionary **Auto Browse ("Act on Web")** AI agent in Google Chrome—instantly bypassing geographic restrictions and profile blocks with a single command.

---

## 🤖 What does this enable?

### 💬 Gemini (Glic) Sidebar
Bring the official, built-in Gemini side panel to your screen. Ask questions, summarize pages, draft emails, and get contextual help directly alongside your active webpage.

### 🌐 Auto Browse ("Act on Web")
Step into the future of web automation. Unlocking Auto Browse allows Gemini to act as a **web agent** that can:
- 📝 **Fill out forms** autonomously.
- 🛍️ **Search, find, and compare products** across multiple pages.
- 📅 **Schedule appointments** or look up flight options.
- 🖱️ **Take control of the viewport** to click, scroll, and navigate tabs on your behalf.

*Normally restricted to U.S. Google accounts with specific AI Premium subscriptions, this script activates the necessary configurations locally so you can start testing immediately.*

---

## ⚡ Key Features

- 🔍 **System Auto-Discovery**: Instantly scans your machine for installed Chrome versions (Stable, Dev, Beta, Canary).
- 🎨 **Interactive TUI**: A beautiful terminal checklist menu. Navigate with Arrow keys, toggle with the **Spacebar**, and confirm with **Enter**.
- 🔒 **Process Guard**: Automatically detects active Chrome processes and prompts for confirmation to safely force-close them (preventing configuration lockups).
- 📂 **Multi-Profile Deep Patching**: Traverses all user profile folders (e.g., `Default`, `Profile 1`, `Profile 2`) to configure settings.
- 🛡️ **macOS Enterprise Policies**: Modifies domain plists on macOS to write enterprise flags (`GeminiActOnWebSettings = 0`) allowing automation to act on web pages.
- 🛡️ **Non-Destructive Patching**: Safely parses and edits the JSON using Python—never corrupting your file formatting. It also creates a `.bak` backup of every file it touches!

---

## ⚙️ How It Works (Under the Hood)

The script patches the internal browser configurations by adjusting four layers:
1. **Local State Variations**: Overrides `variations_country` to `"us"` to bypass regional geo-blocking.
2. **Experimental Flags**: Injects **74+ flags** into the `enabled_labs_experiments` list (including `glic-actor`, `devtools-webmcp-support`, and `aim-server-eligibility`).
3. **Onboarding Skip**: Updates profile preferences with `glic: { completed_fre: 1, geolocation_enabled: true }` to skip the First Run introduction.
4. **Mac Plist Policies**: Deploys native system-level policies to authorize Gemini to operate on all URLs.

For a full technical breakdown, check out [changes_made.md](changes_made.md).

---

## 🚀 Quick Start

Ready to supercharge your Chrome browser? Run the following commands:

```bash
# 1. Clone the repository
git clone https://github.com/fjrtdk/chrome-gemini-enabler.git
cd chrome-gemini-enabler

# 2. Make the script executable
chmod +x chrome-gemini-enabler.sh

# 3. Run the activator
./chrome-gemini-enabler.sh
```

---

## ⚠️ Disclaimer

Editing Chrome configuration files is an advanced procedure. Although this script creates automatic backups (`.bak` files), please proceed with caution. **Use at your own risk.**

*Note: Google Sync can sometimes sync account settings from the cloud and revert your local changes. If features disappear, simply pause Sync or run the script again.*
