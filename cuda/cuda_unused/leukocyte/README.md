# Leukocyte CUDA Implementation

## Overview

GPU-accelerated leukocyte (white blood cell) detection and tracking benchmark that processes microscopy video data to identify and track cell movement in blood vessels using CUDA kernels for parallel computation.

## Building

### Standard Build
```bash
make clean
make
```

### Output for Validation
```bash
make clean
make OUTPUT=Y
```

## Running the Benchmark

### Command Format
```bash
./CUDA/leukocyte <input_video_file> <number_of_frames>
```

### Example Usage
```bash
# Basic execution with 5 frames
./CUDA/leukocyte ../../data/leukocyte/testfile.avi 5

# Process more frames for extended analysis
./CUDA/leukocyte ../../data/leukocyte/testfile.avi 50

# Full analysis with many frames
./CUDA/leukocyte ../../data/leukocyte/testfile.avi 100
```

## Required Data Files

The benchmark requires video data files that must be downloaded separately:

- **`testfile.avi`** - Test video file containing microscopy footage of blood vessels with leukocytes

**Data Location**: Download from [GitHub release](https://github.com/huygnguyen04/gpu-rodinia-v4.0/releases/tag/leukocyte-sample-data) and place in `../../data/leukocyte/`

## Algorithm Details

The leukocyte benchmark performs:

1. **Cell Detection**: Identifies leukocytes in the first frame using gradient-based edge detection and GICOV analysis
2. **Ellipse Fitting**: Uses CUDA kernels to fit ellipses around detected cells for precise boundary detection  
3. **Cell Tracking**: Tracks detected cells across subsequent frames using motion prediction
4. **Motion Analysis**: Computes cell trajectories, velocities, and motion parameters
5. **Parallel Processing**: Utilizes GPU parallelization for computationally intensive image processing operations

## Performance Notes

- **Frame Count**: Second parameter controls how many video frames to process
- **Processing Time**: Scales with number of frames and video resolution
- **Memory Requirements**: Depends on video size and number of detected cells
- **GPU Compatibility**: Requires CUDA-capable GPU with sufficient memory for image processing
- **Output Validation**: Use OUTPUT=Y build flag to generate validation output files

## Dependencies

- **CUDA Runtime**: CUDA-capable GPU and drivers
- **AVI Library**: For video file processing (included)
- **Meschach Library**: Mathematical operations library (included)