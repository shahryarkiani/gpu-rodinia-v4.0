# Breadth-First Search (BFS) CUDA Implementation

## Overview
This is a GPU-accelerated implementation of Breadth-First Search (BFS) using CUDA, based on the algorithm described in the HiPC'07 paper "Accelerating Large Graph Algorithms on the GPU using CUDA". The implementation performs BFS traversal on large graphs using parallel GPU processing.

## Credits
The original BFS CUDA code was developed by Pawan Harish and P. J. Narayanan at the International Institute of Information Technology - Hyderabad (IIIT), who have given permission to include it as part of Rodinia under Rodinia's license.

## Algorithm
The implementation uses a level-synchronous BFS approach:
1. **Kernel 1**: Processes all nodes in the current frontier, updating distances and marking newly discovered nodes
2. **Kernel 2**: Updates the frontier mask for the next iteration
3. Iterates until no new nodes are discovered

## Building the Program

### Standard Build
```bash
make release
```

### Alternative Build Options
```bash
make debug          # Debug version
make clang          # Using clang compiler
make enum           # Device emulation mode
```

## Running the Program

### Command Format
```bash
./bfs.out <graph_file>
```

### Examples
```bash
# Run with sample graphs from data directory
./bfs.out ../../data/bfs/graph1k.txt
./bfs.out ../../data/bfs/graph64k.txt
./bfs.out ../../data/bfs/graph1M.txt

# Run with any compatible graph file
./bfs.out path/to/your/graph.txt
```

## Input Format

The program expects graph files in the following format:
```
<number_of_nodes>
<start_edge_index_1> <number_of_edges_1>
<start_edge_index_2> <number_of_edges_2>
...
<start_edge_index_n> <number_of_edges_n>

<source_node_id>

<total_number_of_edges>
<destination_1> <weight_1>
<destination_2> <weight_2>
...
```

### Format Details
- **Node information**: Each line contains the starting index in the edge list and the number of edges for that node
- **Source node**: The starting node for BFS traversal (typically 0)
- **Edge list**: All edges stored as destination node and weight pairs

## Output

The program outputs:
- **Progress information**: File reading, memory allocation, kernel execution details
- **Traversal statistics**: Number of kernel iterations required
- **Distance results**: Shortest distances from source to all reachable nodes
- **Timing information**: Detailed timing breakdown (when compiled with -DTIMING)

### Timing Details (Release Mode)
- Memory allocation time
- Host-to-device transfer time  
- Kernel execution time
- Device-to-host transfer time
- Total execution time

## Performance Characteristics

### Thread Organization
- **Maximum threads per block**: 512
- **Block distribution**: Automatically calculated based on graph size
- **Thread mapping**: One thread per node

### Memory Usage
- **Node data**: Graph structure and BFS state
- **Edge data**: All graph edges stored in device memory
- **Masks**: Frontier and visited node tracking

### Scalability
- Handles graphs from small (1K nodes) to very large (16M+ nodes)
- Performance scales with graph connectivity and structure
- Memory requirements: O(V + E) where V = vertices, E = edges

## Algorithm Details

### BFS State
Each node maintains:
- **Distance**: Shortest path distance from source
- **Visited**: Whether the node has been processed
- **Mask**: Whether the node is in current frontier
- **Updating mask**: Whether the node should be in next frontier

### Convergence
The algorithm terminates when no new nodes are added to the frontier, indicating all reachable nodes have been discovered.

## Data Generation

Generate test graphs using the data generation tools:
```bash
cd ../../data/bfs

# Generate single graph
python graphgen.py 1000 test

# Generate multiple standard sizes
./gen_dataset_python.sh
```

## Troubleshooting

### Common Issues
1. **File not found**: Ensure graph file path is correct
2. **Memory errors**: For very large graphs, ensure sufficient GPU memory
3. **Build errors**: Check CUDA installation and make.config settings

### Performance Tips
- Use graphs with moderate connectivity for best performance
- Very sparse or very dense graphs may not show optimal speedup
- Consider graph size vs. available GPU memory

## Technical Implementation

### Kernel Functions
- **Kernel**: Main BFS expansion kernel - processes current frontier
- **Kernel2**: Frontier update kernel - prepares next iteration

### Memory Management
- Efficient GPU memory allocation for large graphs
- Minimal host-device transfers during iteration
- Optimized data structures for GPU access patterns

## Verification

To verify correctness:
1. Compare results with CPU BFS implementation
2. Check that all reachable nodes have valid distances
3. Verify shortest path properties