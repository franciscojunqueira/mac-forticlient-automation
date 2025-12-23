#!/usr/bin/env python3
"""
Analyze colors in FortiClient screenshot to find button color.
"""

from PIL import Image
from collections import Counter

img = Image.open("/tmp/forticlient-window.png")
width, height = img.size
pixels = img.load()

print(f"Image size: {width}x{height}")
print("\nSampling colors in bottom 40% of image (where button is)...")

# Sample pixels in bottom area
start_y = int(height * 0.6)
color_samples = []

for y in range(start_y, height, 10):  # Sample every 10 pixels
    for x in range(50, width - 50, 10):
        rgb = pixels[x, y][:3]
        color_samples.append(rgb)

# Find most common colors
counter = Counter(color_samples)
most_common = counter.most_common(20)

print("\n20 most common colors (R, G, B) [count]:")
print("=" * 60)
for color, count in most_common:
    r, g, b = color
    # Highlight blue-ish colors
    marker = "  🔵" if b > 150 and r < 100 else ""
    print(f"RGB({r:3d}, {g:3d}, {b:3d}) [{count:4d}]{marker}")

# Look specifically for blue colors
print("\n\nBlue-ish colors (B > 150, R < 100):")
print("=" * 60)
blue_colors = [(c, cnt) for c, cnt in most_common if c[2] > 150 and c[0] < 100]
for color, count in blue_colors:
    print(f"RGB{color} [{count}]")
