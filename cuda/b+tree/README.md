# B+Tree CUDA Implementation

## Overview
This is a GPU-accelerated B+Tree implementation using CUDA. It performs point searches and range queries on large datasets using parallel GPU processing.

## Building the Program

### Standard Build
```bash
make clean
make
```

### Custom Work Group Size
Adjustable work group size for kernels 1 & 2: RD_WG_SIZE_0_0 RD_WG_SIZE_0
```bash
make clean
make KERNEL_DIM="-DRD_WG_SIZE_0=256"
```

## Running the Program

### Command Format
```bash
./b+tree.out file <data_file> command <command_file>
```

### Examples
```bash
# Run with sample 1M dataset
./b+tree.out file ../../data/b+tree/mil.txt command ../../data/b+tree/command.txt

# Run with 1K dataset
./b+tree.out file ../../data/b+tree/my_file.txt command ../../data/b+tree/command.txt

# Using generated datasets (after running data generation)
./b+tree.out file ../../data/b+tree/btree1M.txt command ../../data/b+tree/command1M.txt
```

## Command File Operations

The command file supports the following GPU operations:
- **`k <count>`** - Perform `<count>` point searches (exact value lookups)
- **`j <count> <range_size>`** - Perform `<count>` range searches with specified range size

### Interactive Commands
If running without a command file, you can use these interactive commands:
- `i <x>` - Insert value x
- `f <x>` - Find value x  
- `p <x>` - Print path to key x
- `d <x>` - Delete key x
- `t` - Print the B+ tree
- `l` - Print leaf keys
- `v` - Toggle verbose output
- `r <start> <end>` - Find range from start to end
- `x <value>` - Run single search for value on GPU and CPU
- `y <a> <b>` - Run single range search for range a-b on GPU and CPU
- `q` - Quit

## Data Files

### Input Data Format
Data files should have this format:
```
<total_count>
<number_1>
<number_2>
...
<number_n>
```

### Command File Format
```
k <num_point_searches>
j <num_range_searches> <range_size>
```

### Generating Test Data
Navigate to the data directory to generate test datasets:
```bash
cd ../../data/b+tree
python btreegen.py 1000000 1M    # Creates btree1M.txt and command1M.txt
./gen_data.sh                    # Generates multiple dataset sizes
```

## Output

Results are written to `output.txt` in the execution directory, containing:
- Search operation results
- Timing information
- Query statistics
- Performance metrics

## Performance Notes

- Maximum query count is limited to 65,535 (CUDA block limit)
- Point searches scale as min(data_size/100, 50,000)
- Range searches are typically half the number of point searches
- Work group size can be tuned for different GPU architectures