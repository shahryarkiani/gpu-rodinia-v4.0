# B+Tree Data Directory

This directory contains test data and utilities for the B+Tree benchmark in the Rodinia suite.

## Contents

### Data Generation Tools
- **`btreegen.py`** - Python script to generate sequential test data and command files
- **`gen_data.sh`** - Shell script that generates multiple dataset sizes automatically

### Sample Data Files
- **`btree1M.txt`** - Pre-generated dataset with 1,000,000 sequential numbers (1M entries)
- **`btree1K.txt`** - Pre-generated dataset with 1,000 sequential numbers (1K entries)

## Data Format

### Data Files
The data files follow this format:
```
<total_count>
<number_1>
<number_2>
...
<number_n>
```

For example, a file with 1000 numbers would start with:
```
1000
0
1
2
3
...
```

### Command Files
Command files specify the operations to perform on the B+Tree:
```
k <num_point_searches>
j <num_range_searches> <range_size>
```

Where:
- `k` specifies point searches (exact value lookups)
- `j` specifies range searches with a given range size

## Generating New Data

### Using the Python Generator
```bash
python btreegen.py <size> <name_suffix>
```

Examples:
```bash
python btreegen.py 1000 1k      # Creates btree1k.txt and command1k.txt
python btreegen.py 10000 10k    # Creates btree10k.txt and command10k.txt
python btreegen.py 1000000 1M   # Creates btree1M.txt and command1M.txt
```

### Using the Shell Script
```bash
./gen_data.sh
```

This generates datasets of various sizes: 1K, 10K, 100K, 1M, 2M, 5M, and 10M entries.

## Generated Files

When using the data generator, you'll get pairs of files:
- **`btree<suffix>.txt`** - The actual data (sequential numbers)
- **`command<suffix>.txt`** - The commands to execute on the B+Tree

The number of search operations scales with data size:
- Point searches: min(size/100, 50,000)
- Range searches: half the number of point searches
- Range size: max(size/1000, 100)

## Usage

These data files are used by the B+Tree benchmark to test insertion, search, and range query performance on GPU implementations.
