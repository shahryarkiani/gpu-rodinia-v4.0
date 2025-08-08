# CFD Data Generation

This directory contains tools and datasets for the Computational Fluid Dynamics (CFD) benchmark in the Rodinia suite.

## Overview

The CFD benchmark simulates 3D unstructured Euler equations for fluid flow using a finite volume method. It requires mesh data files containing node coordinates and connectivity information for the computational domain.

## Tools Available

### Data Generator
- **`cfd_gen.py`** - Python script to generate synthetic CFD mesh data
- **`gen_data.sh`** - Batch script to generate multiple dataset sizes

### Sample Datasets
- **`cfd.domn.97K`** - 97,000 element mesh (~15MB)
- **`cfd.domn.100K`** - 100,000 element mesh (~16MB)
- **`fvcorr.domn.097K`** - Alternative 97K mesh format (~22MB)
- **`fvcorr.domn.193K`** - 193,000 element mesh (~44MB)
- **`missile.domn.0.2M`** - 200,000 element missile geometry (~52MB)

## Data Format

CFD mesh files use the following format:
```
<number_of_elements>
<element_1_data>
<element_2_data>
...
<element_n_data>
```

Each element line contains:
```
<density> <node1_id> <node2_id> <node3_id> <node4_id> <coord1_x> <coord1_y> <coord1_z> <coord2_x> <coord2_y> <coord2_z> <coord3_x> <coord3_y> <coord3_z> <coord4_x> <coord4_y> <coord4_z>
```

Where:
- **density**: Fluid density value (0.0 to 1.0)
- **node_ids**: Four node indices forming a tetrahedral element
- **coordinates**: 3D coordinates (x,y,z) for each of the 4 nodes

### Generated Data Properties
- **Node IDs**: Sequential integers within valid range
- **Coordinates**: Random values between -0.5 and 0.5
- **Density**: Random values between 0.0 and 1.0
- **Connectivity**: Each element has 4 nodes (tetrahedral)

## Usage

### Python Data Generator

Generate single dataset:
```bash
python cfd_gen.py -s <size>

# Examples
python cfd_gen.py -s 1000      # Generate 1K element mesh
python cfd_gen.py -s 100000    # Generate 100K element mesh
python cfd_gen.py -s 500000    # Generate 500K element mesh
```

### Batch Generation

Generate multiple standard sizes:
```bash
./gen_data.sh
```

This creates datasets with the following sizes:
- **Small**: 1K, 5K, 10K, 25K elements
- **Medium**: 50K, 75K, 97K, 100K elements  
- **Large**: 150K, 193K, 200K, 250K elements
- **Very Large**: 500K, 750K, 1M, 2M elements

### File Naming Convention

Generated files follow the pattern: `cfd.domn.<size>`
- `cfd.domn.1K` - 1,000 elements
- `cfd.domn.100K` - 100,000 elements
- `cfd.domn.1M` - 1,000,000 elements

## CFD Benchmark Integration

### Building CFD Benchmark
```bash
cd ../../cuda/cfd
make clean
make
```

### Performance Tips

- **Small datasets** (< 10K): Good for development and debugging
- **Medium datasets** (10K-200K): Optimal for most GPU architectures
- **Large datasets** (> 500K): Requires high-end GPUs with sufficient memory
- **Pre-computed flux variants**: Generally faster than redundant computation

## File Size Estimates

| Elements | File Size | Memory Usage | Recommended GPU |
|----------|-----------|--------------|-----------------|
| 1K       | ~80KB     | ~1MB         | Any CUDA GPU    |
| 10K      | ~800KB    | ~10MB        | 1GB+ VRAM      |
| 100K     | ~16MB     | ~100MB       | 2GB+ VRAM      |
| 500K     | ~80MB     | ~500MB       | 4GB+ VRAM      |
| 1M       | ~160MB    | ~1GB         | 8GB+ VRAM      |
| 2M       | ~320MB    | ~2GB         | 16GB+ VRAM     |

## Credits

The original CFD OpenMP and CUDA codes were developed by Andrew Corrigan at George Mason University and are based on the AIAA-2009-4001 paper. The code has been integrated into Rodinia under Rodinia's license with permission.
