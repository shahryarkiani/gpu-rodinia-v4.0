#!/bin/bash

# DWT2D Data Generation Script
# Generates BMP test images of various sizes for DWT2D benchmark testing

echo "Generating DWT2D test images..."

# Create a simple generator script
cat > bmp_generator.py << 'EOF'
#!/usr/bin/env python3

import struct
import sys

def create_bmp(width, height, filename):
    """Create a simple checkerboard BMP image"""
    
    # BMP Header (54 bytes total)
    # File header (14 bytes)
    file_size = 54 + (width * height * 3)  # 3 bytes per pixel (RGB)
    bmp_header = struct.pack('<2sIHHI', 
        b'BM',      # Signature
        file_size,  # File size
        0,          # Reserved
        0,          # Reserved  
        54          # Offset to pixel data
    )
    
    # Info header (40 bytes)
    info_header = struct.pack('<IIIHHIIIIII',
        40,         # Header size
        width,      # Width
        height,     # Height
        1,          # Planes
        24,         # Bits per pixel
        0,          # Compression
        width * height * 3,  # Image size
        2835,       # X pixels per meter
        2835,       # Y pixels per meter
        0,          # Colors used
        0           # Important colors
    )
    
    # Generate checkerboard pattern
    pixels = []
    block_size = max(1, width // 8)  # 8x8 checkerboard
    
    for y in range(height):
        row = []
        for x in range(width):
            # Checkerboard pattern
            if ((x // block_size) + (y // block_size)) % 2 == 0:
                # Black
                row.extend([0, 0, 0])
            else:
                # White
                row.extend([255, 255, 255])
        
        # BMP rows are stored bottom-to-top, and padded to 4-byte boundary
        while len(row) % 4 != 0:
            row.append(0)
        pixels.extend(row)
    
    # Reverse rows (BMP stores bottom-to-top)
    row_size = (width * 3 + 3) // 4 * 4  # Padded row size
    reversed_pixels = []
    for i in range(height):
        start = i * row_size
        end = start + row_size
        reversed_pixels = pixels[start:end] + reversed_pixels
    
    # Write file
    with open(filename, 'wb') as f:
        f.write(bmp_header)
        f.write(info_header)
        f.write(bytes(reversed_pixels))
    
    print(f"Generated {width}x{height} image: {filename}")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python3 bmp_generator.py <width> <height> <filename>")
        sys.exit(1)
    
    width = int(sys.argv[1])
    height = int(sys.argv[2])
    filename = sys.argv[3]
    
    create_bmp(width, height, filename)
EOF

# Make generator executable
chmod +x bmp_generator.py

# Generate various sizes from small to large
echo "Generating test images..."

sizes=(4 8 16 32 64 128 192 256 512 1024)

for size in "${sizes[@]}"; do
    echo "Generating ${size}x${size} image..."
    python3 bmp_generator.py ${size} ${size} ${size}.bmp
done

# Clean up generator
rm bmp_generator.py

echo ""
echo "DWT2D test image generation complete!"
echo ""
echo "Generated files:"
ls -lh *.bmp | grep -E '[0-9]+\.bmp'
echo ""
echo "Usage examples:"
echo "cd ../../cuda/cuda_unused/dwt2d"
echo "./dwt2d ../../data/cuda_unused/dwt2d/192.bmp -d 192x192 -f -5 -l 3"