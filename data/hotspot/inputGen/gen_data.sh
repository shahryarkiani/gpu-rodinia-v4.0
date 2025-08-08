#!/bin/bash

# Simple Hotspot Data Generation Script
# Generates a few different dataset sizes from small to large
# Just run: ./gen_data.sh

# Generate different sizes (small to large)
echo "Generating datasets:"

# Small: 128x128 (2x expansion)
echo "→ Generating 128x128 (small)..."
./hotspot_generator 64 2 temp_64 power_64 temp_128 power_128 --quiet

# Medium: 256x256 (4x expansion) 
echo "→ Generating 256x256 (medium)..."
./hotspot_generator 64 4 temp_64 power_64 temp_256 power_256 --quiet

# Large: 512x512 (8x expansion)
echo "→ Generating 512x512 (large)..."
./hotspot_generator 64 8 temp_64 power_64 temp_512 power_512 --quiet

# Extra Large: 1024x1024 (16x expansion)
echo "→ Generating 1024x1024 (extra large)..."
./hotspot_generator 64 16 temp_64 power_64 temp_1024 power_1024 --quiet

echo
echo "=== Generation Complete ==="
echo "Available datasets:"
ls -lh temp_* power_* 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
echo
echo "Ready to use with hotspot simulation!"
