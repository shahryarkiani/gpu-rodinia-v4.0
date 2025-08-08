#!/bin/bash

# Simple Hotspot3D Data Generation Script
# Generates a few different 3D dataset sizes
# Just run: ./gen_data.sh

echo "Generating 3D datasets:"

# Small 3D: 64x64x4 (convert 2D to 3D with 4 layers)
echo "→ Generating 64x64x4 (small 3D)..."
./hotspot3D_generator 2d-to-3d 64 4 ../hotspot/inputGen/temp_64 ../hotspot/inputGen/power_64 temp_64x4 power_64x4 --quiet

# Medium 3D: 64x64x8 (convert 2D to 3D with 8 layers)
echo "→ Generating 64x64x8 (medium 3D)..."
./hotspot3D_generator 2d-to-3d 64 8 ../hotspot/inputGen/temp_64 ../hotspot/inputGen/power_64 temp_64x8 power_64x8 --quiet

# Large 3D: 128x128x4 (expand 64x64x4 to larger grid)
echo "→ Generating 128x128x4 (large 3D)..."
./hotspot3D_generator expand-grid 64 4 2 temp_64x4 power_64x4 temp_128x4 power_128x4 --quiet

# Extra Large 3D: 128x128x8 (expand 64x64x8 to larger grid)
echo "→ Generating 128x128x8 (extra large 3D)..."
./hotspot3D_generator expand-grid 64 8 2 temp_64x8 power_64x8 temp_128x8 power_128x8 --quiet