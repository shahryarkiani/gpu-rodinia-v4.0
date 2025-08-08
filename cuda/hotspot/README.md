# Hotspot CUDA Implementation

This directory contains the **CUDA implementation** of the Hotspot thermal simulation benchmark. The program simulates 2D thermal behavior in processor chips using GPU acceleration.

## About Hotspot

Hotspot simulates **thermal diffusion** in processor chips by:
- Computing temperature evolution over time using 2D finite difference methods
- Modeling heat transfer between adjacent grid cells
- Supporting configurable chip dimensions and thermal properties
- Using CUDA for massively parallel computation

## Building the Simulator

### Prerequisites
- **CUDA Toolkit** (10.0 or later)
- **NVIDIA GPU** with CUDA support
- **Compatible C++ compiler** (gcc, clang, or MSVC)

### Build Commands

**Custom work group size:**
```bash
make clean
make KERNEL_DIM="-DRD_WG_SIZE_0=16"
```

**Available targets:**
- `release` - Optimized build
- `debug` - Debug build with symbols
- `enum` - Device emulation mode (deprecated)
- `clean` - Remove built files

### Work Group Configuration

The CUDA kernel uses configurable work group sizes:
- **Default**: 16×16 threads per block
- **Configurable**: Set via `RD_WG_SIZE_0` compile flag
- **Format**: Square blocks only (RD_WG_SIZE_0 × RD_WG_SIZE_0)

## Running the Simulation

### Command Syntax
```bash
./hotspot <grid_size> <pyramid_height> <sim_time> <temp_file> <power_file> <output_file>
```

### Parameters
- **`grid_size`**: Grid dimensions (N for N×N grid)
- **`pyramid_height`**: Computational pyramid height (1-4 recommended)
- **`sim_time`**: Number of simulation iterations
- **`temp_file`**: Initial temperature input file
- **`power_file`**: Power dissipation input file
- **`output_file`**: Results output filename

### Example Usage

**Quick test (64×64 grid):**
```bash
./hotspot 64 2 60 ../../data/hotspot/inputGen/temp_64 ../../data/hotspot/inputGen/power_64 result_64.out
```

**Medium scale (320×320 grid):**
```bash
./hotspot 320 2 100 ../../data/hotspot/inputGen/temp_320 ../../data/hotspot/inputGen/power_320 result_320.out
```

**Large scale (512×512 grid):**
```bash
./hotspot 512 2 200 ../../data/hotspot/inputGen/temp_512 ../../data/hotspot/inputGen/power_512 result_512.out
```

**High precision (higher pyramid):**
```bash
./hotspot 320 4 150 ../../data/hotspot/inputGen/temp_320 ../../data/hotspot/inputGen/power_320 result_320_precise.out
```

### Provided Example
The `run` script contains a ready-to-use example:
```bash
./run
# Executes: ./hotspot 512 2 2 ../../data/hotspot/temp_512 ../../data/hotspot/power_512 output.out
```

## Input Data Requirements

Input files must be in the correct format:
- **Temperature file**: Initial temperature (°C) for each grid cell
- **Power file**: Power dissipation (W) for each grid cell
- **Format**: One floating-point value per line, row-major order
- **Size**: Must contain exactly `grid_size²` values

**Generate input data:**
```bash
cd ../../data/hotspot/inputGen
make
./hotspot_generator 64 5 temp_64 power_64 temp_320 power_320
```

## Output Format

The output file contains:
- **Format**: Index and temperature pairs
- **Content**: `<index> <temperature>` per line
- **Order**: Row-major indexing (0 to grid_size²-1)
- **Units**: Temperature in degrees Celsius

## Performance Tuning

### Work Group Size Optimization
```bash
# Test different work group sizes
make clean && make KERNEL_DIM="-DRD_WG_SIZE_0=8"   # 8×8 blocks
make clean && make KERNEL_DIM="-DRD_WG_SIZE_0=16"  # 16×16 blocks  
make clean && make KERNEL_DIM="-DRD_WG_SIZE_0=32"  # 32×32 blocks
```

### Grid Size Guidelines
- **Small grids** (≤128): Lower pyramid heights (1-2)
- **Medium grids** (256-512): Standard pyramid heights (2-3)
- **Large grids** (≥1024): Higher pyramid heights (3-4)

### Iteration Count
- **Testing**: 60-100 iterations
- **Benchmarking**: 200+ iterations
- **Convergence**: Monitor temperature changes between iterations

## 🐛 Troubleshooting

**CUDA compilation errors:**
```bash
# Check CUDA installation
nvcc --version

# Verify GPU compatibility
nvidia-smi
```

**Runtime errors:**
- Ensure input files exist and have correct format
- Verify grid_size matches input file dimensions
- Check available GPU memory for large grids

**Performance issues:**
- Try different work group sizes
- Reduce pyramid height for memory-constrained GPUs
- Use smaller grid sizes for initial testing

## 📈 Benchmarking

**Standard benchmark configurations:**
```bash
# Small scale
./hotspot 64 2 100 temp_64 power_64 result_64.out

# Medium scale  
./hotspot 320 2 200 temp_320 power_320 result_320.out

# Large scale
./hotspot 512 4 500 temp_512 power_512 result_512.out
```

**Performance metrics to track:**
- Execution time (total and per iteration)
- GPU utilization percentage
- Memory bandwidth utilization
- Temperature convergence rate

---

*Part of the Rodinia Benchmark Suite - CUDA accelerated thermal simulation*
