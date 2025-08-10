# Huffman Data Directory

This directory contains input data and generation tools for the **Huffman coding** benchmark, which tests compression algorithms with various data types and entropy characteristics.

## Directory Overview

```
huffman/
├── generated/                    # Generated test files
│   ├── huffman_generator.py      # Python data generator
│   └── [test files]              # Various entropy test datasets
├── test1024_H2.206587175259.in   # Original test file (1MB)
└── README.md                     # This file
```

## About Huffman Data

The Huffman benchmark tests **lossless compression performance** using:
- **Variable entropy data** - From highly compressible to nearly random
- **Different data patterns** - Text-like, binary, repetitive, and random
- **Multiple file sizes** - 64KB to 4MB for scalability testing
- **Realistic datasets** - Mimicking real-world compression scenarios

### Data Types and Characteristics

| Type | Entropy | Compression | Use Case |
|------|---------|-------------|----------|
| **Random** | High (~8 bits) | Poor | Worst-case performance |
| **Text-like** | Medium (~4-5 bits) | Good | Realistic text files |
| **Binary** | Mixed (~5-6 bits) | Moderate | Executable/binary files |
| **Zipf** | Natural (~3-4 bits) | Very Good | Natural language |
| **Low Entropy** | Low (~2 bits) | Excellent | Simple patterns |
| **Repetitive** | Very Low (~1 bit) | Extreme | Best-case performance |

## Generating Test Data

### Run the Python Generator

```bash
# Navigate to the generated directory
cd generated

# Run the generator (requires Python 3 + numpy)
python3 huffman_generator.py
```

### Generated File Naming

Files follow the pattern: `<type>_<size>_<entropy>.in`
- **Type**: `random`, `text_like`, `binary`, `zipf`, `low_entropy`, `repetitive`
- **Size**: `64K`, `256K`, `1M`, `4M`
- **Entropy**: `HighE`, `MedE`, `LowE`, `VeryLowE`, `MixedE`, `NaturalE`

### Example Generated Files

```
generated/
├── random_1M_HighE.in          # 1MB random data (high entropy)
├── text_like_256K_MedE.in      # 256KB text-like data (medium entropy)
├── low_entropy_64K_LowE.in     # 64KB simple patterns (low entropy)
├── repetitive_4M_VeryLowE.in   # 4MB repetitive data (very low entropy)
├── binary_1M_MixedE.in         # 1MB binary-like data (mixed entropy)
└── zipf_256K_NaturalE.in       # 256KB natural language-like data
```

## Available Datasets

### Pre-generated Files
- **Original test**: `test1024_H2.206587175259.in` (1MB, low entropy)

### Generated Test Suite
Each entropy type is available in multiple sizes:
- **64KB** - Small/quick testing
- **256KB** - Medium scale testing  
- **1MB** - Standard benchmark size
- **4MB** - Large scale performance

## Usage Tips

**For compression testing:**
- Start with `repetitive_64K_VeryLowE.in` (best compression)
- Test with `random_1M_HighE.in` (worst compression)
- Use `text_like_256K_MedE.in` for realistic performance

**For performance benchmarking:**
- Small files (64KB): Algorithm validation
- Medium files (256KB-1MB): Standard benchmarking
- Large files (4MB): Scalability testing

**For algorithm development:**
- `low_entropy_*` files: Test compression efficiency
- `random_*` files: Test worst-case performance
- `zipf_*` files: Test with natural data distributions

## Data Characteristics

### Entropy Analysis
The generator automatically calculates and reports:
- **File size** in bytes
- **Entropy** in bits per symbol (0-8 range)
- **Byte distribution** statistics
- **Compression potential** estimates

### Expected Compression Ratios
- **Repetitive**: 50:1 to 100:1 ratio
- **Low entropy**: 10:1 to 20:1 ratio
- **Zipf/Natural**: 3:1 to 8:1 ratio
- **Text-like**: 2:1 to 5:1 ratio
- **Binary/Mixed**: 1.5:1 to 3:1 ratio
- **Random**: 1:1 ratio (no compression)

## File Format

All input files are **binary format** containing:
- Raw byte data (0-255 values)
- No headers or metadata
- Direct input for Huffman algorithm
- Platform-independent format

## Benchmarking Guidelines

**Standard test sequence:**
1. **Warm-up**: Small repetitive file
2. **Best case**: Large low-entropy file
3. **Realistic**: Medium text-like file
4. **Worst case**: Large random file
5. **Scalability**: Various sizes of same entropy type

**Performance metrics to track:**
- Compression ratio achieved
- Encoding time per MB
- Memory usage during compression
- Throughput (MB/s)

---

*Part of the Rodinia Benchmark Suite - Huffman coding data utilities*
