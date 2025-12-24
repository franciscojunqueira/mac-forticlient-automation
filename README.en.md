**English** | [Português (Brasil)](README.md)

# VPN Monitor & Auto-Reconnect - FortiClient

Complete monitoring and automatic reconnection system for FortiClient Zero Trust Fabric Agent with MFA authentication. Achieves ~95% automation, leaving only manual MFA approval (mandatory for security).

## 📋 Overview

This is a **bash-based automation system** that monitors VPN connections and automatically reconnects when disconnected, including automated UI interaction to click the "Connect" button.

**Problem solved:** Manually reconnecting VPN is tedious and interrupts workflow. This system automates the entire process, except for MFA approval (which is mandatory for security).

**Who it's for:** Developers and remote professionals who need to maintain an active VPN connection at all times, especially in multi-monitor setups.

## ✨ Features

- ✅ Continuous VPN connection monitoring (checks every 5 seconds)
- ✅ Reliable dual detection (scutil + ifconfig)
- ✅ Multiple alerts when VPN disconnects:
  - Voice alert in Brazilian Portuguese (Luciana voice)
  - System sounds
  - macOS notifications
- ✅ 95% automatic reconnection:
  - Automatically detects disconnection
  - Saves user context (focused app + mouse position)
  - Opens FortiClient automatically
  - Automatically clicks "Connect" button
  - Restores mouse to original position (supports multi-monitor with negative coordinates)
  - Restores focus to original application
  - Closes FortiClient window after successful connection
  - Restores final focus to your application
- ✅ Full multi-monitor support via CoreGraphics
- ✅ Two button detection modes:
  - Auto-detection via computer vision (Python + Pillow)
  - Calibrated fixed coordinates (privacy mode - no screenshots)
- ✅ Lock file to prevent multiple instances
- ✅ Detailed logs for debugging
- ✅ Test and management scripts included
- ✅ Support for automatic startup on macOS login

## 🏗️ Architecture

### Core Components

1. **vpn-monitor-orizon.sh** - Main monitoring daemon
   - Check loop every 5 seconds
   - Dual verification (scutil + ifconfig)
   - Reconnection flow orchestration
   - Lock file management (`~/tmp/.vpn-monitor.lock`)

2. **auto-click-connect.sh** - UI automation component
   - Dynamic FortiClient window position detection
   - Two button detection modes (auto/manual)
   - User context restoration (mouse + focus)
   - Multi-monitor support with negative coordinates

3. **config.sh** - Centralized configuration
   - PRIVACY_MODE toggle
   - Button offsets for manual mode
   - VPN settings (UUID, interface, interval)

### Reconnection Flow

```
VPN disconnects
   ↓
Detects in ~5s (dual check)
   ↓
Saves context (focused app + mouse position)
   ↓
Alerts (PT-BR voice + sound + notification)
   ↓
Opens FortiClient automatically
   ↓
Clicks "Connect" button automatically
   ↓
Restores mouse (0.2s after click)
   ↓
Waits for MFA modal (2s)
   ↓
Restores focus to original application
   ↓
→ You approve on phone (ONLY MANUAL ACTION) ←
   ↓
VPN reconnects
   ↓
Closes FortiClient automatically
   ↓
Restores final focus
   ↓
Confirmation alert
```

**Reduces from 7 manual actions to just 1!** 🎉

## 🔧 Prerequisites

