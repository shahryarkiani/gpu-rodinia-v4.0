# BFS Graph Data Generation

Tools for generating and converting graph datasets for the Rodinia BFS benchmark in CSR (Compressed Sparse Row) format.

## Pre-Generated Datasets

**Download:** Pre-generated graph datasets are available at [https://virginia.box.com/s/gvyjdq8qt9ei0ojyd3itokngq7pr2al2](https://virginia.box.com/s/gvyjdq8qt9ei0ojyd3itokngq7pr2al2)  
Available in both **CSR format** (ready for Rodinia) and **original format** (raw edge lists).

## Dataset Types

1. **RMAT Synthetic Graphs** (`rmat_graphs/`) - Graph500-style scalable graphs using PaRMAT [1]
2. **Real-World Graphs** (`dataset_graphs/`) - SNAP [2], DIMACS-10 [3,4], Network Repository [5]
3. **Legacy Random Graphs** (`legacy_graphs/`) - Original simple random graph generator

## 1. RMAT Synthetic Graphs

RMAT graphs mimic real-world network properties using PaRMAT [1] with Graph500 parameters `(A,B,C) = (0.57, 0.19, 0.19)`.

**Scales:** 10K, 50K, 100K, 500K, 1M, 2M, 8M, 16M, 32M vertices  
**Densities:** Sparse (EF=8) and Dense (EF=64) edge factors  
**Properties:** Undirected, no duplicates, no self-loops, sorted

### Usage

```bash
cd rmat_graphs
./rmat_gen_sparse.sh    # Generates graph1k_sparse.txt, graph1M_sparse.txt, etc.
./rmat_gen_dense.sh     # Generates graph1k_dense.txt, graph1M_dense.txt, etc.

# Manual generation
./PaRMAT_gen -nVertices 1000000 -nEdges 8000000 -a 0.57 -b 0.19 -c 0.19 \
    -sorted -noDuplicateEdges -noEdgeToSelf -undirected -output rmat_1M.txt
python3 convert_rmat_to_csr.py rmat_1M.txt graph1M.txt 0
```

## 2. Real-World Graphs

Converts graphs from SNAP [2], DIMACS-10 [3,4], and Network Repository [5].

**Supported:** cit-Patents, roadNet-CA, soc-LiveJournal1, web-Google, asia_osm, coAuthorDBLP, coPaperDBLP, nlpkkt200

### Usage

```bash
cd dataset_graphs/convert_script

# Convert single dataset
python3 convert_dataset_to_csr.py web-Google.txt.gz web-Google.csr.txt \
    --undirected --relabel --format rodinia --source 0

# Batch convert (see csr_convert_script.sh for examples)
for dataset in cit-Patents roadNet-CA soc-LiveJournal1 web-Google; do
    python3 convert_dataset_to_csr.py ${dataset}.txt.gz ${dataset}.csr.txt \
        --undirected --relabel --format rodinia --source 0
done
```

**Options:** `--undirected`, `--relabel`, `--format rodinia`, `--source N`, `--one-based`, `--skip-comments`  
**Formats:** Edge lists, `.gz`/`.bz2` compressed, 0/1-based indexing

## 3. Legacy Random Graphs

Simple random graph generator from original Rodinia suite.

**Properties:** 2-4 edges/node, weights 1-10, undirected, may have duplicates/self-loops  
**Scales:** 1K-16M nodes via batch scripts

### Usage

```bash
cd legacy_graphs
make  # Build C++ version

# Generate single graph
./graphgen 1000              # graph1000.txt
python graphgen.py 1000      # graph1000.txt
python graphgen.py 1000 --max-edges 6 --min-weight 5 --max-weight 20

# Batch generation (1K to 16M nodes)
./gen_dataset.sh             # C++ version (faster for large graphs)
./gen_dataset_python.sh      # Python version
```

## Graph Format (Rodinia CSR)

```
<num_nodes>
<start_edge_idx> <num_edges>  # For each node
...

<source_node>

<total_edges>
<dest> <weight>  # For each edge
...
```

## Troubleshooting

**RMAT:** Requires PaRMAT (https://github.com/farkhor/PaRMAT), Python 3 + NumPy, sufficient RAM for large graphs  
**Real-World:** Use `--relabel` for node ID issues, `--one-based` for 1-based indexing  
**Legacy:** Requires num_nodes ≥ 20, C++11 support, executable permissions on scripts (`chmod +x *.sh`)

## References

[1] F. Khorasani, R. Gupta, and L. N. Bhuyan, "Scalable SIMD-Efficient Graph Processing on GPUs," *PACT 2015*.

[2] J. Leskovec and A. Krevl, "SNAP Datasets: Stanford Large Network Dataset Collection," 2014. http://snap.stanford.edu/data

[3] D. A. Bader et al., "Benchmarking for Graph Clustering and Partitioning," *Encyclopedia of Social Network Analysis and Mining*, Springer, 2014.

[4] D. A. Bader et al. (eds.), *Graph Partitioning and Graph Clustering: 10th DIMACS Implementation Challenge*, AMS, 2013.

[5] R. A. Rossi and N. K. Ahmed, "The Network Data Repository," *AAAI 2015*. https://networkrepository.com

**Resources:** PaRMAT (https://github.com/farkhor/PaRMAT), DIMACS-10 (http://www.cc.gatech.edu/dimacs10/downloads.shtml), Graph500 (https://graph500.org)