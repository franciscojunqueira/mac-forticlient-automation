# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

**VPN Monitor & Auto-Reconnect for FortiClient** - Automated monitoring and reconnection system for FortiClient Zero Trust Fabric Agent with MFA authentication. Achieves ~95% automation, leaving only manual MFA approval (mandatory for security).

This is a **bash-based automation system** that monitors VPN connections and automatically reconnects when disconnected, including automated UI interaction to click the "Connect" button.

## Key Architecture

### Core Components

1. **vpn-monitor-orizon.sh** (Main monitoring daemon)
   - Runs in background loop, checking VPN every 5 seconds
   - Uses dual verification: `scutil --nc status` + `ifconfig` checks
   - Saves user context (focused app bundle ID, mouse position including negative coordinates)
   - Orchestrates full reconnection workflow
   - Handles lock files to prevent multiple instances (`~/tmp/.vpn-monitor.lock`)

2. **auto-click-connect.sh** (UI automation component)
   - Dynamically detects FortiClient window position via AppleScript
   - Two modes for button detection:
     - **Auto-detection** (PRIVACY_MODE=false): Uses Python computer vision via `find-connect-button.py`
     - **Fixed coordinates** (PRIVACY_MODE=true): Uses calibrated offsets from `config.sh`
   - Restores user context: mouse position (via CoreGraphics for negative coords) + application focus
   - Multi-monitor support including negative coordinates (monitors above/left of primary)

3. **config.sh** (Central configuration)
   - PRIVACY_MODE toggle (false=screenshots with auto-detection, true=no screenshots with fixed coords)
   - BUTTON_OFFSET_X/Y for fixed coordinate mode
   - VPN_INTERFACE, CHECK_INTERVAL, AUTO_RECONNECT settings

### Multi-Monitor Support Architecture

The system handles complex multi-monitor setups including negative coordinates (monitors positioned above or to the left of the primary display):

- **Mouse position capture**: Uses `cliclick p` (returns negative coords correctly)
- **Mouse restoration**: Uses `osascript -l JavaScript` with CoreGraphics `CGWarpMouseCursorPosition` for negative coordinates (cliclick has issues with negatives)
- **Window position**: AppleScript `System Events` provides absolute coordinates
- **Button calculation**: Dynamic offset from window position (config-based or vision-detected)

### User Context Restoration

Three-stage restoration process ensures minimal user disruption:

1. **Context Capture**: Before any automation
   - Application bundle ID (more reliable than name)
   - Mouse X,Y coordinates (including negatives)

2. **Immediate Restoration**: 0.2s after clicking Connect
   - Mouse position restored via CoreGraphics

3. **Post-Modal Restoration**: After MFA modal appears (~2s)
   - Focus restored to original app via bundle ID
   - Final focus restoration after VPN reconnects and FortiClient closes

## Common Development Commands

### Installation & Setup
```bash
# Full automated installation (detects VPN UUID, installs dependencies, configures)
./install.sh

# Manual installation
mkdir -p ~/bin ~/tmp
cp scripts/vpn-monitor-orizon.sh ~/bin/
cp scripts/auto-click-connect.sh ~/GitHub/mac-Forticlient-automation/scripts/
chmod +x ~/bin/vpn-monitor-orizon.sh
chmod +x ~/GitHub/mac-Forticlient-automation/scripts/auto-click-connect.sh
```

### Monitor Management
```bash
# Start monitor
~/bin/vpn-monitor-orizon.sh > ~/tmp/vpn-monitor.log 2>&1 &

# Check if running
pgrep -lf vpn-monitor-orizon

# View logs in real-time
tail -f ~/tmp/vpn-monitor.log

# Stop monitor
pkill -f vpn-monitor-orizon
rm -f ~/tmp/.vpn-monitor.lock

# Restart monitor (easiest way)
~/GitHub/mac-Forticlient-automation/scripts/restart-monitor.sh
```

### Testing
```bash
# Manual disconnect test
scutil --nc stop "VPN"
# Then observe automatic reconnection flow

# Automated test with countdown (best for testing focus/mouse restoration)
~/GitHub/mac-Forticlient-automation/scripts/test-disconnect-with-countdown.sh

# Force disconnect for immediate testing
~/GitHub/mac-Forticlient-automation/scripts/force-disconnect-vpn.sh
```

### Configuration Discovery
```bash
# Find VPN UUID (needed for config)
scutil --nc list

# Check current VPN status
scutil --nc status "YOUR-VPN-UUID"

# Find VPN interface and IP
ifconfig | grep -A 3 utun

# Test voice alerts
say -v Luciana "teste em português"

# List available voices
say -v "?"

# Test cliclick (returns current mouse position)
cliclick p
```

### Calibration (for PRIVACY_MODE=true)
```bash
# If button clicks are missing, adjust offsets in config.sh
# Default: BUTTON_OFFSET_X=552, BUTTON_OFFSET_Y=525 (for 894x714 window)

# To recalibrate:
# 1. Open FortiClient manually
# 2. Run to get window dimensions:
osascript -e 'tell application "System Events" to tell process "FortiClient" to get size of window 1'

# 3. Manually click and use cliclick to record position:
cliclick p  # Click button, then immediately run this

# 4. Calculate offset: BUTTON_OFFSET_X = recorded_x - window_x
```

## Critical Technical Details

### macOS Permissions Required

**For PRIVACY_MODE=false (auto-detection):**
1. **Accessibility** - System Settings → Privacy & Security → Accessibility → Add terminal (Terminal.app/Warp)
2. **Screen Recording** - System Settings → Privacy & Security → Screen Recording → Add terminal

