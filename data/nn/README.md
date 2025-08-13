# Nearest Neighbor (NN) Dataset

This directory contains hurricane tracking data used by the CUDA Nearest Neighbor benchmark. The application finds the k-nearest neighbors for a given latitude/longitude query point.

## Dataset Format

### Record Structure
Each line in the `.db` files represents one hurricane record with the following format:
```
YYYY MM DD HH NN NAME      LAT   LON   SPD  PRS
1992  3 22  0  7 ALBERTO  66.5  79.2  129  899
```
Where:
- `YYYY`: Year (1950-2005)
- `MM`: Month (1-12)
- `DD`: Day (1-28)
- `HH`: Hour (0, 6, 12, or 18)
- `NN`: Record number
- `NAME`: Hurricane name
- `LAT`: Latitude (7-70 degrees)
- `LON`: Longitude (0-358 degrees)
- `SPD`: Wind speed (10-165 knots)
- `PRS`: Pressure (0-900)

### Files
- `cane4_[0-3].db`: Database files containing hurricane records (each ~10K records)
- `filelist.txt`: List of database files to process

## Data Generation

The `inputGen/` directory contains tools to generate synthetic hurricane datasets:

### Generator Usage
```bash
cd inputGen
make
./hurricanegen <num_hurricanes> <num_files>
```

Requirements:
- `num_hurricanes` should be a multiple of 1024
- `num_files` should evenly divide `num_hurricanes`

Example:
```bash
./hurricanegen 4096 4  # Generates 4 files with 1024 records each
```

This creates:
- Data files: `cane4k_4_[0-3].db`
- File list: `list4k_4.txt`

## Using the Dataset

The NN CUDA application takes these arguments:
```bash
nearestNeighbor filelist.txt -r <num_results> -lat <latitude> -lng <longitude>
```

Example:
```bash
./nearestNeighbor filelist.txt -r 5 -lat 30 -lng 90
```

This finds the 5 nearest hurricane records to the point (30°N, 90°W).

### Additional Options
- `-r [int]`: Number of records to return (default: 10)
- `-lat [float]`: Query latitude (default: 0)
- `-lng [float]`: Query longitude (default: 0)
- `-q`: Quiet mode (suppress output)
- `-t`: Print timing information
