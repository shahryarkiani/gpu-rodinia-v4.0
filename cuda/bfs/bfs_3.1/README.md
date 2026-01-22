# BFS CUDA Implementation

GPU-accelerated Breadth-First Search using CUDA, based on the HiPC'07 paper "Accelerating Large Graph Algorithms on the GPU using CUDA".

**Credits:** Original code by Pawan Harish and P. J. Narayanan (IIIT-Hyderabad), included in Rodinia under Rodinia's license.

## Directory Structure

```
bfs_3.1/
├── src/              # Standard BFS implementation
│   ├── bfs.cu
│   ├── kernel.cu
│   ├── kernel2.cu
│   └── Makefile
└── profiling/        # NVTX-instrumented version for profiling
    ├── bfs_nvtx.cu
    ├── kernel.cu
    ├── kernel2.cu
    └── Makefile
```

## Configuration

### CUDA Paths (in `common/make.config`)

Before building, verify these paths in `../../../common/make.config`:

```bash
CUDA_DIR = /usr/local/cuda              # Change if needed
SDK_DIR = /usr/local/cuda/samples/      # Change if needed
NV_OPENCL_DIR = /usr/local/cuda         # Change if needed
```

### GPU Architecture (profiling only)

For the profiling build, edit `profiling/Makefile`:

```makefile
GPU  ?= a100        # Change if needed (e.g., v100, a100, h100)
ARCH ?= sm_80       # Change if needed (sm_70, sm_80, sm_90, etc.)
```

Find your GPU's compute capability: https://developer.nvidia.com/cuda-gpus

## Running

### Command Format

```bash
./bfs.out <graph_file>
```

### Examples

```bash
# Standard version
cd src
./bfs.out ../../../data/bfs/legacy_graphs/graph1k.txt
./bfs.out ../../../data/bfs/rmat_graphs/graph1M_sparse.txt

# Profiling version
cd profiling
./bfs_nvtx_a100.out ../../../data/bfs/rmat_graphs/graph1M_sparse.txt
```

## Input Graph Format (Rodinia CSR)

```
<num_nodes>
<start_edge_idx> <num_edges>  # For each node
...

<source_node>

<total_edges>
<dest> <weight>  # For each edge
...
```

See `../../../data/bfs/README.md` for graph generation and dataset information.

## Graph Datasets

### Pre-Generated Datasets

Download at: https://virginia.box.com/s/gvyjdq8qt9ei0ojyd3itokngq7pr2al2

### Generate Your Own

```bash
cd ../../../data/bfs

# RMAT graphs (Graph500-style, scales 1K-32M vertices)
cd rmat_graphs
./rmat_gen_sparse.sh    # EF=8
./rmat_gen_dense.sh     # EF=64

# Real-world graphs (SNAP, DIMACS-10)
cd dataset_graphs/convert_script
python3 convert_dataset_to_csr.py <input> <output> --undirected --relabel --format rodinia

# Legacy random graphs (1K-16M nodes)
cd legacy_graphs
./gen_dataset.sh        # C++ version
./gen_dataset_python.sh # Python version
```

## Output

**Standard version (`-DTIMING` enabled):**
- Memory allocation time
- Host-to-device transfer time
- Kernel execution time (per iteration)
- Device-to-host transfer time
- Total execution time
- Distance results for all nodes

**Profiling version:**
- Same as standard, plus NVTX markers visible in Nsight Systems

## Profiling with NVTX

The `profiling/` version includes NVTX ranges for detailed GPU analysis:

```bash
cd profiling
make

# Profile with Nsight Systems
nsys profile --stats=true ./bfs_nvtx_a100.out ../../../data/bfs/rmat_graphs/graph1M_sparse.txt

# View results
nsys-ui report1.nsys-rep
```

**NVTX markers track:**
- File I/O operations
- Memory allocation (host & device)
- Host-to-device transfers
- Kernel launches (Kernel 1 & Kernel 2)
- Device-to-host transfers
- Individual BFS iterations

## Algorithm

**Level-synchronous BFS:**
1. **Kernel 1**: Process current frontier, update distances, mark new nodes
2. **Kernel 2**: Update frontier mask for next iteration
3. Repeat until frontier is empty

**Thread organization:**
- Max 512 threads per block
- One thread per node
- Dynamic block calculation based on graph size

## Performance Tips

- Use graphs with moderate connectivity for best performance
- RMAT sparse (EF=8) graphs work well for most GPUs
- Ensure sufficient GPU memory for large graphs (>8M vertices)
- Use profiling version to identify bottlenecks

## Verification

Compare results with CPU BFS or verify:
- All reachable nodes have valid distances (≥ 0)
- Unreachable nodes have distance -1
- Source node has distance 0
- Path distances satisfy shortest-path property

## References

Pawan Harish and P. J. Narayanan, "Accelerating Large Graph Algorithms on the GPU using CUDA," *HiPC 2007*.