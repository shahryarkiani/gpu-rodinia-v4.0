# DWT2D Data Directory

## Overview

The DWT2D benchmark performs 2D Discrete Wavelet Transform on image data using various image sizes and compression algorithms. This directory contains sample BMP images and tools for generating additional test data.

## Available Data Files

### Sample Images
- **`example.bmp`** - Small example test image
- **`rgb.bmp`** - Large RGB test image (~3MB, 1024x1024)
- **`4.bmp`** to **`128.bmp`** - more test image

### Generated Images (after running gen_data.sh)
- **`4.bmp`** to **`1024.bmp`** - Test images from 4x4 to 1024x1024 pixels

## Data Generation

### Quick Start
```bash
./gen_data.sh
```

This generates BMP test images of various sizes (4x4, 8x8, 16x16, 32x32, 64x64, 128x128, 192x192, 256x256, 512x512, 1024x1024) for comprehensive testing.

### Generation Tools
- **`gen_data.sh`** - Main generation script
- **`inputGen/`** - Contains source code and utilities for BMP generation

## Data Format

- **Image Format**: BMP (24-bit RGB bitmap images)
- **Content**: Checkerboard patterns optimized for wavelet transform testing
- **Sizes**: Square images with power-of-2 and common test dimensions
- **Purpose**: Input images for wavelet decomposition and reconstruction algorithms

## Usage

1. Generate test data: `./gen_data.sh`
2. Refer to implementation-specific README files for build and run instructions

## Performance Testing

Different image sizes serve different testing purposes:

- **Small** (4x4 to 32x32): Algorithm verification and debugging
- **Medium** (64x64 to 256x256): Standard benchmarking  
- **Large** (512x512 to 1024x1024): Performance stress testing and memory evaluation

The wavelet transform computational complexity scales with image size, making this range suitable for comprehensive GPU performance evaluation.