- **Operating System:** macOS 14+ (Sonoma or later)
- **Software:**
  - FortiClient Zero Trust Fabric Agent installed
  - VPN connection configured in FortiClient
  - [cliclick](https://github.com/BlueM/cliclick) installed (`brew install cliclick`)
  - Bash 5.x (default on modern macOS)
- **Optional (for auto-detection mode):**
  - Python 3
  - Pillow (`pip3 install Pillow`)
- **macOS Permissions:**
  - **Accessibility** (required) - For cliclick to work
  - **Screen Recording** (only if PRIVACY_MODE=false) - For automatic button detection

### Configure Permissions

1. Open: **System Settings → Privacy & Security → Accessibility**
2. Click **+** and add your terminal (Terminal.app, iTerm2, Warp, etc.)
3. If using PRIVACY_MODE=false: **System Settings → Privacy & Security → Screen Recording** and add your terminal

## 🚀 Installation

### Automatic Installation (Recommended)

```bash
cd ~/GitHub/mac-Forticlient-automation
./install.sh
```

The installer will:
- Automatically detect VPN UUID
- Install dependencies (cliclick via Homebrew)
- Copy scripts to correct locations
- Configure permissions
- Optionally add to Login Items

### Manual Installation

```bash
# 1. Create necessary directories
mkdir -p ~/bin ~/tmp ~/GitHub/mac-Forticlient-automation/scripts

# 2. Copy main script
cp scripts/vpn-monitor-orizon.sh ~/bin/
chmod +x ~/bin/vpn-monitor-orizon.sh

# 3. Copy auto-click script
cp scripts/auto-click-connect.sh ~/GitHub/mac-Forticlient-automation/scripts/
chmod +x ~/GitHub/mac-Forticlient-automation/scripts/auto-click-connect.sh

# 4. Copy configuration
cp config.sh ~/GitHub/mac-Forticlient-automation/

# 5. Install cliclick
brew install cliclick

# 6. Configure VPN UUID
scutil --nc list  # Copy your VPN UUID
nano ~/bin/vpn-monitor-orizon.sh  # Edit line 14: FORTICLIENT_UUID="your-uuid"
```

## ⚙️ Configuration

### Basic Configuration

Edit `~/GitHub/mac-Forticlient-automation/config.sh`:

```bash
# Button detection mode
export PRIVACY_MODE=false  # false=auto-detection, true=fixed coordinates

# Fixed coordinates (only if PRIVACY_MODE=true)
export BUTTON_OFFSET_X=552
export BUTTON_OFFSET_Y=525

# VPN UUID (leave empty for auto-detect)
export FORTICLIENT_UUID=""

# VPN interface (usually utun7 for FortiClient)
export VPN_INTERFACE="utun7"

# Check interval in seconds
export CHECK_INTERVAL=5

# Enable automatic reconnection
export AUTO_RECONNECT=true
```

### Find VPN UUID

```bash
scutil --nc list
```

Look for an entry containing "FortiClient" or "VPN" and copy the UUID (format: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX).

### Customize Voice Alerts

Edit `~/bin/vpn-monitor-orizon.sh`:

```bash
# Line 73 - Disconnection alert
say -v Luciana "Atenção! A V P N foi desconectada..."

# Line 89 - Reconnection alert
say -v Luciana "V P N reconectada com sucesso"

# Other available voices: Joana, Felipe
# List all: say -v "?"
```

## 💻 Usage

### Start Monitor

```bash
~/bin/vpn-monitor-orizon.sh > ~/tmp/vpn-monitor.log 2>&1 &
```

### Check Status

```bash
# Check if running
pgrep -lf vpn-monitor-orizon

# View logs in real-time
tail -f ~/tmp/vpn-monitor.log

# View last 50 lines
tail -n 50 ~/tmp/vpn-monitor.log
```

### Stop Monitor

```bash
pkill -f vpn-monitor-orizon
rm -f ~/tmp/.vpn-monitor.lock
```

### Restart Monitor

```bash
# Easy method (recommended)
~/GitHub/mac-Forticlient-automation/scripts/restart-monitor.sh

# Manual method
pkill -f vpn-monitor-orizon
rm -f ~/tmp/.vpn-monitor.lock
~/bin/vpn-monitor-orizon.sh > ~/tmp/vpn-monitor.log 2>&1 &
```

## 🧪 Tests

### Simple Test

```bash
# Manually disconnect VPN
scutil --nc stop "VPN"

# Wait ~5 seconds and observe:
# 1. Voice alert in Portuguese
# 2. FortiClient opens automatically
# 3. Automatic click on Connect button
# 4. Mouse and focus return to where they were
# 5. Approve on phone when notified
# 6. FortiClient closes automatically
# 7. Focus returns to your application
```

### Automated Test with Countdown

```bash
~/GitHub/mac-Forticlient-automation/scripts/test-disconnect-with-countdown.sh
```

This script will:
- Count 5 seconds
- Disconnect VPN
- You observe the entire automatic process
- Focus and mouse should return to terminal

### Forced Disconnection (For Testing)

```bash
~/GitHub/mac-Forticlient-automation/scripts/force-disconnect-vpn.sh
```

## 🐛 Troubleshooting

### Monitor doesn't start

**Symptom:** Script doesn't start or exits immediately.

**Solutions:**
```bash
# Check permissions
ls -la ~/bin/vpn-monitor-orizon.sh
# Should show: -rwxr-xr-x

# Fix permissions
chmod +x ~/bin/vpn-monitor-orizon.sh

# Check if already running
pgrep -lf vpn-monitor-orizon

# Remove old lock file
rm -f ~/tmp/.vpn-monitor.lock
```

### No voice alerts

**Symptom:** No voice alert when VPN disconnects.

**Solutions:**
```bash
# Test say command
say -v Luciana "teste em português"

# Check installed voices
say -v "?"

# Install Luciana voice
# Go to: System Settings → Accessibility → Spoken Content → System Voices
# Download: Portuguese (Brazil) - Luciana
```

### Auto-click doesn't work

**Symptom:** FortiClient opens but Connect button is not clicked.

**Solutions:**
```bash
# Check if cliclick is installed
which cliclick
# If not: brew install cliclick

# Test cliclick
cliclick p  # Should show mouse position

# Check Accessibility permissions
# Go to: System Settings → Privacy & Security → Accessibility
# Add your terminal

# Toggle detection mode
# Edit config.sh: PRIVACY_MODE=true (or false)
```

### Mouse doesn't return to original position on multi-monitor

**Symptom:** Mouse doesn't return to original position, especially with negative coordinates.

**Solutions:**
```bash
# Test CoreGraphics
osascript -l JavaScript << 'EOF'
ObjC.import('CoreGraphics');
var point = {x: 500, y: -100};
$.CGWarpMouseCursorPosition(point);
console.log("Mouse moved to negative coordinates");
EOF

# If it works, problem might be timing
# Edit auto-click-connect.sh line ~179: adjust sleep
```

### FortiClient doesn't open

**Symptom:** FortiClient is not opened automatically.

**Solutions:**
```bash
# Test manually
open -a "FortiClient"

# Check installation
ls -la /Applications/FortiClient.app

# Check correct app name
ls -la /Applications/ | grep -i forti
```

### Multiple instances running

**Symptom:** Duplicate logs or erratic behavior.

**Solutions:**
```bash
# Use restart script (recommended)
~/GitHub/mac-Forticlient-automation/scripts/restart-monitor.sh

# Or kill all and restart
pkill -9 -f vpn-monitor-orizon
rm -f ~/tmp/.vpn-monitor.lock
~/bin/vpn-monitor-orizon.sh > ~/tmp/vpn-monitor.log 2>&1 &
```

### VPN not detected as connected

**Symptom:** Monitor thinks VPN is always disconnected.

**Solutions:**
```bash
# Check UUID
scutil --nc list

# Check status
scutil --nc status "YOUR-UUID-HERE"

# Check interface
ifconfig | grep utun

# Adjust IP pattern
# Edit vpn-monitor-orizon.sh line ~52
# Example: if ifconfig "$VPN_INTERFACE" 2>/dev/null | grep -q "inet 172\.16\.";
```

## 🗺️ Roadmap

- [ ] Optional GUI (menu bar app)
- [ ] Support for other VPN clients
- [ ] Connection metrics and statistics
- [ ] Customizable notifications via Notification Center
- [ ] Slack/Teams integration for notifications
- [ ] Silent mode (no voice alerts)

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

### Report Bugs

Open an issue including:
- macOS version
- FortiClient version
- Relevant logs (`~/tmp/vpn-monitor.log`)
- Steps to reproduce

### Suggest Improvements

Open an issue describing:
- The problem you're trying to solve
- Your proposed solution
- Alternatives considered

### Submit Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/MyFeature`)
3. Commit your changes (`git commit -m 'Add MyFeature'`)
4. Push to the branch (`git push origin feature/MyFeature`)
5. Open a Pull Request

### Code Standards

- Use idiomatic bash and POSIX when possible
- Add comments for complex logic
- Maintain log format: `[YYYY-MM-DD HH:MM:SS] message`
- Test in multiple scenarios (single/multi-monitor)
- Update documentation if needed

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

Copyright (c) 2025 Francisco Junqueira

## 📚 Additional Documentation

- [Complete Technical Documentation](docs/FINAL-IMPLEMENTATION.md)
- [Multi-Monitor Support](docs/MULTI-MONITOR-SUPPORT.md)
- [Click Calibration](docs/CLICK-CALIBRATION.md)
- [Privacy Mode](docs/PRIVACY-MODE.md)
- [Technical Analysis](docs/vpn-monitor-analysis.md)
- [Changelog](CHANGELOG.md)
- [WARP Guide](WARP.md)

## 📞 Contact

**Maintainer:** Francisco Junqueira

**Repository:** [mac-Forticlient-automation](https://github.com/franciscojunqueira/mac-Forticlient-automation)

---

**Developed to automate VPN monitoring with FortiClient + MFA**

✨ The most automated solution possible while respecting security boundaries ✨

🎯 **95% automation** - You just approve on your phone! 🎯
