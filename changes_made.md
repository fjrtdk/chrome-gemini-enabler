# Documentation of Chrome Configurations for Gemini and Auto Browse

This document details the modifications and configurations applied to Google Chrome (Stable, Dev, Beta, or Canary) to unlock the Gemini sidebar (Glic) and the **Auto Browse** ("Act on Web") agentic automation features for users outside of the United States.

---

## 1. Browser-Wide Variations (Local State)

Chrome gates experimental AI features based on the client's location and variations country. The script patches the browser-wide `Local State` configuration file.

### Key Overrides
- **`variations_country`**: Set to `"us"`. This bypasses regional locks for the client.
- **`variations_permanent_consistency_country`**: Updates the permanent variation country list to end with `"us"` (e.g., `["<chrome_version>", "us"]`).
- **`glic` block**: Injects `"glic": {"launcher_enabled": true}` at the root level to ensure the launcher/trigger button is enabled browser-wide.

---

## 2. Experimental Flags (enabled_labs_experiments)

Chrome uses internal experiments (labs) flags to toggle individual features. The script enables 74 distinct flags under the `browser.enabled_labs_experiments` key of the `Local State` file. These flags include:

| Flag Name | Function |
| :--- | :--- |
| `glic@1` | Enables the main Glic sidebar interface. |
| `glic-actor@1` | Activates the core agentic execution framework. |
| `glic-actor-autofill@1` | Permits the AI agent to autofill forms on web pages. |
| `glic-actor-cursor@1` | Allows the AI agent to interact with the page cursor. |
| `glic-actor-script-tools@1` | Grants the AI agent page script manipulation tools. |
| `enable-webmcp-testing@1` | Opens Chrome WebMCP support for programmatic automation. |
| `devtools-webmcp-support@1` | Connects WebMCP tools to the Chrome Developer tools. |
| `aim-server-eligibility@1` | Forces AI Mode (Gemini) server-side eligibility checks to succeed. |
| `aim-use-pec-api@1` | Enforces the use of permanent country consistency variations. |

---

## 3. Profile Preference Settings (Preferences)

Within each user profile folder (e.g., `Default`), Chrome checks preferences to skip onboarding screens and register capabilities.

### Key Preferences
- **`glic` configuration**:
  ```json
  "glic": {
      "completed_fre": 1,
      "geolocation_enabled": true
  }
  ```
  This marks the First Run Experience (FRE) as completed and enables the geolocation context required by Gemini.
- **`optimization_guide` registrations**: Marks `GLIC_ACTION_PAGE_BLOCK`, `GLIC_CONTEXTUAL_CUEING`, and `GLIC_ZERO_STATE_SUGGESTIONS` as previously registered to activate them in the profile.

---

## 4. Enterprise Policies (macOS defaults)

To prevent Chrome from restricting "Act on Web" (Auto Browse) actions, policies must explicitly authorize Gemini. On macOS, this is done by writing to the preference domain plist of the respective Chrome version:

- **`GeminiSettings = 0`**: Ensures the Gemini sidebar app is fully allowed.
- **`GeminiActOnWebSettings = 0`**: Explicitly permits Gemini to take actions (click, type, navigate) on web pages.
- **`GenAiDefaultSettings = 0`**: Sets the default for all generative AI integrations to "allowed."
- **`GeminiActOnWebAllowedForURLs = ["*"]`**: Allows Auto Browse to work across all websites.

---

## Configuration Paths Reference

### macOS
- **Google Chrome (Stable)**:
  - Local State: `~/Library/Application Support/Google/Chrome/Local State`
  - Preferences: `~/Library/Application Support/Google/Chrome/Default/Preferences`
  - Policy Domain: `com.google.Chrome`
- **Google Chrome Dev**:
  - Local State: `~/Library/Application Support/Google/Chrome Dev/Local State`
  - Preferences: `~/Library/Application Support/Google/Chrome Dev/Default/Preferences`
  - Policy Domain: `com.google.Chrome.dev`

### Linux
- **Google Chrome (Stable)**:
  - Local State: `~/.config/google-chrome/Local State`
  - Preferences: `~/.config/google-chrome/Default/Preferences`
- **Google Chrome Dev/Unstable**:
  - Local State: `~/.config/google-chrome-unstable/Local State`
  - Preferences: `~/.config/google-chrome-unstable/Default/Preferences`
