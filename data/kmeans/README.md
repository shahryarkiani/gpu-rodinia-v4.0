# K-means Clustering Datasets

This directory contains sample datasets and tools for generating data for the k-means clustering benchmark.

## Available Datasets

### Sample Files
- `100`: Small test set with 100 objects, 34 integer features (0-255)
- `204800.txt`: ~200K objects dataset
- `819200.txt`: ~800K objects dataset
- `kdd_cup`: KDD Cup dataset format

### File Format
Each line represents one object with the following format:
```
ID feat1 feat2 feat3 ... featN
```
where:
- `ID`: Object identifier (ignored by k-means)
- `feat1` to `featN`: Feature values, either:
  - Integers in range [0, 255], or
  - Floats in range [0.0, 1.0] (for files with `-f` suffix)
- Default number of features: 34

## Data Generation

### Using the Generator
The `inputGen/` directory contains tools to generate custom datasets:

```bash
cd inputGen
make
./datagen <numObjects> [numFeatures] [-f]
```

Parameters:
- `numObjects`: Number of objects to generate (required)
- `numFeatures`: Number of features per object (optional, default: 34)
- `-f`: Generate float features [0.0-1.0] instead of integers [0-255]

Example usage:
```bash
./datagen 1000     # 1000 objects, 34 integer features
./datagen 1000 50  # 1000 objects, 50 integer features
./datagen 1000 -f  # 1000 objects, 34 float features
```

### Batch Generation
Use `gen_dataset.sh` to generate multiple datasets:
```bash
cd inputGen
./gen_dataset.sh
```
This generates datasets from 100 to 10M objects, in both integer and float formats.

### Output Files
- Integer format: `<numObjects>_<numFeatures>.txt`
- Float format: `<numObjects>_<numFeatures>f.txt`

Example: `1000_34.txt` contains 1000 objects with 34 integer features.

## Memory Requirements
Approximate file sizes:
- Each integer feature: 1-3 bytes + separator
- Each float feature: 6 bytes + separator
- Example: 1M objects × 34 features ≈ 200MB (integer) or 400MB (float)

## Notes
- Files are space-separated text format
- First column (ID) is ignored by the k-means implementation
- Integer features are uniformly distributed in [0,255]
- Float features are uniformly distributed in [0.0,1.0]
- Large datasets (>1M objects) may take significant time to generate
