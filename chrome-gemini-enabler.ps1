# Windows Gemini & Auto Browse Chrome Toolkit
# Patches or restores Chrome configurations to manage Glic (Gemini) and Auto Browse features on Windows

Write-Host ""
Write-Host "⚠️  WARNING: The Windows/PowerShell version of this script is still UNTESTED." -ForegroundColor Red
Write-Host "⚠️  Please proceed with caution." -ForegroundColor Red
Write-Host ""

# Setup known Chrome channels on Windows
$userProfile = [System.Environment]::GetFolderPath('UserProfile')
$channelsData = @(
    @{ Name = "Google Chrome (Stable)"; Path = "$userProfile\AppData\Local\Google\Chrome\User Data\Local State"; Process = "chrome" },
    @{ Name = "Google Chrome Dev"; Path = "$userProfile\AppData\Local\Google\Chrome Dev\User Data\Local State"; Process = "chrome" },
    @{ Name = "Google Chrome Beta"; Path = "$userProfile\AppData\Local\Google\Chrome Beta\User Data\Local State"; Process = "chrome" },
    @{ Name = "Google Chrome Canary"; Path = "$userProfile\AppData\Local\Google\Chrome SxS\User Data\Local State"; Process = "chrome" }
)

# Detect installed channels
$installed = @()
foreach ($ch in $channelsData) {
    if (Test-Path $ch.Path) {
        $installed += $ch
    }
}

if ($installed.Count -eq 0) {
    Write-Error "❌ No installed Google Chrome configuration files found on this machine."
    exit
}

# Check for running Chrome processes
$running = Get-Process chrome -ErrorAction SilentlyContinue
if ($running) {
    Write-Host "⚠️  Chrome processes are currently running." -ForegroundColor Yellow
    $ans = Read-Host "Do you want to continue? This will automatically FORCE CLOSE them. (y/n)"
    if ($ans -notlike "y*") {
        Write-Host "❌ Aborted by user."
        exit
    }
    Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    Write-Host "✓ Running processes closed.`n"
}

