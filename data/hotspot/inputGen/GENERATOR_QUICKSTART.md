# Hotspot Generator - One Command Solution

## Quick Start

```bash
# Build the tool
cd data/hotspot/inputGen
make

# One command to expand AND verify!
./hotspot_generator 64 5 temp_64 power_64 temp_320 power_320
```

That's it! One command does everything:
- ✅ Expands 64×64 → 320×320 
- ✅ Automatically verifies the expansion
- ✅ Shows you the exact hotspot command to run next

## Basic Usage

```bash
./hotspot_generator <input_size> <multiplier> <temp_in> <power_in> <temp_out> <power_out>
```

## Common Examples

### Create Popular Sizes
```bash
# 64×64 → 256×256 (4x expansion)
./hotspot_generator 64 4 temp_64 power_64 temp_256 power_256

# 512×512 → 1536×1536 (3x expansion)
./hotspot_generator 512 3 temp_512 power_512 temp_1536 power_1536

# 64×64 → 640×640 (10x expansion)
./hotspot_generator 64 10 temp_64 power_64 temp_640 power_640
```

### Chain for Massive Datasets
```bash
# Step 1: 64 → 512 (8x)
./hotspot_generator 64 8 temp_64 power_64 temp_512 power_512

# Step 2: 512 → 4096 (8x) - Creates 64x total expansion!
./hotspot_generator 512 8 temp_512 power_512 temp_4096 power_4096
```

## Options

| Option | Description | Example |
|--------|-------------|---------|
| `--quiet` | Minimal output | `./hotspot_generator 64 5 temp_64 power_64 temp_320 power_320 --quiet` |
| `--no-verify` | Skip verification | `./hotspot_generator 64 5 temp_64 power_64 temp_320 power_320 --no-verify` |
| `--verify-only` | Only verify existing files | `./hotspot_generator 64 5 temp_64 power_64 temp_320 power_320 --verify-only` |

## Performance Tips

### For Large Datasets (>2048×2048)
```bash
# Use --quiet for faster processing
./hotspot_generator 1024 8 temp_1024 power_1024 temp_8192 power_8192 --quiet

# Skip verification if you trust the process
./hotspot_generator 1024 10 temp_1024 power_1024 temp_10240 power_10240 --no-verify
```

### For Development/Testing
```bash
# Only verify existing files
./hotspot_generator 64 5 temp_64 power_64 temp_320 power_320 --verify-only
```