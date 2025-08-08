# Hotspot3D Data Directory

This directory contains input data generation tools and datasets for the **Hotspot3D** thermal simulation benchmark, which extends thermal modeling to **3 dimensions** with chip layers.

## Directory Overview

```
hotspot3D/
├── hotspot3D_generator      # Compiled generator executable
├── hotspot3D_generator.cpp  # Generator source code  
├── Makefile                 # Build configuration
├── HOTSPOT3D_GUIDE.md       # Detailed generator guide
└── [3D datasets]            # Pre-generated 3D input files
```

## About Hotspot3D Data

Hotspot3D simulates **3D thermal behavior** in processor chips using grids that represent:
- **Temperature distribution** across X×Y surface and Z layers (°C)
- **Power dissipation** values for each 3D grid cell (W)
- **Layer-wise heat transfer** between chip levels

### 3D Data Format
- **Structure**: `rows × cols × layers` values
- **Indexing**: `index = row*cols + col + layer*rows*cols`
- **File format**: One floating-point value per line
- **Example**: 64×64×8 = 32,768 total values

### Naming Convention
Files follow the pattern: `temp_<size>x<layers>` and `power_<size>x<layers>`
- `temp_64x8` = 64×64 grid with 8 layers (temperature)
- `power_512x4` = 512×512 grid with 4 layers (power)

## 🛠️ Generating 3D Data

### Build the Generator
```bash
# Build the 3D generator tool
make
```

### Generation Modes

**1. Convert 2D to 3D:**
```bash
./hotspot3D_generator 2d-to-3d <grid_size> <layers> <temp_2d> <power_2d> <temp_3d> <power_3d>
```

**2. Expand 3D grid size:**
```bash
./hotspot3D_generator expand-grid <input_size> <layers> <multiplier> <temp_in> <power_in> <temp_out> <power_out>
```

**3. Change layer count:**
```bash
./hotspot3D_generator change-layers <grid_size> <input_layers> <output_layers> <temp_in> <power_in> <temp_out> <power_out>
```

### Example Usage

**Convert 2D hotspot data to 3D:**
```bash
./hotspot3D_generator 2d-to-3d 64 8 ../hotspot/inputGen/temp_64 ../hotspot/inputGen/power_64 temp_64x8 power_64x8
```

**Expand existing 3D data:**
```bash
./hotspot3D_generator expand-grid 64 8 4 temp_64x8 power_64x8 temp_256x8 power_256x8
```

**Add more layers to existing data:**
```bash
./hotspot3D_generator change-layers 512 4 8 temp_512x4 power_512x4 temp_512x8 power_512x8
```

## 📊 Available 3D Datasets

| Files | Grid Size | Layers | Total Values | File Size |
|-------|-----------|---------|--------------|-----------|
| `temp_64x8`, `power_64x8` | 64×64 | 8 | 32,768 | ~350KB |
| `temp_512x2`, `power_512x2` | 512×512 | 2 | 524,288 | ~5.5MB |
| `temp_512x4`, `power_512x4` | 512×512 | 4 | 1,048,576 | ~11MB |
| `temp_512x8`, `power_512x8` | 512×512 | 8 | 2,097,152 | ~22MB |

### Data Characteristics
- **Temperature files**: Initial 3D temperature distribution (°C)
- **Power files**: 3D power dissipation values (W)
- **Layer gradients**: Automatic thermal variation between layers
- **Power scaling**: Layer-appropriate power distribution

## ⚙️ Generator Options

**Quiet mode** (minimal output):
```bash
./hotspot3D_generator <mode> <args...> --quiet
```

**Performance considerations:**
- Large 3D datasets require significant memory
- Generation time scales with total volume (rows × cols × layers)
- File sizes can be substantial for high-resolution 3D grids

## 🔧 Building Requirements

- **C++ compiler**: g++, clang++, or compatible
- **Standards**: C++11 or later
- **Platform**: Cross-platform (Linux, Windows, macOS)

## 🐛 Troubleshooting

**Generator build fails:**
```bash
# Check for C++ compiler with C++11 support
g++ --version
```

**Memory errors during generation:**
- Reduce grid size or layer count for testing
- Use progressive generation for very large datasets

**File format issues:**
- Ensure input files contain exactly `size² × layers` values
- Verify 2D source files are valid before 3D conversion

## 💡 Usage Tips

**Data size estimation:**
- Memory usage: ~4 bytes per value during generation
- 512×512×8 dataset: ~8MB storage, ~32MB RAM during generation

**Recommended workflow:**
1. Start with small datasets (64×64×8)
2. Test with 2D-to-3D conversion first
3. Scale up using expand-grid mode
4. Add layers as needed for specific simulations

---

*Part of the Rodinia Benchmark Suite - 3D thermal simulation data utilities*
