# DWT2D CUDA Implementation

## Overview

GPU-accelerated 2D Discrete Wavelet Transform (DWT) implementation used in JPEG2000 image compression. This benchmark performs multi-level wavelet decomposition on images, which is one of the most computationally intensive parts of JPEG2000 encoding.

## Algorithm Description

The 2D DWT transforms an image into frequency subbands using wavelet decomposition:

1. **Horizontal Transform**: Apply 1D DWT to each row
2. **Vertical Transform**: Apply 1D DWT to each column  
3. **Multi-level Decomposition**: Recursively apply DWT to low-frequency subbands
4. **Subband Organization**: Results in LL, LH, HL, HH frequency components

### Wavelet Types
- **5/3 Transform**: Integer-to-integer reversible transform (lossless)
- **9/7 Transform**: Floating-point irreversible transform (lossy)

## Building

### Standard Build
```bash
make clean
make
```

### Output Generation
```bash
make clean
make OUTPUT=Y
```

This enables detailed output generation for validation and debugging.

## Running the Benchmark

### Command Format
```bash
./dwt2d [options] <input_image> [output_file]
```

### Command Line Options
- `-d, --dimension`: Image dimensions (e.g., `1920x1080`)
- `-c, --components`: Number of color components (default: 3)
- `-l, --level`: DWT decomposition levels (default: 3)
- `-f, --forward`: Perform forward transform
- `-r, --reverse`: Perform reverse transform  
- `-5, --53`: Use 5/3 integer transform
- `-9, --97`: Use 9/7 floating-point transform

### Example Usage
```bash
# Process 192x192 BMP image with 5/3 transform, 3 levels
./dwt2d 192.bmp -d 192x192 -f -5 -l 3

# Process large RGB image with forward transform
./dwt2d rgb.bmp -d 1024x1024 -f -5 -l 3

# Specify custom parameters
./dwt2d input.bmp -d 512x512 -c 3 -l 4 -f -9
```

### Image Processing Examples
```bash
# Small test image
./dwt2d 4.bmp -d 4x4 -f -5 -l 1

# Medium test image  
./dwt2d 64.bmp -d 64x64 -f -5 -l 2

# Large performance test
./dwt2d 1024.bmp -d 1024x1024 -f -5 -l 5
```

## Required Data Files

The benchmark processes BMP image files. Compatible formats:
- **24-bit RGB BMP**: Standard bitmap format
- **Various sizes**: 4x4 to 1024x1024+ pixels
- **Test images**: Available in `../../data/cuda_unused/dwt2d/`

Generate additional test images using:
```bash
cd ../../data/cuda_unused/dwt2d/
./gen_data.sh
```

## CUDA Implementation Details

### Kernel Organization
- **Thread blocks**: Optimized for GPU architecture
- **Shared memory**: Used for data reuse in transform operations
- **Memory coalescing**: Optimized memory access patterns
- **Multi-level processing**: Recursive decomposition on GPU

### Performance Optimizations
- **Parallel row/column processing**: Independent wavelet transforms
- **Memory hierarchy**: Efficient use of shared and global memory
- **Data layout**: Optimized for GPU memory access patterns
- **Kernel fusion**: Combined operations to reduce memory transfers

## Algorithm Applications

2D DWT is essential for:
- **JPEG2000 compression**: Core transform in the standard
- **Image processing**: Multi-resolution analysis
- **Medical imaging**: Lossless compression requirements
- **Satellite imagery**: Large-scale image compression
- **Digital cinema**: High-quality video compression

## Performance Characteristics

- **Memory pattern**: Regular strided access for transforms
- **Computation**: Intensive floating-point operations
- **Scalability**: Performance scales with image size and decomposition levels
- **Bottlenecks**: Memory bandwidth for large images

## Output Validation

When built with `OUTPUT=Y`:
- **Intermediate results**: Saved for each decomposition level
- **Coefficient visualization**: Transform coefficients output
- **Debug information**: Detailed processing statistics
- **Verification data**: For correctness checking

## Testing Recommendations

Different image sizes for various testing scenarios:

- **Small** (4x4 to 32x32): Algorithm verification
- **Medium** (64x64 to 256x256): Standard benchmarking
- **Large** (512x512 to 1024x1024+): Performance evaluation

Higher decomposition levels increase computational complexity and provide more detailed frequency analysis.

## Credits

Based on the JPEG2000 standard wavelet transform algorithms. CUDA implementation optimized for parallel GPU execution.

