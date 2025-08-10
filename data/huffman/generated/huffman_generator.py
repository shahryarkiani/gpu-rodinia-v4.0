#!/usr/bin/env python3
"""
Huffman Input File Generator
Generates various types of input files for testing Huffman coding performance
with different entropy characteristics and data patterns.
"""

import os
import sys
import random
import struct
import numpy as np
from collections import Counter
import math

def calculate_entropy(data):
    """Calculate the entropy of data in bits per symbol"""
    if len(data) == 0:
        return 0.0
    
    # Count frequency of each byte value
    counter = Counter(data)
    total = len(data)
    
    entropy = 0.0
    for count in counter.values():
        p = count / total
        if p > 0:
            entropy -= p * math.log2(p)
    
    return entropy

def analyze_existing_file(filename):
    """Analyze the existing Huffman input file"""
    try:
        with open(filename, 'rb') as f:
            data = f.read()
        
        print(f"Analyzing {filename}:")
        print(f"  Size: {len(data):,} bytes")
        print(f"  Entropy: {calculate_entropy(data):.6f} bits/symbol")
        
        # Show byte distribution
        counter = Counter(data)
        print(f"  Unique bytes: {len(counter)}/256")
        print(f"  Most common bytes: {counter.most_common(5)}")
        print(f"  Least common bytes: {counter.most_common()[-5:]}")
        
        return data
    except FileNotFoundError:
        print(f"File {filename} not found")
        return None

def generate_uniform_random(size, filename):
    """Generate uniformly random data (high entropy ~8 bits/symbol)"""
    data = bytearray(random.getrandbits(8) for _ in range(size))
    
    with open(filename, 'wb') as f:
        f.write(data)
    
    entropy = calculate_entropy(data)
    print(f"Generated {filename}: {size:,} bytes, entropy {entropy:.6f}")
    return entropy

def generate_low_entropy(size, filename, num_symbols=4):
    """Generate low entropy data using only a few symbols"""
    symbols = list(range(num_symbols))
    # Zipf distribution for realistic low entropy
    weights = [1.0 / (i + 1) for i in range(num_symbols)]
    
    data = bytearray(random.choices(symbols, weights=weights, k=size))
    
    with open(filename, 'wb') as f:
        f.write(data)
    
    entropy = calculate_entropy(data)
    print(f"Generated {filename}: {size:,} bytes, entropy {entropy:.6f}")
    return entropy

