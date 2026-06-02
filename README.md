# Chrome Gemini Enabler

An interactive, user-friendly shell script to enable Google Gemini (Glic) and **Auto Browse** ("Act on Web") agentic automation features in Google Chrome (Stable, Dev, Beta, Canary) on macOS and Linux for users outside of the United States.

---

## Features

- **Running Instance Detection**: Automatically checks for running Chrome processes and prompts for confirmation to force-close them before modifying configuration files.
- **Auto-Detection**: Scans your system to detect which Chrome installations (Stable, Dev, Beta, Canary) are present.
- **Interactive Terminal UI Checklist**: Presents a clean TUI checklist (supporting up/down arrow keys, Spacebar to toggle selection, and Enter to confirm) to select which installations to patch.
- **Profile Traversal**: Recursively scans and patches configurations for all user profiles (Default, Profile 1, Profile 2, etc.) under the selected installation paths.
- **Safe JSON Editing**: Uses Python (`python3`) to modify JSON configuration files safely without corrupting format or syntax.
- **macOS Enterprise Policies**: Automatically configures the defaults domain plists on macOS to allow the agentic Auto Browse features to act on web pages.

---

## How It Works

For detailed information on the exact files and fields modified (variations, flags, preferences, policies), see [changes_made.md](changes_made.md).

---

## Installation & Usage

1. **Clone the repository:**
   ```bash
   git clone https://github.com/fjrtdk/chrome-gemini-enabler.git
   cd chrome-gemini-enabler
   ```

2. **Make the script executable:**
   ```bash
   chmod +x chrome-gemini-enabler.sh
   ```

3. **Run the script:**
   ```bash
   ./chrome-gemini-enabler.sh
   ```

---

## Disclaimer

Modifying browser configuration files is an advanced procedure that can lead to configuration errors or browser instability. The script creates backups of your configuration files (e.g., `Local State.bak`, `Preferences.bak`) before modifying them. **Use at your own risk.**

Google Sync can occasionally overwrite local configurations; pausing sync or temporarily signing out of your Google account may be required if changes do not persist.
