# Gaussian Data Directory

## Overview

This directory contains test matrices for the Gaussian elimination benchmark. The matrices represent systems of linear equations in the form Ax = b, where A is an n×n coefficient matrix, x is the solution vector, and b is the right-hand side vector.

## Available Data Files

### Sample Matrices
- **`matrix3.txt`** - 3×3 matrix system (minimal test case)
- **`matrix4.txt`** - 4×4 matrix system
- **`matrix16.txt`** - 16×16 matrix system
- **`matrix208.txt`** - 208×208 matrix system
- **`matrix1024.txt`** - 1024×1024 matrix system (~4.5MB, large-scale test)

## Data Format

Each matrix file follows this structure:
```
<dimension_n>

<n×n coefficient matrix A>
<row 1: a11 a12 ... a1n>
<row 2: a21 a22 ... a2n>
...
<row n: an1 an2 ... ann>

<1×n right-hand side vector b>
<b1 b2 ... bn>

<1×n solution vector x>
<x1 x2 ... xn>
```

### Example (3×3 system):
```
3

1 1 1
1 -2 2  
1 2 -1

0 4 2

4 -2 -2
```

## Data Generation

### Using the Matrix Generator
```bash
python3 matrixGenerator.py <start> <end> <step>
```

### Examples
```bash
# Generate matrices from size 16 to 256 in steps of 4
python3 matrixGenerator.py 16 256 4

# Generate specific sizes
python3 matrixGenerator.py 64 64 1    # Single 64×64 matrix
python3 matrixGenerator.py 100 500 100  # 100×100, 200×200, ..., 500×500
```

## Data Properties

- **Coefficient values**: Random values between -0.9 and 0.9 (one decimal place)
- **Right-hand side**: Can have two decimal places for precision
- **Solution accuracy**: Pre-computed exact solutions included
- **Matrix conditioning**: Generated to have well-defined solutions

## Usage

These matrix files are used by Gaussian elimination implementations to:
- **Solve linear systems**: Forward elimination and back substitution
- **Test accuracy**: Compare computed solutions with provided exact solutions
- **Performance benchmarking**: Evaluate algorithm efficiency across different matrix sizes
- **Numerical stability**: Test behavior with various matrix conditions

## Testing Scale

Different matrix sizes serve different purposes:

- **Small** (3×3 to 16×16): Algorithm verification and debugging
- **Medium** (64×64 to 256×256): Standard benchmarking
- **Large** (512×512 to 1024×1024+): Performance stress testing and memory evaluation

The computational complexity of Gaussian elimination is O(n³), making larger matrices ideal for evaluating parallel processing performance.
