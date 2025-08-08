# Hotspot3D Data Generation Guide

## Overview
Hotspot3D extends thermal simulation to **3 dimensions**, modeling heat flow through chip layers (Z-axis). This guide shows how to generate 3D datasets of any size.

## Understanding Hotspot3D Data

### **Data Structure**
- **Format**: `rows × cols × layers` values (one per line)
- **Indexing**: `index = row*cols + col + layer*rows*cols`
- **Example**: 64×64×8 = 32,768 values total

### **Command Format**
```bash
./3D <rows/cols> <layers> <iterations> <powerFile> <tempFile> <outputFile>
```

### **Current Available Data**
| Dataset | Grid Size | Layers | Total Values | File Size |
|---------|-----------|---------|--------------|-----------|
| `temp_64x8`, `power_64x8` | 64×64 | 8 | 32,768 | ~350KB |
| `temp_512x2`, `power_512x2` | 512×512 | 2 | 524,288 | ~5.5MB |
| `temp_512x4`, `power_512x4` | 512×512 | 4 | 1,048,576 | ~11MB |
| `temp_512x8`, `power_512x8` | 512×512 | 8 | 2,097,152 | ~22MB |

## Building the Generator

```bash
cd data/hotspot3D
make
```

This creates the `hotspot3D_generator` executable with three powerful modes.

## Generation Modes

### **Mode 1: Convert 2D → 3D**

Transform existing 2D hotspot data into 3D by replicating across layers with thermal gradients.

#### Usage
```bash
./hotspot3D_generator 2d-to-3d <grid_size> <layers> <temp_2d> <power_2d> <temp_3d> <power_3d>
```

#### Examples
```bash
# Convert 2D 64×64 to 3D 64×64×8
./hotspot3D_generator 2d-to-3d 64 8 ../hotspot/temp_64 ../hotspot/power_64 temp_64x8 power_64x8

# Convert 2D 512×512 to 3D 512×512×16  
./hotspot3D_generator 2d-to-3d 512 16 ../hotspot/temp_512 ../hotspot/power_512 temp_512x16 power_512x16

# Create ultra-thin chip simulation (many layers)
./hotspot3D_generator 2d-to-3d 256 32 ../hotspot/temp_256 ../hotspot/power_256 temp_256x32 power_256x32
```

#### What It Does
- **Temperature**: Adds thermal gradient across layers (each layer +0.1°C)
- **Power**: Varies power distribution per layer (layers have 80%-120% of base power)
- **Physics**: Simulates realistic chip heating patterns

### **Mode 2: Expand 3D Grid**

Increase spatial resolution while maintaining layer structure.

#### Usage
```bash
./hotspot3D_generator expand-grid <input_size> <layers> <multiplier> <temp_in> <power_in> <temp_out> <power_out>
```

#### Examples
```bash
# Expand 64×64×8 to 256×256×8 (4× spatial resolution)
./hotspot3D_generator expand-grid 64 8 4 temp_64x8 power_64x8 temp_256x8 power_256x8

# Expand 512×512×4 to 2048×2048×4 (4× spatial, same layers)
./hotspot3D_generator expand-grid 512 4 4 temp_512x4 power_512x4 temp_2048x4 power_2048x4

# Create massive dataset: 64×64×8 → 1024×1024×8 (16× expansion)
./hotspot3D_generator expand-grid 64 8 16 temp_64x8 power_64x8 temp_1024x8 power_1024x8
```

#### What It Does
- **Spatial Expansion**: Each cell becomes `multiplier × multiplier` block in X-Y plane
- **Layer Preservation**: Z-axis structure remains unchanged
- **Data Replication**: Same thermal patterns at higher resolution

### **Mode 3: Change Layer Count**

Modify the number of layers while preserving grid size.

#### Usage
```bash
./hotspot3D_generator change-layers <grid_size> <input_layers> <output_layers> <temp_in> <power_in> <temp_out> <power_out>
```

#### Examples
```bash
# Double layers: 512×512×8 → 512×512×16
./hotspot3D_generator change-layers 512 8 16 temp_512x8 power_512x8 temp_512x16 power_512x16

# Reduce layers: 512×512×8 → 512×512×4 (downsampling)
./hotspot3D_generator change-layers 512 8 4 temp_512x8 power_512x8 temp_512x4 power_512x4

# Create ultra-layered chip: 64×64×8 → 64×64×64
./hotspot3D_generator change-layers 64 8 64 temp_64x8 power_64x8 temp_64x64 power_64x64
```

#### What It Does
- **Layer Interpolation**: Intelligently maps between different layer counts
- **Thermal Gradients**: Adds realistic inter-layer variations
- **Up/Downsampling**: Works for both increasing and decreasing layers

## Advanced Workflows

### **Workflow 1: Complete 2D → Large 3D Pipeline**
```bash
# Step 1: Convert small 2D to 3D
./hotspot3D_generator 2d-to-3d 64 8 ../hotspot/temp_64 ../hotspot/power_64 temp_64x8 power_64x8

# Step 2: Expand spatially
./hotspot3D_generator expand-grid 64 8 8 temp_64x8 power_64x8 temp_512x8 power_512x8

# Step 3: Add more layers
./hotspot3D_generator change-layers 512 8 16 temp_512x8 power_512x8 temp_512x16 power_512x16

# Result: 64×64 2D → 512×512×16 3D (total expansion: 8×8×2 = 128×)
```

