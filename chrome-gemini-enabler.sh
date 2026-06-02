#!/bin/bash

# Interactive Gemini and Auto Browse Enabler & Reverter for Google Chrome
# Patches or restores Chrome configurations to manage Glic (Gemini) and Auto Browse features
# Supports: macOS, Linux

set -e

# Hide/Restore cursor helpers
hide_cursor() { tput civis; }
show_cursor() { tput cnorm; }
trap 'show_cursor; exit 1' INT TERM

# Check if python3 is installed
if ! command -v python3 >/dev/null 2>&1; then
    echo "❌ python3 is required to edit Chrome's JSON configurations safely, but it is not installed."
    exit 1
fi

echo ""
echo "🚀 Gemini & Auto Browse Chrome Toolkit"
echo "======================================="
echo ""

# Detect OS
OS_TYPE=$(uname -s)

# Setup array of known Chrome channels
CHANNELS_NAME=()
CHANNELS_CONFIG=()
CHANNELS_PLIST=()
CHANNELS_PROCESS=()

add_channel() {
    local name="$1"
    local config_path="$2"
    local plist_domain="$3"
    local process_name="$4"
    
    # Expand tilde ~ manually to avoid path expansion issues
    config_path="${config_path/#\~/$HOME}"
    
    if [ -f "$config_path" ]; then
        CHANNELS_NAME+=("$name")
        CHANNELS_CONFIG+=("$config_path")
        CHANNELS_PLIST+=("$plist_domain")
        CHANNELS_PROCESS+=("$process_name")
    fi
}

# Add system-specific channels
if [[ "$OS_TYPE" == "Darwin" ]]; then
    add_channel "Google Chrome (Stable)" "~/Library/Application Support/Google/Chrome/Local State" "com.google.Chrome" "Google Chrome"
    add_channel "Google Chrome Dev" "~/Library/Application Support/Google/Chrome Dev/Local State" "com.google.Chrome.dev" "Google Chrome Dev"
    add_channel "Google Chrome Beta" "~/Library/Application Support/Google/Chrome Beta/Local State" "com.google.Chrome.beta" "Google Chrome Beta"
    add_channel "Google Chrome Canary" "~/Library/Application Support/Google/Chrome Canary/Local State" "com.google.Chrome.canary" "Google Chrome Canary"
elif [[ "$OS_TYPE" == "Linux" ]]; then
    add_channel "Google Chrome (Stable)" "~/.config/google-chrome/Local State" "" "chrome"
    add_channel "Google Chrome Beta" "~/.config/google-chrome-beta/Local State" "" "google-chrome-beta"
    add_channel "Google Chrome Dev (Unstable)" "~/.config/google-chrome-unstable/Local State" "" "google-chrome-unstable"
else
    echo "❌ Unsupported OS: $OS_TYPE"
    exit 1
fi