**For PRIVACY_MODE=true (no screenshots):**
1. **Accessibility** - Same as above
2. Screen Recording NOT required ✓

### Why Certain Design Choices

**Lock File Pattern** (`~/tmp/.vpn-monitor.lock`):
- Contains PID of running monitor
- Prevents multiple instances
- Cleaned up on EXIT/INT/TERM via trap
- Must be removed manually if process crashes

**Bundle ID vs App Name for Focus**:
- Bundle IDs are more reliable (unique, unchanging)
- App names can have localization issues
- Script tries bundle ID first, falls back to name

**CoreGraphics for Mouse Restoration**:
- cliclick has issues with negative coordinates
- JavaScript ObjC Bridge allows direct CoreGraphics API access
- `$.CGWarpMouseCursorPosition({x: -100, y: 200})` works with negatives

**Two-Stage Focus Restoration**:
- Immediate restoration fails because FortiClient MFA modal steals focus
- Wait 2s for modal to appear, then restore focus again
- Final restoration after VPN reconnects and FortiClient closes

**String "V P N" with Spaces in Voice Alerts**:
- macOS `say` command pronounces "VPN" incorrectly as one word
- Spacing forces letter-by-letter pronunciation: "V P N"
- Brazilian voice: `say -v Luciana`

### VPN Detection Logic

The monitor uses **dual verification** - both must pass for "connected" state:

1. **scutil check**: `scutil --nc status "$UUID"` must return "Connected"
2. **ifconfig check**: `ifconfig "$VPN_INTERFACE"` must show IP matching pattern (default: `inet 10\.`)

Adjust IP pattern in script line ~52 if your VPN uses different subnet (e.g., `172.16.*`, `192.168.*`)

### What Cannot Be Automated (By Design)

**MFA Approval**: The one manual step remaining. This is intentional and cannot be bypassed:
- Token is dynamically generated
- Requires physical presence (biometric)
- Push notification server→device
- Security protocol prevents automation

## Script Locations

- **Installed location**: `~/bin/vpn-monitor-orizon.sh` (main monitor)
- **Project scripts**: `~/GitHub/mac-Forticlient-automation/scripts/`
- **Logs**: `~/tmp/vpn-monitor.log`
- **Lock file**: `~/tmp/.vpn-monitor.lock`
- **Config**: `~/GitHub/mac-Forticlient-automation/config.sh`

## Dependencies

**Required**:
- macOS 14+ (tested)
- FortiClient Zero Trust Fabric Agent
- cliclick (`brew install cliclick`)
- Bash 5.x (default on modern macOS)

**Optional** (for auto-detection mode):
- Python 3
- Pillow library (`pip3 install Pillow`)

## Troubleshooting Patterns

**Monitor not starting**:
- Check if already running: `pgrep -lf vpn-monitor-orizon`
- Check lock file: `cat ~/tmp/.vpn-monitor.lock` (contains PID)
- Remove stale lock: `rm -f ~/tmp/.vpn-monitor.lock`

**Click not working**:
- Verify Accessibility permissions for terminal
- Test cliclick manually: `cliclick p`
- Check if window name changed: Run script manually to see detected window info
- Try toggling PRIVACY_MODE in config.sh

**Mouse not restoring to negative coords**:
- Verify using CoreGraphics path (not cliclick) for negative coordinates
- Test manually: `osascript -l JavaScript -e 'ObjC.import("CoreGraphics"); $.CGWarpMouseCursorPosition({x: -100, y: 200});'`

**Focus not restoring**:
- Check if bundle ID was captured: grep "Bundle ID" ~/tmp/vpn-monitor.log
- Timing issue: adjust sleep values in auto-click-connect.sh lines ~208

**VPN not detected as connected**:
- Check UUID: `scutil --nc list`
- Check interface: `ifconfig | grep utun`
- Verify IP pattern matches your VPN's subnet in vpn-monitor-orizon.sh line ~52

## Important Conventions

1. **Never hardcode paths** - Always use `$HOME` or `~` for user directories
2. **Always use absolute paths** in installed scripts (e.g., `~/bin/`, not relative paths)
3. **Logging format**: `[YYYY-MM-DD HH:MM:SS] message` (ISO 8601 timestamps)
4. **Portuguese alerts**: All user-facing voice/notifications in Portuguese (Brazilian)
5. **Error handling**: Scripts should return 0 on success, 1 on failure
6. **Idempotency**: Installation and restart scripts should be safely re-runnable
7. **No sensitive data**: Never store VPN credentials - only UUIDs and interface names

## When Making Changes

**To the monitoring logic**:
- Test with `test-disconnect-with-countdown.sh` to verify full flow
- Monitor logs in real-time: `tail -f ~/tmp/vpn-monitor.log`
- Ensure lock file handling remains correct

**To the click automation**:
- Test both PRIVACY_MODE=true and false
- Verify multi-monitor scenarios (positive and negative coordinates)
- Check timing between click and focus restoration (currently 0.2s)

**To the restoration logic**:
- Test with different apps in focus (browsers, IDEs, terminals)
- Verify bundle ID capture and restoration
- Test mouse restoration on different monitor configurations

**To configuration**:
- Update both config.sh and the script's embedded defaults
- Document in README.md if user-visible
- Use export for variables used by child scripts

## Documentation References

- `docs/FINAL-IMPLEMENTATION.md` - Complete technical implementation details
- `docs/MULTI-MONITOR-SUPPORT.md` - Multi-monitor and negative coordinate handling
- `docs/CLICK-CALIBRATION.md` - Button coordinate calibration process
- `docs/PRIVACY-MODE.md` - Privacy mode vs auto-detection details
- `CHANGELOG.md` - Version history and feature additions