# Helper function to create a backup
function Create-Backup {
    param(
        [string]$Name,
        [string]$ConfigPath,
        [string]$TargetDir
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $sanitizeName = $Name -replace '[^a-zA-Z0-9]', '_'
    $backupFolder = Join-Path $TargetDir "chrome_backup_${sanitizeName}_${timestamp}"
    
    Write-Host "💾 Creating backup of $Name configurations..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
    
    # Backup Local State
    Copy-Item $ConfigPath -Destination (Join-Path $backupFolder "Local_State") -Force
    
    # Backup Profile Preferences
    $parentDir = Split-Path $ConfigPath -Parent
    $preferencesFiles = Get-ChildItem -Path $parentDir -Filter "Preferences" -Recurse -Depth 2
    
    $profiles = @()
    foreach ($prefFile in $preferencesFiles) {
        $prefPath = $prefFile.FullName
        $profileName = Split-Path (Split-Path $prefPath -Parent) -Leaf
        
        Copy-Item $prefPath -Destination (Join-Path $backupFolder "Preferences_$profileName") -Force
        
        $profiles += @{
            name = $profileName
            path = $prefPath
        }
    }
    
    # Create metadata JSON
    $meta = @{
        channel_name = $Name
        local_state_path = $ConfigPath
        profiles = $profiles
    }
    
    $meta | ConvertTo-Json -Depth 10 | Out-File (Join-Path $backupFolder "backup_meta.json") -Encoding utf8
    
    Write-Host "   ✓ Backup successfully saved to: $backupFolder" -ForegroundColor Green
}

# Helper function to restore from a backup
function Revert-Backup {
    param(
        [string]$BackupFolder
    )
    
    if (-not (Test-Path $BackupFolder) -or -not (Test-Path (Join-Path $BackupFolder "backup_meta.json"))) {
        Write-Error "❌ Invalid backup folder path. Could not find backup_meta.json inside '$BackupFolder'."
        return
    }
    
    Write-Host "🔄 Restoring configuration from backup directory: $BackupFolder" -ForegroundColor Cyan
    
    $meta = Get-Content (Join-Path $BackupFolder "backup_meta.json") -Raw | ConvertFrom-Json
    $localStatePath = $meta.local_state_path
    
    # Restore Local State
    if (Test-Path (Join-Path $BackupFolder "Local_State")) {
        Copy-Item (Join-Path $BackupFolder "Local_State") -Destination $localStatePath -Force
        Write-Host "   ✓ Restored Local State file to: $localStatePath" -ForegroundColor Green
    }
    
    # Restore Profile Preferences
    foreach ($profile in $meta.profiles) {
        $name = $profile.name
        $path = $profile.path
        $backupFile = Join-Path $BackupFolder "Preferences_$name"
        if (Test-Path $backupFile) {
            Copy-Item $backupFile -Destination $path -Force
            Write-Host "   ✓ Restored Preferences for profile '$name' to: $path" -ForegroundColor Green
        }
    }
    
    Write-Host "`n🎉 Revert process complete! Please restart your browser." -ForegroundColor Green
}

# Ask user for Apply vs Revert Action
Write-Host "Please choose an action:"
Write-Host "  [1] Apply Gemini & Auto Browse configurations"
Write-Host "  [2] Revert browser settings to a previous backup"
Write-Host ""
$action = Read-Host "Select option (1 or 2)"
Write-Host ""

if ($action -eq "2") {
    Write-Host "=== Revert Configuration ==="
    $backupInput = Read-Host "Enter the directory path of the backup folder to restore"
    Write-Host ""
    Revert-Backup $backupInput
    exit
}

if ($action -ne "1") {
    Write-Error "❌ Invalid action selected. Exiting."
    exit
}

# Ask if user wants to backup
$backupAgree = Read-Host "Create a backup of current settings before modifying? (y/N)"
$doBackup = $false
$backupDest = ""
if ($backupAgree -like "y*") {
    $doBackup = $true
    $backupDest = Read-Host "Enter directory path to save backup [default: ~]"
    if ([string]::IsNullOrWhiteSpace($backupDest)) {
        $backupDest = $Home
    }
    # Resolve path
    $resolved = Resolve-Path $backupDest -ErrorAction SilentlyContinue
    if ($resolved) {
        $backupDest = $resolved.Path
    } else {
        $backupDest = $Home
    }
    Write-Host ""
}

# Prompt selection
Write-Host "=== Select Chrome installations to fix ==="
for ($i = 0; $i -lt $installed.Count; $i++) {
    Write-Host "[$($i + 1)] $($installed[$i].Name)"
}
Write-Host ""
$selection = Read-Host "Enter numbers separated by commas (e.g., 1, 2) or press Enter to select all"

$selected = @()
if ([string]::IsNullOrWhiteSpace($selection)) {
    $selected = $installed
} else {
    $indices = $selection -split ',' | ForEach-Object { [int]$_ - 1 }
    foreach ($idx in $indices) {
        if ($idx -ge 0 -and $idx -lt $installed.Count) {
            $selected += $installed[$idx]
        }
    }
}

if ($selected.Count -eq 0) {
    Write-Host "⚠️  No installations selected. Exiting."
    exit
}

# Patch selections
foreach ($ch in $selected) {
    # Perform backup if requested
    if ($doBackup) {
        Create-Backup $ch.Name $ch.Path $backupDest
    }
    
    Write-Host "🔧 Fixing configuration for: $($ch.Name)"
    $localStatePath = $ch.Path
    $jsonContent = Get-Content $localStatePath -Raw | ConvertFrom-Json
    
    $jsonContent.variations_country = "us"
    if ($jsonContent.variations_permanent_consistency_country -is [System.Array]) {
        $list = [System.Collections.Generic.List[string]]::new($jsonContent.variations_permanent_consistency_country)
        if ($list.Count -gt 0) {
            $list[$list.Count - 1] = "us"
        } else {
            $list.Add("us")
        }
        $jsonContent.variations_permanent_consistency_country = $list.ToArray()
    } else {
        $jsonContent.variations_permanent_consistency_country = @("us")
    }
    
    if (-not $jsonContent.browser) {
        $jsonContent | Add-Member -MemberType NoteProperty -Name browser -Value @{}
    }
    
    $experiments = @()
    if ($jsonContent.browser.enabled_labs_experiments) {
        $experiments = [System.Collections.Generic.List[string]]::new($jsonContent.browser.enabled_labs_experiments)
    }
    
    $glicFlags = @(
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
    )
    
    foreach ($flag in $glicFlags) {
        if ($experiments -notcontains $flag) {
            $experiments.Add($flag)
        }
    }
    
    if (-not (Get-Member -InputObject $jsonContent.browser -Name enabled_labs_experiments)) {
        $jsonContent.browser | Add-Member -MemberType NoteProperty -Name enabled_labs_experiments -Value $experiments.ToArray() -Force
    } else {
        $jsonContent.browser.enabled_labs_experiments = $experiments.ToArray()
    }
    
    if (-not $jsonContent.glic) {
        $jsonContent | Add-Member -MemberType NoteProperty -Name glic -Value @{}
    }
    if (-not (Get-Member -InputObject $jsonContent.glic -Name launcher_enabled)) {
        $jsonContent.glic | Add-Member -MemberType NoteProperty -Name launcher_enabled -Value $true -Force
    } else {
        $jsonContent.glic.launcher_enabled = $true
    }
    
    $jsonContent | ConvertTo-Json -Depth 100 | Out-File $localStatePath -Encoding utf8
    Write-Host "   ✓ Enabled 40+ Glic/AI flags & US variations in Local State"
    
    # Update Preferences files recursively
    $parentDir = Split-Path $localStatePath -Parent
    $preferencesFiles = Get-ChildItem -Path $parentDir -Filter "Preferences" -Recurse -Depth 2
    
    foreach ($prefFile in $preferencesFiles) {
        $prefPath = $prefFile.FullName
        $profileName = Split-Path (Split-Path $prefPath -Parent) -Leaf
        
        $prefJson = Get-Content $prefPath -Raw | ConvertFrom-Json
        
        if (-not $prefJson.glic) {
            $prefJson | Add-Member -MemberType NoteProperty -Name glic -Value @{}
        }
        if (-not (Get-Member -InputObject $prefJson.glic -Name completed_fre)) {
            $prefJson.glic | Add-Member -MemberType NoteProperty -Name completed_fre -Value 1 -Force
        } else {
            $prefJson.glic.completed_fre = 1
        }
        if (-not (Get-Member -InputObject $prefJson.glic -Name geolocation_enabled)) {
            $prefJson.glic | Add-Member -MemberType NoteProperty -Name geolocation_enabled -Value $true -Force
        } else {
            $prefJson.glic.geolocation_enabled = $true
        }
        
        if (-not $prefJson.optimization_guide) {
            $prefJson | Add-Member -MemberType NoteProperty -Name optimization_guide -Value @{}
        }
        if (-not $prefJson.optimization_guide.previously_registered_optimization_types) {
            $prefJson.optimization_guide | Add-Member -MemberType NoteProperty -Name previously_registered_optimization_types -Value @{}
        }
        
        $types = $prefJson.optimization_guide.previously_registered_optimization_types
        if (-not (Get-Member -InputObject $types -Name GLIC_ACTION_PAGE_BLOCK)) {
            $types | Add-Member -MemberType NoteProperty -Name GLIC_ACTION_PAGE_BLOCK -Value $true -Force
        } else {
            $types.GLIC_ACTION_PAGE_BLOCK = $true
        }
        if (-not (Get-Member -InputObject $types -Name GLIC_CONTEXTUAL_CUEING)) {
            $types | Add-Member -MemberType NoteProperty -Name GLIC_CONTEXTUAL_CUEING -Value $true -Force
        } else {
            $types.GLIC_CONTEXTUAL_CUEING = $true
        }
        if (-not (Get-Member -InputObject $types -Name GLIC_ZERO_STATE_SUGGESTIONS)) {
            $types | Add-Member -MemberType NoteProperty -Name GLIC_ZERO_STATE_SUGGESTIONS -Value $true -Force
        } else {
            $types.GLIC_ZERO_STATE_SUGGESTIONS = $true
        }
        
        $prefJson | ConvertTo-Json -Depth 100 | Out-File $prefPath -Encoding utf8
        Write-Host "   ✓ Patched Preferences for profile: $profileName"
    }
    Write-Host "   🎉 Fix complete for $($ch.Name)!"
    Write-Host ""
}

Write-Host "✅ All selected Chrome browser configurations have been successfully updated!"
Write-Host "📌 Please restart your browser to apply changes."
Write-Host ""
