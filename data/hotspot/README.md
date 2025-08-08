# Hotspot Data Directory

This directory contains input data generation tools and datasets for the **Hotspot** thermal simulation benchmark.

## 📁 Directory Overview

```
hotspot/
├── inputGen/                    # Input file generation tools
│   ├── hotspot_generator        # Compiled generator executable
│   ├── hotspot_generator.cpp    # Generator source code
│   ├── Makefile                 # Build configuration
│   ├── GENERATOR_QUICKSTART.md  # Detailed generator guide
│   └── [input files]           # Pre-generated input files
└── README.md                    # This file
```

## 🔥 About Hotspot Data

Hotspot simulates **thermal behavior** in processor chips using 2D grids that represent:
- **Temperature distribution** across chip surface (°C)
- **Power dissipation** values for each grid cell (W)

### Input Data Format
- **Grid-based**: Square grids (64×64, 128×128, 320×320, 512×512)
- **File format**: One floating-point value per line, row-major order
- **Temperature files**: Initial temperature values for each cell
- **Power files**: Power dissipation values for each cell

## 🛠️ Generating Input Data

```bash
# Navigate to the generator directory
cd inputGen

# Build the generator (requires g++ or compatible compiler)
make

# Generate 320×320 data from 64×64 base (5x expansion)
./hotspot_generator 64 5 temp_64 power_64 temp_320 power_320
```

## 📊 Input File Generator

The `inputGen/` directory contains a powerful tool for creating scaled input datasets:

### Basic Usage
```bash
./hotspot_generator <input_size> <multiplier> <temp_in> <power_in> <temp_out> <power_out>
```

### Parameters
- `input_size`: Grid dimension of source files (e.g., 64 for 64×64)
- `multiplier`: Expansion factor (2 = double size, 5 = 5x larger)
- `temp_in/out`: Temperature input/output filenames
- `power_in/out`: Power dissipation input/output filenames

### Available Options
- `--quiet`: Minimal output for large datasets
- `--no-verify`: Skip verification (faster for trusted operations)
- `--verify-only`: Only verify existing files without expansion

### Common Examples
```bash
# Create 256×256 from 64×64 (4x expansion)
./hotspot_generator 64 4 temp_64 power_64 temp_256 power_256

# Create large dataset (1536×1536) with minimal output
./hotspot_generator 512 3 temp_512 power_512 temp_1536 power_1536 --quiet

# Verify existing expansion
./hotspot_generator 64 5 temp_64 power_64 temp_320 power_320 --verify-only
```

## 📋 Pre-generated Input Files

The directory includes several ready-to-use input file pairs:

| Files | Grid Size | Elements | Use Case |
|-------|-----------|----------|----------|
| `temp_64`, `power_64` | 64×64 | 4,096 | Small/testing |
| `temp_128`, `power_128` | 128×128 | 16,384 | Medium scale |
| `temp_320`, `power_320` | 320×320 | 102,400 | Large scale |
| `temp_512`, `power_512` | 512×512 | 262,144 | Very large |

### File Format
- **Temperature files**: Initial temperature values (°C) for each grid cell
- **Power files**: Power dissipation values (W) for each grid cell
- **Format**: One floating-point value per line, row-major order

## 🔧 Building Requirements

- **C++ compiler**: g++, clang++, or MSVC
- **Standards**: C++98 or later
- **Platform**: Cross-platform (Linux, Windows, macOS)

## ⚡ Performance Notes

- **Large expansions**: Use `--quiet` flag for datasets >1000×1000
- **Memory usage**: ~8×(output_size²) bytes during generation
- **Verification**: Can be skipped with `--no-verify` for trusted operations

## 🐛 Troubleshooting

**Generator build fails**:
```bash
# Check for C++ compiler
which g++  # Linux/macOS
where g++  # Windows
```

**Memory errors during generation**:
- Reduce expansion factor or use progressive expansion
- Example: 64→256→1024 instead of direct 64→1024

**File format issues**:
- Ensure input files contain exactly `size²` values
- Values should be separated by whitespace/newlines

---

*Part of the Rodinia Benchmark Suite - Data generation utilities*
