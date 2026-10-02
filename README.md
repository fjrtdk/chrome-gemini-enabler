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

*Normally restricted to U.S. Google accounts with specific Google One AI Premium subscriptions, this toolkit activates the necessary configurations locally and exposes the built-in policy control exemption parameter (`glic_actor_policy_control_exemption`), completely unlocking Auto Browse actuation on any account.*

---

## ⚡ Key Features

- 🔍 **System Auto-Discovery**: Instantly scans your machine for installed Chrome versions (Stable, Dev, Beta, Canary).
- 🎨 **Interactive TUI**: A beautiful terminal checklist menu. Navigate with Arrow keys, toggle with the **Spacebar**, and confirm with **Enter**.
- 🔒 **Process Guard**: Automatically detects active Chrome processes and prompts for confirmation to safely force-close them (preventing configuration lockups).
- 📂 **Multi-Profile Deep Patching**: Traverses all user profile folders (e.g., `Default`, `Profile 1`, `Profile 2`) to configure settings.
- 🛡️ **Google One AI Premium Bypass**: Unlocks the hidden `glic_actor_policy_control_exemption` feature switch and `--disable-actor-safety-checks` command-line flags.
- 🖥️ **Chrome AI Launcher**: Automatically generates a dedicated macOS app (`Chrome AI.app`) and CLI wrapper (`chrome-ai`) pre-configured with all required runtime flags.
- 🛡️ **Enterprise Policies**: Modifies enterprise policies on macOS (`GeminiActOnWebSettings = 0`, `GeminiActOnWebAllowedForURLs = ["*"]`) allowing automation to act on web pages.
- 🛡️ **Non-Destructive Patching**: Safely parses and edits the JSON using Python—never corrupting your file formatting. It also creates a full backup before modifying files.

---

## ⚙️ How It Works (Under the Hood)

The script patches the internal browser configurations by adjusting five layers:
1. **Local State Variations**: Overrides `variations_country` to `"us"` to bypass regional geo-blocking.
2. **Experimental Flags**: Injects **60+ flags** into the `enabled_labs_experiments` list (including `glic-actor`, `glic-actor-ui-magic-cursor`, `devtools-webmcp-support`, and `glic-web-actuation-setting`).
3. **Onboarding Skip**: Updates profile preferences with `glic: { completed_fre: 1, geolocation_enabled: true }` to skip the First Run introduction.
4. **Policy Control Exemption**: Chrome's `GlicActorPolicyChecker::ComputeActOnWebCapability` blocks non-subscribers with `kAccountMissingChromeBenefits`. We bypass this check directly via `--enable-features=GlicActor:glic_actor_policy_control_exemption/true`.
5. **Mac Plist Policies**: Deploys native system-level policies to authorize Gemini to operate on all URLs (`GeminiActOnWebAllowedForURLs`).

For a full technical breakdown, check out [changes_made.md](changes_made.md).

---

## 🚀 Quick Start

Ready to supercharge your Chrome browser?

### 🍎 macOS & 🐧 Linux

Run the activator directly without cloning:

```bash
curl -fsSL https://raw.githubusercontent.com/fjrtdk/chrome-gemini-enabler/main/chrome-gemini-enabler.sh | bash
```

Alternatively, you can clone and run it locally:

```bash
# 1. Clone the repository
git clone https://github.com/fjrtdk/chrome-gemini-enabler.git
cd chrome-gemini-enabler

# 2. Make the script executable
chmod +x chrome-gemini-enabler.sh

# 3. Run the activator
./chrome-gemini-enabler.sh
```

### 🎯 Launching Chrome with Full AI Actuation

Once patched, launch Chrome using the generated launcher:
- **macOS**: Launch **`Chrome AI.app`** from `~/Applications` or terminal: `~/.local/bin/chrome-ai`
- **Linux**: Run `~/.local/bin/chrome-ai`

### 🪟 Windows (PowerShell)

> [!WARNING]
> The Windows / PowerShell version of this script is **still untested**. Please proceed with caution and ensure you have backups (the script automatically creates `.bak` files before modification).

Run the activator directly in PowerShell:

```powershell
irm https://raw.githubusercontent.com/fjrtdk/chrome-gemini-enabler/main/chrome-gemini-enabler.ps1 | iex
```

---

## ⚠️ Disclaimer

Editing Chrome configuration files is an advanced procedure. Although this script creates automatic backups (`.bak` files), please proceed with caution. **Use at your own risk.**

*Note: Google Sync can sometimes sync account settings from the cloud and revert your local changes. If features disappear, simply pause Sync or run the script again.*
