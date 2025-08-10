# Hybridsort (CUDA)

GPU-accelerated hybrid sorting of floats combining bucket sort and merge sort. Uses 1024-way bucketing followed by parallel merge passes. Optimized for sorting large arrays of floating-point values in [0,1) range.

## Quick Start
```bash
make VERIFY=Y TIMER=Y
./hybridsort r                 # sort 4M random floats
./hybridsort input.txt         # sort floats from file
```

## Build Options

### Required
- CUDA toolkit
- Update `Makefile` CC_FLAGS for your GPU architecture:
  ```makefile
  CC_FLAGS = -arch=sm_20  # Change sm_20 to match your GPU
  ```

### Compile-time Flags
Pass as `make FLAG=Y`:
- `VERIFY`: Enable CPU verification (runs qsort & compares results)
- `TIMER`: Print detailed timing breakdown
- `OUTPUT`: Save input data to `hybridoutput.txt`

### Performance Tuning
Pass as `make PARAM=VALUE`:
- `HISTO_WG_SIZE_0=N`: Histogram kernel work-group size (default: 96)
- `BUCKET_WG_SIZE_0=N`: First bucket sort kernel size (default: 128)
- `BUCKET_WG_SIZE_1=N`: Second bucket sort kernel size (default: 32)
- `MERGE_WG_SIZE_0=N`: First merge kernel size (default: 256)
- `MERGE_WG_SIZE_1=N`: Second merge kernel size (default: 208)

Example with tuning:
```bash
make clean
make VERIFY=Y TIMER=Y BUCKET_WG_SIZE_0=128 MERGE_WG_SIZE_0=256
```

## Usage

### Random Data
```bash
./hybridsort r
```
Generates and sorts 2^22 (4,194,304) random floats in [0,1).

### File Input
```bash
./hybridsort <input_file>
```

### Input Format
- Space/newline separated floats
- No header or count prefix
- Values ideally in [0,1) range
- Example: `0.5 0.1 0.8 0.3`

### Sample Data
Generate test data using scripts in `../../data/hybridsort/`:
```bash
cd ../../data/hybridsort/
python hybrid_gen.py 1000000 1M    # creates 1M.txt with 1M floats
cd -
./hybridsort ../../data/hybridsort/1M.txt
```

## Algorithm Details

### Pipeline
1. **Histogram** (GPU)
   - 1024-bin histogram to analyze distribution
   - Uses texture memory for input

2. **Bucket Assignment** (CPU + GPU)
   - CPU: Compute pivot points from histogram
   - GPU: Assign elements to 1024 buckets (DIVISIONS)
   - GPU: Compute bucket offsets

3. **Sort** (GPU)
   - Bucket sort with float4 alignment
   - Multi-pass parallel merge sort
   - Uses texture memory for lookups

### Memory Usage
- Input size: N floats
- GPU memory: ~2N + padding
- Additional GPU buffers for indices and offsets
- CPU memory: ~2N for verification when VERIFY=Y

### Performance Notes
- Runs each sort 4 times (TEST=4) and reports average
- Best for large datasets (default 4M elements)
- Optimized for [0,1) range; other ranges auto-scaled
- Uses texture cache for better memory access patterns

## Output
- Reports input size and GPU iterations
- With TIMER=Y: Shows upload, bucket, merge, download times
- With VERIFY=Y: Shows CPU time and validation result
- With OUTPUT=Y: Writes input to hybridoutput.txt

## Known Limitations
- Input size must fit in GPU memory
- Performance sensitive to value distribution
- May need tuning for different GPU architectures