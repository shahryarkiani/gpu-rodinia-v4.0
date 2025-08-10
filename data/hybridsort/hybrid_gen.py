#!/usr/bin/env python3
"""
Hybrid Sort Input Generator
Generates input files with random floating point numbers for testing hybrid sort
"""

import os
import sys
from random import random

def hybrid_gen(size, filename):
    """Generate input file with random floats"""
    print(f"Generating {size:,} numbers...")
    
    
    with open(filename, 'w') as f:
        
        # Generate random floats
        for _ in range(size):
            num = round(random(), 6)
            f.write(f" {num}")
    
    print(f"Generated {filename}")

def main():
    if len(sys.argv) != 3:
        print("Usage: python hybrid_gen.py <size> <name_suffix>")
        print("Example: python hybrid_gen.py 1000000 1M")
        sys.exit(1)
        
    size = int(sys.argv[1])
    suffix = sys.argv[2]
    
    if size <= 0:
        print("Error: Size must be positive")
        sys.exit(1)
        
    filename = f"{suffix}.txt"
    hybrid_gen(size, filename)

if __name__ == "__main__":
    main()
