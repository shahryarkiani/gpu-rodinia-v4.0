### MUMmerGPU datasets

This directory provides reference and query datasets for the CUDA MUMmerGPU application. The app aligns a set of query reads against a reference genome.

### What the app expects
- **Inputs**: `reference.fna` and `query.fna` in FASTA format
- **Run syntax**: `mummergpu [options] reference.fna query.fna`

Example (from the included run script):
```bash
bin/mummergpu ../../data/mummergpu/NC_003997.fna ../../data/mummergpu/NC_003997_q100bp.fna > NC_003997.out
```

### Files in this directory
- **NC_003997.fna**: Bacillus anthracis str. Ames complete genome FASTA. Used as a full-size reference.
- **NC_003997.20k.fna**: Smaller subset of the NC_003997 reference for quick tests.
- **NC_003997_q25bp.50k.fna**: 50,000 synthetic reads of length 25 bp sampled from `NC_003997.fna` (multi‑FASTA).
- **NC_003997_q100bp.fna**: Synthetic reads of length 100 bp sampled from `NC_003997.fna` (large file; stress testing) - available on https://github.com/huygnguyen04/gpu-rodinia-v4.0/releases/tag/mummergpu-sample-data
- **genreads.py**: Utility to generate synthetic reads from a reference.

### File formats
- **Reference (`*.fna`)**
  - Single FASTA record with a header line beginning with `>` followed by one or more sequence lines.
- **Queries (`*_qXXbp*.fna`)**
  - Multi‑FASTA where each read has a header and a sequence line. When created by `genreads.py`, headers look like `>rid123 start-end` and the sequence line contains the read of the requested length.

Example query FASTA snippet:
```text
>rid1 1-26
TAAACTGTAACGTATTGCATTTCCT
>rid2 42-67
TTCTTTAGCAGATTCCAATACTTCT
```

### Generate new query sets
Use `genreads.py` to sample fixed‑length reads from a reference.

Usage:
```bash
python genreads.py <reference.fna> <read_length> <num_reads> [-s <seed>]
```

Examples:
```bash
# 200k reads of 100 bp from the full reference
python genreads.py NC_003997.fna 100 200000 > NC_003997_q100bp.200k.fna

# 50k reads of 25 bp from the smaller reference
python genreads.py NC_003997.20k.fna 25 50000 > NC_003997_q25bp.50k.from20k.fna
```

Notes:
- `genreads.py` samples uniform random start positions; `-s` sets the RNG seed for reproducibility.
- The script was originally written for Python 2. If using Python 3, minor syntax updates may be required, or run it with a Python 2 interpreter.

### Recommended pairings
- **Quick sanity check**: `NC_003997.20k.fna` + `NC_003997_q25bp.50k.fna`
- **Full benchmark**: `NC_003997.fna` + `NC_003997_q100bp.fna` (large memory/time)

### Where this data is used
The CUDA app in `gpu-rodinia-v4.0/cuda/mummergpu/` consumes these files. See the `run` helper script there for an example invocation and additional options (e.g., `-l` minimal match length).