def generate_text_like(size, filename):
    """Generate text-like data (medium entropy ~4-5 bits/symbol)"""
    # ASCII printable characters with letter frequency bias
    letters = 'etaoinshrdlcumwfgypbvkjxqz'
    spaces_punct = ' .,!?;:\n\t'
    
    # Create weighted character set
    chars = []
    weights = []
    
    # Letters (more frequent)
    for i, c in enumerate(letters):
        chars.extend([ord(c), ord(c.upper())])
        weight = 26 - i  # Higher weight for more common letters
        weights.extend([weight, weight // 3])  # Lowercase more common
    
    # Spaces and punctuation
    for c in spaces_punct:
        chars.append(ord(c))
        weights.append(10 if c == ' ' else 2)
    
    # Numbers
    for i in range(10):
        chars.append(ord(str(i)))
        weights.append(5)
    
    data = bytearray(random.choices(chars, weights=weights, k=size))
    
    with open(filename, 'wb') as f:
        f.write(data)
    
    entropy = calculate_entropy(data)
    print(f"Generated {filename}: {size:,} bytes, entropy {entropy:.6f}")
    return entropy

def generate_repetitive_pattern(size, filename):
    """Generate repetitive pattern data (very low entropy)"""
    # Create a repeating pattern
    pattern = b'ABCDABCDABCDABCD1234567890!@#$%^&*()'
    repeats = (size + len(pattern) - 1) // len(pattern)
    data = (pattern * repeats)[:size]
    
    with open(filename, 'wb') as f:
        f.write(data)
    
    entropy = calculate_entropy(data)
    print(f"Generated {filename}: {size:,} bytes, entropy {entropy:.6f}")
    return entropy

def generate_binary_data(size, filename):
    """Generate binary-like data with structured patterns"""
    data = bytearray()
    
    # Mix of different patterns
    for i in range(0, size, 1024):
        chunk_size = min(1024, size - i)
        
        if i % 4096 < 2048:
            # More structured data (headers, metadata-like)
            chunk = bytearray([0x00, 0xFF, 0x55, 0xAA] * (chunk_size // 4))
            chunk.extend([0x00] * (chunk_size % 4))
        else:
            # More random data (payload-like)
            chunk = bytearray(random.getrandbits(8) for _ in range(chunk_size))
        
        data.extend(chunk[:chunk_size])
    
    with open(filename, 'wb') as f:
        f.write(data)
    
    entropy = calculate_entropy(data)
    print(f"Generated {filename}: {size:,} bytes, entropy {entropy:.6f}")
    return entropy

def generate_zipf_distribution(size, filename, alpha=1.5):
    """Generate data following Zipf distribution (realistic entropy)"""
    # Generate Zipf distribution for 256 possible byte values
    symbols = list(range(256))
    weights = [1.0 / (i + 1) ** alpha for i in range(256)]
    
    data = bytearray(random.choices(symbols, weights=weights, k=size))
    
    with open(filename, 'wb') as f:
        f.write(data)
    
    entropy = calculate_entropy(data)
    print(f"Generated {filename}: {size:,} bytes, entropy {entropy:.6f}")
    return entropy

def main():
    # Create output directory
    output_dir = "data/"
    os.makedirs(output_dir, exist_ok=True)
    
    print("Huffman Input File Generator")
    print("=" * 50)
    
    # Analyze existing file if it exists
    existing_file = "data/huffman/test1024_H2.206587175259.in"
    if os.path.exists(existing_file):
        analyze_existing_file(existing_file)
        print()
    
    # Standard sizes to generate
    sizes = [
        (64 * 1024, "64K"),      # 64KB
        (256 * 1024, "256K"),    # 256KB  
        (1024 * 1024, "1M"),     # 1MB (same as original)
        (4 * 1024 * 1024, "4M"), # 4MB
    ]
    
    print("Generating test files:")
    print("-" * 30)
    
    for size_bytes, size_name in sizes:
        print(f"\nGenerating {size_name} files:")
        
        # High entropy (random data) - should compress poorly
        generate_uniform_random(
            size_bytes, 
            f"{output_dir}/random_{size_name}_HighE.in"
        )
        
        # Low entropy (few symbols) - should compress very well
        generate_low_entropy(
            size_bytes, 
            f"{output_dir}/low_entropy_{size_name}_LowE.in", 
            num_symbols=4
        )
        
        # Text-like data (medium entropy) - realistic compression
        generate_text_like(
            size_bytes, 
            f"{output_dir}/text_like_{size_name}_MedE.in"
        )
        
        # Repetitive pattern (very low entropy) - extreme compression
        generate_repetitive_pattern(
            size_bytes, 
            f"{output_dir}/repetitive_{size_name}_VeryLowE.in"
        )
        
        # Binary-like data (mixed entropy) - realistic binary files
        generate_binary_data(
            size_bytes, 
            f"{output_dir}/binary_{size_name}_MixedE.in"
        )
        
        # Zipf distribution (natural language-like)
        generate_zipf_distribution(
            size_bytes, 
            f"{output_dir}/zipf_{size_name}_NaturalE.in",
            alpha=1.5
        )
    
    print("\n" + "=" * 50)
    print("File generation complete!")
    print(f"Generated files are in: {output_dir}/")
    print("\nTo test with these files:")
    print("  cd cuda/huffman")
    print("  make")
    print("  ./pavle ../../data/huffman/generated/[filename]")

if __name__ == "__main__":
    main()