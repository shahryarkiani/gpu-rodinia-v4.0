#!/bin/bash

# Build the generator if needed
if [ ! -f "./lud_gen" ]; then
    echo "Building LUD generator..."
    make
fi

echo "Generating LUD matrices..."
echo "Note: Larger sizes will take longer to generate"

# Small sizes (quick generation)
echo -e "\nGenerating small matrices..."
./lud_gen 64
./lud_gen 128

# Medium sizes
echo -e "\nGenerating medium matrices..."
./lud_gen 256
./lud_gen 512

# Large sizes (may take a while)
echo -e "\nGenerating large matrices..."
echo "Warning: These may take several minutes..."
./lud_gen 1024
./lud_gen 2048

echo -e "\nGeneration complete! Available sizes:"
ls -lh *.dat | grep -v "^l-\|^u-" | awk '{print $9 " (" $5 ")"}'
