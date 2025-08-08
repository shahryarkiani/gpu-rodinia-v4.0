# Heartwall CUDA Implementation

## Overview

GPU-accelerated cardiac motion tracking benchmark that processes ultrasound video data to track heart wall movement using CUDA kernels for parallel computation.

## Building

### Standard Build
```bash
make clean
make
```

### Adjustable Work Group Size
```bash
make clean
make KERNEL_DIM="-DRD_WG_SIZE_0=256"
```

### Output for Validation
```bash
make clean
make OUTPUT=Y
```

## Running the Benchmark

### Command Format
```bash
./heartwall <input_video_file> <number_of_frames>
```

### Example Usage
```bash
# Basic execution with 20 frames
./heartwall ../../data/heartwall/test.avi 20

# Process more frames for extended analysis
./heartwall ../../data/heartwall/test.avi 50
```

## Required Data Files

The benchmark requires video data files that must be downloaded separately:

- **`test.avi`** - Test video file containing ultrasound cardiac imaging data
- **`input.txt`** - Configuration file with tracking parameters

**Data Location**: Download from [GitHub release](https://github.com/huygnguyen04/gpu-rodinia-v4.0/releases/tag/heartwall-sample-data) and place in `../../data/heartwall/`

## Algorithm Details

The heartwall benchmark performs:

1. **Frame Processing**: Extracts and processes video frames sequentially
2. **Motion Tracking**: Tracks endocardium and epicardium boundaries
3. **Parallel Computation**: Uses CUDA kernels for efficient GPU processing
4. **Output Generation**: Produces tracking results and motion statistics

## Performance Notes

- **Frame Count**: Second parameter controls processing duration
- **Work Group Size**: Adjustable via KERNEL_DIM for performance tuning
- **Memory Requirements**: Scales with video resolution and frame count
- **GPU Compatibility**: Requires CUDA-capable GPU with sufficient memory