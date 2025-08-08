# SRAD CUDA Implementation

## Overview

SRAD (Speckle Reducing Anisotropic Diffusion) is a diffusion method for ultrasonic and radar imaging applications based on partial differential equations (PDEs). It removes locally correlated noise (speckles) without destroying important image features, commonly used in medical imaging preprocessing.

## Algorithm Description

SRAD consists of several computational stages:
1. **Image extraction** - Load and prepare image data
2. **Iterative processing** - Multiple stages per iteration:
   - Preparation kernel
   - Reduction kernel  
   - Statistics computation
   - Diffusion computation (stages 1 & 2)
3. **Image compression** - Final output processing

The sequential dependency between stages requires synchronization after each stage since each operates on the entire image.

## SRAD Variants

### SRAD_v1
- **Input**: Processes real image data (image.pgm)
- **GPU utilization**: More computation on GPU (initializations, reductions)
- **Image generation**: Expands original image by concatenating parts
- **Best for**: Real image processing workflows

### SRAD_v2  
- **Input**: Uses randomized synthetic data
- **Memory optimization**: Better use of GPU shared memory (scratchpad)
- **Performance**: Optimized kernel implementations
- **Best for**: Performance benchmarking and testing

## Building

### Standard Build
```bash
# Build both versions
make clean
make

# Build specific version
cd srad_v1/ && make
cd srad_v2/ && make
```

### Adjustable Work Group Size
```bash
# SRAD_v2 supports customizable work group sizes
cd srad_v2/
make clean
make KERNEL_DIM="-DRD_WG_SIZE_0=16"
```

**Work Group Notes:**
- Kernels use square thread block shapes
- `RD_WG_SIZE_0` defines one dimension
- Total threads per block = `RD_WG_SIZE_0 × RD_WG_SIZE_0`
- GPU implementation requires dimensions divisible by 16

## Running the Benchmarks

### SRAD_v1 (Real Image Processing)
```bash
cd srad_v1/
./srad <iterations> <saturation_coeff> <rows> <columns>

# Example - process 502x458 image with 100 iterations
./srad 100 0.5 502 458
```

**Parameters:**
- `iterations`: Number of diffusion iterations (integer > 0)
- `saturation_coeff`: Lambda diffusion coefficient (float > 0, typically 0.5)
- `rows`: Image height (integer > 0)
- `columns`: Image width (integer > 0)

### SRAD_v2 (Synthetic Data)
```bash
cd srad_v2/
./srad <rows> <cols> <y1> <y2> <x1> <x2> <lambda> <iterations>

# Example - 128x128 domain with speckle region 0-31
./srad 128 128 0 31 0 31 0.5 2

# Large scale example
./srad 2048 2048 0 127 0 127 0.5 2
```

**Parameters:**
- `rows, cols`: Domain dimensions
- `y1, y2`: Y-coordinates of speckle region
- `x1, x2`: X-coordinates of speckle region  
- `lambda`: Diffusion coefficient (typically 0.5)
- `iterations`: Number of diffusion steps

## Required Data Files

### SRAD_v1
Requires `image.pgm` file in the source directory. The application expands this base image to create larger test images.

### SRAD_v2
No external data files required - generates synthetic speckled images internally.

## Performance Characteristics

- **Memory Pattern**: Global memory bandwidth intensive
- **Synchronization**: Requires kernel-level synchronization between stages
- **Scalability**: Performance scales with image size until GPU saturation
- **Optimization**: Benefits from shared memory usage (especially v2)

## Algorithm Applications

SRAD is commonly used as a preprocessing stage in:
- **Medical imaging**: Ultrasound speckle reduction
- **Radar imaging**: Noise removal while preserving edges
- **Heart wall tracking**: Part of the larger Heart Wall application suite
- **General denoising**: PDE-based image filtering

## Credits

Based on the research paper: Y. Yu, S. Acton, "Speckle reducing anisotropic diffusion," IEEE Transactions on Image Processing 11(11)(2002) 1260-1270.