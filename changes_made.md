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
- **`GeminiActOnWebAllowedForURLs = ["*", "https://*", "https://*.youtube.com/*", "https://youtube.com/*"]`**: Allows Auto Browse to work across all websites.

---

## 5. Policy Control Exemption Engine (Reverse Engineering Breakthrough)

In Chrome versions with Glic Actor, internal policy verification is handled by `GlicActorPolicyChecker::ComputeActOnWebCapability`. By default, Chrome checks if the signed-in Google account has active Chrome benefits (`AccountHasChromeBenefits` / `kAccountMissingChromeBenefits`), which normally restricts Auto Browse actuation to users with an active **Google One AI Premium** subscription.

However, auditing the Chromium actor policy checker source reveals an intentional developer exemption switch:
```cpp
if (features::kGlicActorPolicyControlExemption.Get()) {
    return log_and_return(CanActOutcome::kYes, "exempted via cmdline `glic_actor_policy_control_exemption`");
}
```

By enabling the feature parameter `GlicActor:glic_actor_policy_control_exemption/true`, Chrome completely bypasses the subscription check, granting full agentic web actuation to all accounts.

---

## 6. Runtime Safety Checks Bypass

Chrome enforces secondary page safety checks via `actor::switches::kDisableActorSafetyChecks`:
- Passing `--disable-actor-safety-checks` overrides SafeBrowsing restrictions and internal action blocklists that might otherwise prevent Gemini from clicking, typing, or submitting on complex web applications.

---

## 7. Built-in On-Device AI Suite & WebNN

In addition to cloud-assisted Glic Actor, this toolkit activates the entire browser-resident on-device AI ecosystem:
- **Prompt API (`window.LanguageModel`)**: Direct access to Gemini Nano on device.
- **Language Detection API (`window.LanguageDetector`)**: Fast, offline language classification.
- **Summarization, Writer, and Rewriter APIs**: On-device drafting and summarization.
- **WebNN (`navigator.ml`)**: Hardware-accelerated ML graph execution (using Apple CoreML backend on macOS Apple Silicon).
- **Sampling Fix**: Avoids `on-device-model-speculative-decoding@1` which previously forced sampling mode to `most-predictable`.

---

## 8. Smart Launcher Architecture

The generated `Chrome AI.app` and `chrome-ai` launcher wrappers implement channel intelligence:
- Automatically detects and prioritizes **Google Chrome Dev** (or Canary) on macOS/Linux where Glic UI elements and toolbar pill views (`✨ Ask Gemini`) are compiled.
- Avoids passing `--remote-debugging-port` to the default user profile, preventing profile startup lockouts introduced in modern Chrome releases.
- Auto-locates the local `OptGuideOnDeviceModel` directory to ensure immediate model execution without waiting for background downloads.

---

## 9. Verified Autonomous Actuation Benchmark

The effectiveness of this configuration was verified end-to-end on YouTube:
- **Prompt:** `"In YouTube, create a 90s music playlist"`
- **Auto Browse Plan:** Gemini formulated: *"Create a new playlist for 90s music on YouTube."*
- **Execution:** Gemini displayed *"Browsing for you: Opening create menu on YouTube"*, actuated the page with its on-screen Magic Cursor, navigated to the playlist dialog, input the title, set private visibility, and submitted the form.
- **Result:** Confirmed live in YouTube Library (`youtube.com/playlist?list=PLfEIYzVgblVc`).

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
