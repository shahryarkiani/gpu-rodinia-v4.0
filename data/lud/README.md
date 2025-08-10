# LU Decomposition (LUD) Test Data

This directory contains sample matrices and tools for generating test data for the LU Decomposition benchmark.

## Available Datasets

Pre-generated matrices in various sizes:
- Small: `64.dat` (64×64)
- Medium: `128.dat`, `256.dat`, `512.dat` (128×128 to 512×512)
- Large: `1024.dat`, `2048.dat` (1024×1024 to 2048×2048)

For each size N, three files are provided:
- `N.dat`: Input matrix A
- `l-N.dat`: Reference L matrix (lower triangular)
- `u-N.dat`: Reference U matrix (upper triangular)

## File Format

### Main Matrix (N.dat)
```
N           # Matrix size (first line)
a11 a12 ... # Matrix elements (N×N floats)
a21 a22 ...
...
```

### L/U Matrices (l-N.dat, u-N.dat)
```
l11 l12 ... # Matrix elements (N×N floats)
l21 l22 ...
...
```

Properties:
- Space-separated floating-point values
- L is lower triangular with diagonal=1.0
- U is upper triangular
- A = L × U

## Data Generation

### Using the Generator
```bash
make            # Build generator
./lud_gen N    # Generate NxN matrices

# Examples
./lud_gen 128  # Generate 128×128 matrices
./lud_gen 512  # Generate 512×512 matrices
```

### Memory Requirements
- Each value is a float (4 bytes) plus whitespace
- Total size ≈ N² × 15 bytes (all three files)
- Examples:
  - 128×128 ≈ 440KB total
  - 1024×1024 ≈ 28MB total
  - 2048×2048 ≈ 112MB total

### Makefile Targets
```bash
make           # Build generator
make generate  # Generate common sizes (64-1024)
make test     # Generate small test sizes (16,32)
make clean    # Remove generator and all data
make clean-data # Remove only data files
```

## Notes
- Matrices are randomly generated but mathematically valid for LU decomposition
- Values are uniformly distributed between 0 and 1
- Generator ensures numerical stability
- Large matrices may take significant time to generate
