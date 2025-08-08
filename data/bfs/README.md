# BFS Graph Data Generation

This directory contains tools for generating graph datasets for the Breadth-First Search (BFS) benchmark in the Rodinia suite.

## Overview

The BFS benchmark requires graph data in a specific format. This directory provides two equivalent graph generators:
- **C++ version** (`graphgen.cpp`) - Original implementation
- **Python version** (`graphgen.py`) - Python port with additional features

Both generators create random graphs with configurable parameters for testing BFS algorithms on different graph sizes and structures.

## Tools Available

### Graph Generators
- **`graphgen.cpp`** - C++ graph generator (requires compilation)
- **`graphgen.py`** - Python graph generator (ready to use)
- **`graphgen`** - Pre-compiled C++ binary (if available)

### Batch Generation Scripts
- **`gen_dataset.sh`** - Generates multiple datasets using C++ version
- **`gen_dataset_python.sh`** - Generates multiple datasets using Python version

### Build Tools
- **`Makefile`** - For compiling the C++ generator

## Building the C++ Generator

```bash
make
```

Or manually:
```bash
g++ -std=c++0x -fopenmp -o graphgen graphgen.cpp
```

## Graph Format

The generated graphs use the Rodinia BFS format:

```
<num_nodes>
<start_edge_index_1> <num_edges_1>
<start_edge_index_2> <num_edges_2>
...
<start_edge_index_n> <num_edges_n>

<source_node>

<total_edges>
<destination_1> <weight_1>
<destination_2> <weight_2>
...
```

## Usage

### C++ Generator

```bash
# Basic usage
./graphgen <num_nodes> [filename_suffix]

# Examples
./graphgen 1000                # Creates graph1000.txt
./graphgen 1000 test           # Creates graphtest.txt
./graphgen 50000 50k           # Creates graph50k.txt
```

### Python Generator

```bash
# Basic usage
python graphgen.py <num_nodes> [filename_suffix] [options]

# Examples
python graphgen.py 1000                           # Creates graph1000.txt
python graphgen.py 1000 test                      # Creates graphtest.txt
python graphgen.py 1000 --max-edges 6             # More edges per node
python graphgen.py 1000 --min-weight 5 --max-weight 20  # Custom weights
```

#### Python Generator Options

- `--min-edges N` - Minimum edges per node (default: 2)
- `--max-edges N` - Maximum edges per node (default: 4)  
- `--min-weight N` - Minimum edge weight (default: 1)
- `--max-weight N` - Maximum edge weight (default: 10)

### Batch Generation

Generate multiple standard dataset sizes:

```bash
# Using C++ generator
./gen_dataset.sh

# Using Python generator  
./gen_dataset_python.sh
```

Both scripts generate graphs with these sizes:
- 1K, 2K, 4K, 8K, 16K, 32K, 64K nodes
- 128K, 256K, 512K nodes  
- 1M, 2M, 4M, 8M, 16M nodes

## Graph Properties

### Default Parameters
- **Minimum nodes:** 20
- **Edges per node:** 2-4 (randomly chosen)
- **Edge weights:** 1-10 (randomly chosen)
- **Graph type:** Undirected (edges added in both directions)

### Characteristics
- Graphs may contain **multiple edges** between the same nodes
- Graphs may contain **self-loops**
- Graphs are **not guaranteed to be connected**
- Average edges per node: ~6 (2 × max_init_edges × 2 directions)

## Generated Files

Each generator creates files named `graph<suffix>.txt` where suffix can be:
- The number of nodes (default)
- A custom string provided as argument

### Example Datasets
```bash
graph1k.txt      # 1,024 nodes
graph16k.txt     # 16,384 nodes  
graph1M.txt      # 1,048,576 nodes
graph8M.txt      # 8,388,608 nodes
```

## Performance Considerations

### Memory Usage
- **C++ version:** More memory efficient for large graphs
- **Python version:** Easier to use but uses more memory

### Generation Time
- Small graphs (< 100K nodes): Both versions are fast
- Large graphs (> 1M nodes): C++ version is significantly faster

### Recommended Usage
- **Development/Testing:** Use Python version for flexibility
- **Large-scale datasets:** Use C++ version for performance
- **Automated pipelines:** Use batch scripts

## Graph Statistics

When generating graphs, both tools display:
- Number of nodes
- Total number of edges
- Average edges per node

## File Size Estimates

Approximate output file sizes:
- 1K nodes: ~50KB
- 16K nodes: ~800KB  
- 1M nodes: ~50MB
- 8M nodes: ~400MB

## Integration with BFS Benchmark

These graph files can be used directly with the Rodinia BFS benchmark:

```bash
# Navigate to BFS CUDA implementation
cd ../../cuda/bfs

# Build BFS benchmark
make

# Run with generated graph
./bfs ../../data/bfs/graph1M.txt
```

## Troubleshooting

### Common Issues

1. **"Invalid argument" error:** Ensure num_nodes ≥ 20
2. **Compilation errors:** Check C++11 support (`-std=c++0x`)
3. **Permission denied:** Make scripts executable (`chmod +x *.sh`)
4. **Memory issues:** For very large graphs (>16M nodes), ensure sufficient RAM

### Validation

To verify generated graphs:
1. Check file format matches specification
2. Verify edge count consistency
3. Ensure all node references are within valid range

## Technical Details

### Algorithm
1. For each node, randomly choose 2-4 outgoing edges
2. For each edge, randomly select destination and weight
3. Add reciprocal edge to maintain undirected property
4. Output in Rodinia BFS format with adjacency list structure

### Random Number Generation
- **C++ version:** Uses TR1 linear congruential engine + standard rand()
- **Python version:** Uses Python's random module with equivalent distribution

Both generators should produce statistically similar graphs for the same parameters.