### **Workflow 2: Multi-Resolution 3D Family**
```bash
# Base: Create 128×128×8 from 2D
./hotspot3D_generator 2d-to-3d 128 8 ../hotspot/temp_128 ../hotspot/power_128 temp_128x8 power_128x8

# Family member 1: 256×256×8
./hotspot3D_generator expand-grid 128 8 2 temp_128x8 power_128x8 temp_256x8 power_256x8

# Family member 2: 512×512×8  
./hotspot3D_generator expand-grid 128 8 4 temp_128x8 power_128x8 temp_512x8 power_512x8

# Family member 3: 128×128×16 (more layers)
./hotspot3D_generator change-layers 128 8 16 temp_128x8 power_128x8 temp_128x16 power_128x16
```

### **Workflow 3: Performance Testing Suite**
```bash
# Small test case
./hotspot3D_generator 2d-to-3d 32 4 ../hotspot/temp_32 ../hotspot/power_32 temp_32x4 power_32x4

# Medium test case  
./hotspot3D_generator 2d-to-3d 128 8 ../hotspot/temp_128 ../hotspot/power_128 temp_128x8 power_128x8

# Large test case
./hotspot3D_generator expand-grid 128 8 4 temp_128x8 power_128x8 temp_512x8 power_512x8

# Extreme test case (requires significant GPU memory)
./hotspot3D_generator expand-grid 512 8 4 temp_512x8 power_512x8 temp_2048x8 power_2048x8
```

## Usage Examples

### **Example 1: Basic 3D Simulation**
```bash
# Create dataset
./hotspot3D_generator 2d-to-3d 64 8 ../hotspot/temp_64 ../hotspot/power_64 temp_64x8 power_64x8

# Run simulation
cd ../cuda/hotspot3D
./3D 64 8 100 ../../data/hotspot3D/temp_64x8 ../../data/hotspot3D/power_64x8 output_64x8.out
```

### **Example 2: High-Resolution 3D**
```bash
# Create high-res dataset
./hotspot3D_generator expand-grid 64 8 8 temp_64x8 power_64x8 temp_512x8 power_512x8

# Run simulation (requires more GPU memory)
cd ../cuda/hotspot3D  
./3D 512 8 50 ../../data/hotspot3D/temp_512x8 ../../data/hotspot3D/power_512x8 output_512x8.out
```

### **Example 3: Multi-Layer Analysis**
```bash
# Create datasets with different layer counts
./hotspot3D_generator change-layers 128 8 4 temp_128x8 power_128x8 temp_128x4 power_128x4
./hotspot3D_generator change-layers 128 8 16 temp_128x8 power_128x8 temp_128x16 power_128x16
./hotspot3D_generator change-layers 128 8 32 temp_128x8 power_128x8 temp_128x32 power_128x32

# Compare thermal behavior across layer counts
cd ../cuda/hotspot3D
./3D 128 4 100 ../../data/hotspot3D/temp_128x4 ../../data/hotspot3D/power_128x4 output_128x4.out
./3D 128 16 100 ../../data/hotspot3D/temp_128x16 ../../data/hotspot3D/power_128x16 output_128x16.out
./3D 128 32 100 ../../data/hotspot3D/temp_128x32 ../../data/hotspot3D/power_128x32 output_128x32.out
```

## Options

| Option | Description | Example |
|--------|-------------|---------|
| `--quiet` | Minimal output | `./hotspot3D_generator 2d-to-3d 64 8 temp_64 power_64 temp_64x8 power_64x8 --quiet` |

## Performance & Memory Notes

### **File Sizes (Approximate)**
| Grid Size | Layers | Values | File Size Each | Total |
|-----------|---------|---------|----------------|-------|
| 64×64 | 8 | 32,768 | 350 KB | 700 KB |
| 128×128 | 8 | 131,072 | 1.4 MB | 2.8 MB |
| 256×256 | 8 | 524,288 | 5.6 MB | 11.2 MB |
| 512×512 | 8 | 2,097,152 | 22.4 MB | 44.8 MB |
| 1024×1024 | 8 | 8,388,608 | 89.6 MB | 179.2 MB |
| 512×512 | 32 | 8,388,608 | 89.6 MB | 179.2 MB |

### **Memory Requirements**
- **Generation**: ~2× output file size in RAM
- **Hotspot3D**: Grid size² × layers × 4 bytes GPU memory
- **Example**: 512×512×8 needs ~1 GB GPU memory

### **Processing Time**
- **2D→3D**: Fast (mostly I/O bound)
- **Grid Expansion**: Scales with output size
- **Layer Changes**: Scales with layer count

## Physics Insights

### **Thermal Gradients**
The generator adds realistic thermal variations:
- **Inter-layer temperature gradients**: Heat dissipation through chip thickness
- **Power distribution variations**: Different layers have different power densities
- **Realistic thermal physics**: Based on actual chip thermal behavior

### **Use Cases**
1. **Chip Design**: Model heat in multi-layer processors
2. **Cooling Analysis**: Study thermal management strategies  
3. **Performance Research**: Compare 2D vs 3D thermal effects
4. **GPU Benchmarking**: Test thermal simulation performance

## Error Handling

Common issues and solutions:
- **File not found**: Check paths to input files
- **Out of memory**: Reduce dataset size or increase system RAM  
- **Invalid parameters**: Verify grid sizes and layer counts are positive
- **GPU memory**: Large 3D datasets may exceed GPU capacity

## Best Practices

1. **Start Small**: Test workflow with small datasets first
2. **Chain Operations**: Build complex datasets step-by-step
3. **Verify Results**: Check file sizes match expected values
4. **Monitor Resources**: Watch RAM/GPU usage for large datasets
5. **Save Intermediates**: Keep intermediate files for debugging

**The Hotspot3D generator enables creating thermal simulation datasets of virtually any 3D size and resolution!** 🎯 