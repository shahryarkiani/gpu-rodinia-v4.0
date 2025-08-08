# Gaussian Elimination CUDA Implementation

## Overview

GPU-accelerated Gaussian elimination algorithm for solving systems of linear equations Ax = b. This implementation converts the sequential algorithm into parallel CUDA kernels using the "Fans" approach from "Foundations of Parallel Programming".

## Algorithm Description

The Gaussian elimination method solves linear equation systems through two phases:

1. **Forward Elimination**: Transform the augmented matrix [A|b] to upper triangular form
   - For each pivot row, eliminate elements below the diagonal
   - Uses three parallel "Fan" operations to replace sequential loops

2. **Back Substitution**: Solve for unknowns starting from the last equation
   - Work backwards from bottom-right to top-left
   - Each solution uses previously computed values

### Example System (n=4):
```
Equations:          Matrix Form:        Solution:
a0x + b0y + c0z + d0w = e0    [a0 b0 c0 d0] [e0]    [x]
a1x + b1y + c1z + d1w = e1    [a1 b1 c1 d1] [e1]    [y]
a2x + b2y + c2z + d2w = e2    [a2 b2 c2 d2] [e2]    [z]
a3x + b3y + c3z + d3w = e3    [a3 b3 c3 d3] [e3]    [w]
```

## Building

### Standard Build
```bash
make clean
make
```

### Adjustable Work Group Sizes
```bash
make clean
make KERNEL_DIM="-DRD_WG_SIZE_0=128 -DRD_WG_SIZE_1=16"
```

**Work Group Parameters:**
- `RD_WG_SIZE_0`: Maximum block size for 1D kernels (default: 512)
- `RD_WG_SIZE_1`: Block size for 2D kernels (default: 4, square shape)
- Total 2D threads per block = `RD_WG_SIZE_1 × RD_WG_SIZE_1`

## Running the Benchmark

### Command Format
```bash
./gaussian [options]
```

### Input Methods

#### Using Matrix Files
```bash
# Process pre-generated matrix file
./gaussian -f ../../data/gaussian/matrix4.txt

# Standard test cases
./gaussian -f ../../data/gaussian/matrix16.txt
./gaussian -f ../../data/gaussian/matrix1024.txt
```

#### Generate Internal Matrix
```bash
# Generate random n×n matrix internally
./gaussian -s 16
./gaussian -s 256
./gaussian -s 1024
```

### Command Line Options
- `-f filename`: Load matrix from file (includes exact solution for verification)
- `-s size`: Generate random matrix of specified size internally
- `-q`: Quiet mode (suppress text output)
- `-t`: Print detailed timing information
- `-h, --help`: Display help information

### Example Usage
```bash
# Small test with file input
./gaussian -f ../../data/gaussian/matrix4.txt

# Medium benchmark with internal generation
./gaussian -s 128

# Large performance test with timing
./gaussian -s 1024 -t

# Quiet mode for automated testing
./gaussian -s 512 -q
```

## Required Data Files

### Using Pre-generated Matrices
Matrix files are available in `../../data/gaussian/`:
- **`matrix3.txt`** to **`matrix1024.txt`** - Various sizes from 3×3 to 1024×1024
- **Format**: Includes coefficient matrix, right-hand side, and exact solution
- **Generation**: Use `matrixGenerator.py` in the data directory for additional sizes

### Internal Matrix Generation
- **No files required**: Use `-s size` option
- **Random values**: Generates well-conditioned matrices internally
- **Solution verification**: Computes and verifies solution accuracy

## CUDA Implementation Details

### Kernel Organization
- **Fan1 Kernel**: Partial pivot and row scaling
- **Fan2 Kernel**: Elimination below pivot (main computational kernel)
- **Back Substitution**: Sequential on GPU with parallel optimization

### Memory Management
- **Global memory**: Stores full matrix and vectors
- **Shared memory**: Used for thread collaboration within blocks
- **Memory coalescing**: Optimized access patterns for GPU efficiency
- **Data layout**: Row-major matrix storage

### Parallelization Strategy
- **Thread mapping**: Each thread handles matrix elements or rows
- **Block synchronization**: Required between elimination steps
- **Load balancing**: Work distribution optimized for GPU architecture

## Performance Characteristics

- **Computational complexity**: O(n³) for forward elimination, O(n²) for back substitution
- **Memory pattern**: Irregular access during elimination phase
- **Scalability**: Performance scales with matrix size until memory saturation
- **Bottlenecks**: Matrix size limited by GPU memory capacity

## Algorithm Applications

Gaussian elimination is fundamental to:
- **Scientific computing**: Solving physical simulation equations
- **Engineering analysis**: Structural, thermal, and fluid dynamics
- **Machine learning**: Linear regression and matrix operations
- **Computer graphics**: Transformation matrices and lighting calculations
- **Economics modeling**: Input-output analysis and optimization

## Verification

- **File input**: Compares computed solution with provided exact solution
- **Internal generation**: Verifies Ax = b using computed solution
- **Accuracy metrics**: Reports solution error and residual norms
- **Numerical stability**: Tests behavior with various matrix conditions

## Performance Testing

Different matrix sizes for various scenarios:

- **Small** (3×3 to 16×16): Algorithm verification and debugging
- **Medium** (64×64 to 256×256): Standard benchmarking
- **Large** (512×512 to 1024×1024+): Performance evaluation and memory stress testing

Larger matrices provide better GPU utilization but require more memory and longer computation time.

## Credits

Based on the algorithm from "Foundations of Parallel Programming". Originally written by Andreas Kura (1995), modified by Chong-wei Xu (1995), and adapted for CUDA by Chris Gregg (2009).
