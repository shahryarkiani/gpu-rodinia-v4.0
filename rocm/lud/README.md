# LU Decomposition (LUD) - CUDA Implementation

TODO: Fix floating point verification to like 3 decimal penalty maybe

CUDA implementation of LU matrix decomposition with parallel block-wise algorithm.

## Build Options

### Requirements
- CUDA toolkit
- GCC/Clang for host code
- Default compute capability: sm_20 (modify in cuda/Makefile)

### Compilation Methods
```bash
# Standard CUDA build
make

# Alternative Clang build (with timing)
make clang

# Clean build files
make clean
```

### Build-time Configuration
Modify cuda/Makefile or pass as make variables:

1. **GPU Architecture**
```bash
# In Makefile (NVCCFLAGS):
-arch=sm_20    # Change for your GPU

# Or via command line:
make NVCCFLAGS="-arch=sm_75"
```

2. **Block Size** (default: 16×16)
```bash
# Via command line:
make KERNEL_DIM="-DRD_WG_SIZE_0=32"    # Set to 32×32
make KERNEL_DIM="-DRD_WG_SIZE_0_0=64"  # Set to 64×64
```

3. **Compiler Flags**
```bash
# Enable timing measurements
make DEFS="-DTIMING"

# Enable GPU timer
make DEFS="-DGPU_TIMER"
```

## Running the Program

### Basic Usage
```bash
./cuda/lud_cuda [-v] [-s matrix_size|-i input_file]
```

### Command Line Options
- `-s <size>`: Generate and use random matrix of given size
  ```bash
  ./cuda/lud_cuda -s 256      # 256×256 random matrix
  ./cuda/lud_cuda -s 1024     # 1024×1024 random matrix
  ```

- `-i <file>`: Use matrix from input file
  ```bash
  ./cuda/lud_cuda -i ../../data/lud/256.dat
  ./cuda/lud_cuda -i ../../data/lud/512.dat
  ```

- `-v`: Enable verification (compare with CPU result)
  ```bash
  ./cuda/lud_cuda -s 256 -v   # Random matrix with verification
  ```

### Example Run Commands
```bash
# Quick test with small matrix
./cuda/lud_cuda -s 64 -v

# Performance test with large matrix
./cuda/lud_cuda -s 2048

# Verify with sample data
./cuda/lud_cuda -i ../../data/lud/512.dat -v
```

### Input Data Requirements
- Matrix size must be multiple of block size (default 16)
- Input file format:
  ```
  N        # Matrix size (first line)
  a11 a12 ... a1N
  a21 a22 ... a2N
  ...
  aN1 aN2 ... aNN
  ```

## Output and Verification

### Standard Output
- Reports working group (block) size
- Shows matrix size and source (file/random)
- Displays execution time in milliseconds

### With Verification (-v)
```
WG size of kernel = 16 X 16
Matrix size = 256
Verification: PASS
Time consumed(ms): 123.45
```

### With Timing (if compiled with -DTIMING)
```
Exec: 98.76    # Kernel execution time in ms
```

## Performance Notes

### Memory Considerations
- Matrix size N requires:
  - GPU memory: N² × sizeof(float)
  - Additional CPU memory if verification enabled
  - Shared memory per block: BLOCK_SIZE × BLOCK_SIZE × sizeof(float)

### Optimal Performance
- Best for matrices ≥ 256×256
- Block size should match GPU architecture
- Recommended sizes: 64, 128, 256, 512, 1024, 2048
- Larger matrices benefit more from GPU acceleration

### Known Limitations
- Matrix size must be multiple of block size
- Very large matrices may require GPU memory management
- Performance varies with matrix properties

## Directory Structure
- `cuda/`
  - `lud.cu`: Main program
  - `lud_kernel.cu`: CUDA kernels
  - `Makefile`: Build configuration
- `common/`: Shared utilities
- `base/`: CPU reference implementation
- `tools/`: Matrix generation tools