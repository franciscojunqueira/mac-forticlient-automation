#!/usr/bin/env python3
"""
FortiClient Connect Button Finder
Uses screenshot analysis to automatically find the Connect button coordinates.
"""

import subprocess
import sys
import json
from pathlib import Path


def run_command(cmd):
    """Execute shell command and return output."""
    result = subprocess.run(
        cmd,
        shell=True,
        capture_output=True,
        text=True
    )
    return result.stdout.strip(), result.returncode


def get_window_bounds():
    """Get FortiClient window position and size using AppleScript."""
    script = '''
    tell application "System Events"
        tell process "FortiClient"
            tell window "FortiClient -- Zero Trust Fabric Agent"
                get {position, size}
            end tell
        end tell
    end tell
    '''
    
    output, code = run_command(f"osascript -e '{script}'")
    if code != 0:
        print("❌ Error: FortiClient window not found", file=sys.stderr)
        sys.exit(1)
    
    # Parse output: "273, 93, 894, 714"
    values = [int(x.strip()) for x in output.split(',')]
    return {
        'x': values[0],
        'y': values[1],
        'width': values[2],
        'height': values[3]
    }


def capture_window_screenshot(bounds, output_path):
    """Capture screenshot of FortiClient window."""
    x, y = bounds['x'], bounds['y']
    w, h = bounds['width'], bounds['height']
    
    # Use screencapture with exact coordinates
    cmd = f"screencapture -R{x},{y},{w},{h} {output_path}"
    _, code = run_command(cmd)
    
    if code != 0:
        print("❌ Error capturing screenshot", file=sys.stderr)
        sys.exit(1)
    
    print(f"✓ Screenshot saved: {output_path}")


def analyze_screenshot_for_button(image_path, window_bounds):
    """
    Analyze screenshot to find Connect button.
    Uses pixel analysis and known UI patterns.
    """
    try:
        from PIL import Image
    except ImportError:
        print("❌ Error: Pillow not installed. Run: pip3 install Pillow", file=sys.stderr)
        sys.exit(1)
    
    img = Image.open(image_path)
    width, height = img.size
    pixels = img.load()
    
    # FortiClient Connect button characteristics:
    # - Blue background (RGB around 28, 116, 179)
    # - Located in center-bottom area
    # - Approximate size: 100-150px wide, 30-40px tall
    
    print(f"✓ Image size: {width}x{height}")
    print("🔍 Scanning for Connect button (blue color pattern)...")
    
    # Search in bottom 60% of window (where button is located)
    search_start_y = int(height * 0.4)
    
    # Track blue pixel regions
    button_regions = []
    
    for y in range(search_start_y, height - 100):
        for x in range(100, width - 100):
            r, g, b = pixels[x, y][:3]  # Get RGB, ignore alpha if present
            
            # Detect blue button color (FortiClient Connect button)
            # Tolerant range: R:20-40, G:105-130, B:165-195
            if 20 <= r <= 40 and 105 <= g <= 130 and 165 <= b <= 195:
                button_regions.append((x, y))
    
    if not button_regions:
        print("❌ Connect button not found (no blue pixels detected)", file=sys.stderr)
        print("ℹ️  Make sure FortiClient window shows the Connect button", file=sys.stderr)
        sys.exit(1)
    
    # Find center of button region
    avg_x_screenshot = sum(p[0] for p in button_regions) // len(button_regions)
    avg_y_screenshot = sum(p[1] for p in button_regions) // len(button_regions)
    
    # Detect Retina display (screenshot is 2x window size)
    scale_factor = width / window_bounds['width']
    
    # Convert screenshot coordinates to window coordinates
    avg_x = int(avg_x_screenshot / scale_factor)
    avg_y = int(avg_y_screenshot / scale_factor)
    
    # Convert to absolute screen coordinates
    abs_x = window_bounds['x'] + avg_x
    abs_y = window_bounds['y'] + avg_y
    
    print(f"✓ Screenshot scale: {scale_factor}x (Retina: {scale_factor == 2})")
    print(f"✓ Button found at window coords: ({avg_x}, {avg_y})")
    print(f"✓ Absolute screen coords: ({abs_x}, {abs_y})")
    
    return {
        'relative_x': avg_x,
        'relative_y': avg_y,
        'absolute_x': abs_x,
        'absolute_y': abs_y,
        'window_x': window_bounds['x'],
        'window_y': window_bounds['y'],
        'offset_x': avg_x,
        'offset_y': avg_y
    }


def main():
    print("🔍 FortiClient Connect Button Finder")
    print("=" * 50)
    
    # Step 1: Get window bounds
    print("\n1️⃣  Getting FortiClient window position...")
    bounds = get_window_bounds()
    print(f"✓ Window: {bounds['x']},{bounds['y']} size: {bounds['width']}x{bounds['height']}")
    
    # Step 2: Capture screenshot
    print("\n2️⃣  Capturing window screenshot...")
    screenshot_path = "/tmp/forticlient-window.png"
    capture_window_screenshot(bounds, screenshot_path)
    
    # Step 3: Analyze screenshot
    print("\n3️⃣  Analyzing screenshot for Connect button...")
    result = analyze_screenshot_for_button(screenshot_path, bounds)
    
    # Step 4: Output results
    print("\n" + "=" * 50)
    print("📍 BUTTON COORDINATES FOUND:")
    print("=" * 50)
    print(f"Window position: ({result['window_x']}, {result['window_y']})")
    print(f"Button offset:   ({result['offset_x']}, {result['offset_y']})")
    print(f"Absolute coords: ({result['absolute_x']}, {result['absolute_y']})")
    
    # Save to JSON for script consumption
    json_path = "/tmp/forticlient-button-coords.json"
    with open(json_path, 'w') as f:
        json.dump(result, f, indent=2)
    
    print(f"\n💾 Results saved to: {json_path}")
    print(f"🖼️  Screenshot saved to: {screenshot_path}")


if __name__ == "__main__":
    main()