# If no Chrome versions detected
if [ ${#CHANNELS_NAME[@]} -eq 0 ]; then
    echo "❌ No installed Google Chrome configuration files found on this machine."
    exit 1
fi

# Check for running Chrome processes
running_channels=()
for ((i=0; i<${#CHANNELS_NAME[@]}; i++)); do
    proc="${CHANNELS_PROCESS[i]}"
    if pgrep -x "$proc" > /dev/null 2>&1; then
        running_channels+=("${CHANNELS_NAME[i]} ($proc)")
    fi
done

if [ ${#running_channels[@]} -gt 0 ]; then
    echo "⚠️  The following Chrome browsers are currently running:"
    for rc in "${running_channels[@]}"; do
        echo "   - $rc"
    done
    echo ""
    read -p "Do you want to continue? This will automatically FORCE CLOSE them. (y/n): " -n 1 -r < /dev/tty
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborted by user."
        exit 1
    fi
    
    echo "Closing running Chrome instances..."
    for ((i=0; i<${#CHANNELS_NAME[@]}; i++)); do
        proc="${CHANNELS_PROCESS[i]}"
        if pgrep -x "$proc" > /dev/null 2>&1; then
            pkill -x "$proc" || killall "$proc" || true
        fi
    done
    sleep 1 # Wait a bit for file handles to be released
    echo "✓ Running processes closed."
    echo ""
fi

# Helper function to create a backup
create_backup() {
    local name="$1"
    local config_file="$2"
    local plist_domain="$3"
    local target_dir="$4"
    
    local parent_dir=$(dirname "$config_file")
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local sanitize_name=$(echo "$name" | sed 's/[^a-zA-Z0-9]/_/g')
    local backup_folder="$target_dir/chrome_backup_${sanitize_name}_${timestamp}"
    
    echo "💾 Creating backup of $name configurations..."
    mkdir -p "$backup_folder"
    
    # Copy Local State
    cp "$config_file" "$backup_folder/Local_State"
    
    # Copy Profile Preferences
    local pref_files=($(find "$parent_dir" -maxdepth 2 -name "Preferences"))
    local profiles_json="[]"
    for pref_file in "${pref_files[@]}"; do
        local profile_name=$(basename "$(dirname "$pref_file")")
        cp "$pref_file" "$backup_folder/Preferences_$profile_name"
        
        # Append to metadata JSON list
        profiles_json=$(python3 -c "import json; p = json.loads('$profiles_json'); p.append({'name': '$profile_name', 'path': '$pref_file'}); print(json.dumps(p))")
    done
    
    # Back up macOS plist defaults
    if [[ "$OS_TYPE" == "Darwin" ]] && [ -n "$plist_domain" ]; then
        defaults read "$plist_domain" > "$backup_folder/defaults.plist" 2>/dev/null || true
    fi
    
    # Save metadata JSON file
    python3 - <<EOF
import json
meta = {
    "channel_name": "$name",
    "local_state_path": "$config_file",
    "plist_domain": "$plist_domain",
    "profiles": $profiles_json
}
with open("$backup_folder/backup_meta.json", "w") as f:
    json.dump(meta, f, indent=4)
EOF

    echo "   ✓ Backup successfully saved to: $backup_folder"
}

# Helper function to revert from a backup folder
revert_backup() {
    local backup_folder="$1"
    
    # Resolve tilde
    backup_folder="${backup_folder/#\~/$HOME}"
    
    if [ ! -d "$backup_folder" ] || [ ! -f "$backup_folder/backup_meta.json" ]; then
        echo "❌ Invalid backup folder path. Could not find backup_meta.json inside '$backup_folder'."
        exit 1
    fi
    
    echo "🔄 Restoring configuration from backup directory: $backup_folder"
    
    local local_state_path=$(python3 -c "import json; print(json.load(open('$backup_folder/backup_meta.json'))['local_state_path'])")
    local plist_domain=$(python3 -c "import json; print(json.load(open('$backup_folder/backup_meta.json'))['plist_domain'])")
    
    # Restore Local State
    if [ -f "$backup_folder/Local_State" ]; then
        cp "$backup_folder/Local_State" "$local_state_path"
        echo "   ✓ Restored Local State file to: $local_state_path"
    fi
    
    # Restore Profile Preferences
    python3 - <<EOF
import json
import shutil
import os

meta = json.load(open("$backup_folder/backup_meta.json"))
for profile in meta.get("profiles", []):
    name = profile["name"]
    path = profile["path"]
    backup_file = os.path.join("$backup_folder", f"Preferences_{name}")
    if os.path.exists(backup_file):
        shutil.copy2(backup_file, path)
        print(f"   ✓ Restored Preferences for profile '{name}' to: {path}")
EOF

    # Restore macOS policies
    if [[ "$OS_TYPE" == "Darwin" ]] && [ -n "$plist_domain" ]; then
        # Delete policies to clean them up
        defaults delete "$plist_domain" GeminiActOnWebSettings >/dev/null 2>&1 || true
        defaults delete "$plist_domain" GeminiSettings >/dev/null 2>&1 || true
        defaults delete "$plist_domain" GenAiDefaultSettings >/dev/null 2>&1 || true
        defaults delete "$plist_domain" GeminiActOnWebAllowedForURLs >/dev/null 2>&1 || true
        
        if [ -f "$backup_folder/defaults.plist" ]; then
            defaults write "$plist_domain" "$(cat "$backup_folder/defaults.plist")" 2>/dev/null || true
            echo "   ✓ Restored original macOS enterprise policies for domain: $plist_domain"
        else
            echo "   ✓ Cleaned up custom enterprise policies for defaults domain: $plist_domain"
        fi
    fi
    
    echo ""
    echo "🎉 Revert process complete! Please restart your browser."
}

# Display multi-select menu
multiselect() {
    local title="$1"
    local -n _options="$2"
    local -n _selected="$3"
    
    local current=0
    local size=${#_options[@]}
    
    hide_cursor
    
    while true; do
        echo -e "\033[1m$title\033[0m"
        echo "Use Up/Down Arrow keys to navigate, Space to select/deselect, Enter to confirm."
        echo ""
        
        for ((i=0; i<size; i++)); do
            local marker="[ ]"
            if [ "${_selected[i]}" = "true" ]; then
                marker="[\033[1;32m✓\033[0m]"
            fi
            
            if [ $i -eq $current ]; then
                echo -e " \033[1;36m>\033[0m $marker ${_options[i]}"
            else
                echo -e "   $marker ${_options[i]}"
            fi
        done
        
        # Read key
        IFS= read -rsn1 key < /dev/tty
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 -t 0.1 key < /dev/tty
            case $key in
                '[A') # Up arrow
                    current=$(( (current - 1 + size) % size ))
                    ;;
                '[B') # Down arrow
                    current=$(( (current + 1) % size ))
                    ;;
            esac
        elif [[ $key == "" ]]; then # Enter key
            break
        elif [[ $key == " " ]]; then # Space key
            if [ "${_selected[current]}" = "true" ]; then
                _selected[current]="false"
            else
                _selected[current]="true"
            fi
        fi
        
        # Move cursor up to overwrite menu in-place
        local lines_to_move=$((size + 3))
        for ((l=0; l<lines_to_move; l++)); do
            echo -ne "\033[1A\033[2K"
        done
    done
    
    show_cursor
}

# Ask user for Apply vs Revert Action
echo "Please choose an action:"
echo "  [1] Apply Gemini & Auto Browse configurations"
echo "  [2] Revert browser settings to a previous backup"
echo ""
read -p "Select option (1 or 2): " -n 1 -r action < /dev/tty
echo ""

if [[ "$action" == "2" ]]; then
    echo "=== Revert Configuration ==="
    read -p "Enter the directory path of the backup folder to restore: " -r backup_input < /dev/tty
    echo ""
    revert_backup "$backup_input"
    exit 0
fi

if [[ "$action" != "1" ]]; then
    echo "❌ Invalid action selected. Exiting."
    exit 1
fi

# Ask if user wants to backup
read -p "Create a backup of current settings before modifying? (y/N): " -n 1 -r backup_agree < /dev/tty
echo ""

do_backup="false"
backup_dest=""
if [[ "$backup_agree" =~ ^[Yy]$ ]]; then
    do_backup="true"
    read -p "Enter directory path to save backup [default: ~/]: " -r backup_dest < /dev/tty
    backup_dest="${backup_dest:-$HOME}"
    backup_dest="${backup_dest/#\~/$HOME}"
    echo ""
fi

# Initialize select status
selected_options=()
for ((i=0; i<${#CHANNELS_NAME[@]}; i++)); do
    selected_options+=("false")
done

# Run interactive checklist
multiselect "Select Chrome installations to fix:" CHANNELS_NAME selected_options

# Clear the checklist view from screen to keep output clean
local lines_to_clear=$(( ${#CHANNELS_NAME[@]} + 3 ))
for ((l=0; l<lines_to_clear; l++)); do
    echo -ne "\033[1A\033[2K"
done

# Count selection
selected_count=0
for val in "${selected_options[@]}"; do
    if [ "$val" = "true" ]; then
        ((selected_count++))
    fi
done

if [ $selected_count -eq 0 ]; then
    echo "⚠️  No Chrome installations selected. Exiting."
    exit 0
fi

# Function to patch config files
patch_chrome_config() {
    local name="$1"
    local config_file="$2"
    local plist_domain="$3"
    local parent_dir=$(dirname "$config_file")
    
    echo "🔧 Fixing configuration for: $name"
    
    python3 - <<EOF
import json

path = "$config_file"
with open(path, "r") as f:
    d = json.load(f)

# Update location/variations
d["variations_country"] = "us"
if "variations_permanent_consistency_country" in d:
    if isinstance(d["variations_permanent_consistency_country"], list):
        if len(d["variations_permanent_consistency_country"]) > 0:
            d["variations_permanent_consistency_country"][-1] = "us"
        else:
            d["variations_permanent_consistency_country"] = ["us"]
else:
    d["variations_permanent_consistency_country"] = ["us"]

# Update enabled labs experiments
if "browser" not in d:
    d["browser"] = {}
experiments = d["browser"].get("enabled_labs_experiments", [])
if not isinstance(experiments, list):
    experiments = []

glic_flags = [
    'ai-mode-omnibox-entry-point@1',
    'aim-entry-point-direct-navigation@1',
    'aim-server-eligibility-include-client-locale@1',
    'aim-server-eligibility@1',
    'aim-use-pec-api@1',
    'autofill-ai-server-model@1',
    'autofill-enable-ai-based-amount-extraction@1',
    'browsing-history-actor-integration-M2@1',
    'browsing-history-actor-integration-M3@1',
    'contextual-tasks-context-library@1',
    'devtools-webmcp-support@1',
    'enable-webmcp-testing@1',
    'glic-actor-autofill@1',
    'glic-actor-cursor@1',
    'glic-actor-script-tools@1',
    'glic-actor@1',
    'glic-bind-pinned-unbound-tab@1',
    'glic-button-auto-summarize@1',
    'glic-button-pressed-state@1',
    'glic-capture-region@1',
    'glic-chrome-status-icon@1',
    'glic-client-zoom-control@1',
    'glic-contextual-cue-bubble@1',
    'glic-daisy-chain-new-tabs@1',
    'glic-default-tab-context-setting@1',
    'glic-default-to-last-active-conversation@1',
    'glic-detached@1',
    'glic-entrypoint-variations@1',
    'glic-experimental-triggering@1',
    'glic-horizontal-tab-toolbar-button@1',
    'glic-mi-tab-context-menu@1',
    'glic-pre-warming@2',
    'glic-print-menu-item@1',
    'glic-selection-prompt@1',
    'glic-share-image@1',
    'glic-tab-restoration@1',
    'glic-toolbar-button-location@1',
    'glic-toolbar-height-side-panel@1',
    'glic-trust-first-onboarding@3',
    'glic@1',
    'optimization-guide-on-device-model@2',
    'prompt-api-for-gemini-nano-multimodal-input@1',
    'prompt-api-for-gemini-nano@1',
    'proofreader-api-for-gemini-nano@1',
    'rewriter-api-for-gemini-nano@1',
    'summarizer-api-for-gemini-nano@1',
    'skills@1',
    'sync-ai-threads@1',
    'sync-gemini-threads@1',
    'writer-api-for-gemini-nano@1'
]

for flag in glic_flags:
    if flag not in experiments:
        experiments.append(flag)

d["browser"]["enabled_labs_experiments"] = experiments

# Enforce glic launcher
if "glic" not in d:
    d["glic"] = {}
d["glic"]["launcher_enabled"] = True

with open(path, "w") as f:
    json.dump(d, f)
EOF
    echo "   ✓ Enabled 40+ Glic/AI flags & US variation parameters in Local State"
    
    # 2. Edit Profile Preferences files (Default, Profile 1, etc.)
    local pref_files=($(find "$parent_dir" -maxdepth 2 -name "Preferences"))
    for pref_file in "${pref_files[@]}"; do
        local profile_name=$(basename "$(dirname "$pref_file")")
        
        python3 - <<EOF
import json

pref_path = "$pref_file"
with open(pref_path, "r") as f:
    pref_data = json.load(f)

# Update glic preferences
pref_data["glic"] = {
    "completed_fre": 1,
    "geolocation_enabled": True
}

# Update optimization guide registered types
if "optimization_guide" not in pref_data:
    pref_data["optimization_guide"] = {}
if "previously_registered_optimization_types" not in pref_data["optimization_guide"]:
    pref_data["optimization_guide"]["previously_registered_optimization_types"] = {}

pref_data["optimization_guide"]["previously_registered_optimization_types"]["GLIC_ACTION_PAGE_BLOCK"] = True
pref_data["optimization_guide"]["previously_registered_optimization_types"]["GLIC_CONTEXTUAL_CUEING"] = True
pref_data["optimization_guide"]["previously_registered_optimization_types"]["GLIC_ZERO_STATE_SUGGESTIONS"] = True

with open(pref_path, "w") as f:
    json.dump(pref_data, f)
EOF
        echo "   ✓ Patched Preferences for profile: $profile_name"
    done
    
    # 3. macOS Specific Policies via defaults command
    if [[ "$OS_TYPE" == "Darwin" ]] && [ -n "$plist_domain" ]; then
        echo "   ✓ Writing enterprise policies to macOS defaults domain: $plist_domain"
        defaults write "$plist_domain" GeminiActOnWebSettings -int 0
        defaults write "$plist_domain" GeminiSettings -int 0
        defaults write "$plist_domain" GenAiDefaultSettings -int 0
        defaults write "$plist_domain" GeminiActOnWebAllowedForURLs -array "*"
    fi
    
    echo "   🎉 Fix complete for $name!"
    echo ""
}

# Loop and run backup/fix on selections
for ((i=0; i<${#CHANNELS_NAME[@]}; i++)); do
    if [ "${selected_options[i]}" = "true" ]; then
        if [ "$do_backup" = "true" ]; then
            create_backup "${CHANNELS_NAME[i]}" "${CHANNELS_CONFIG[i]}" "${CHANNELS_PLIST[i]}" "$backup_dest"
        fi
        patch_chrome_config "${CHANNELS_NAME[i]}" "${CHANNELS_CONFIG[i]}" "${CHANNELS_PLIST[i]}"
    fi
done

echo "✅ All selected Chrome browser configurations have been successfully updated!"
echo "📌 Please restart your browser to apply changes."
echo ""
