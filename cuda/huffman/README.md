## PAVLE: CUDA Huffman Encoder (VLC)

CUDA-accelerated variable-length (Huffman) encoder with a CPU reference for correctness and timing comparisons.

### Key files
- `main_test_cu.cu`: entry point, timing, and end-to-end pipeline
- `vlc_kernel_sm64huff.cu`: GPU VLC encoder kernel
- `scan.cu`, `pack_kernels.cu`: prefix-sum and packing helpers (used in testing/validation)
- `cpuencode.cpp/.h`: CPU reference encoder
- `huffTree.h`, `hist.cu`, `load_data.h`: build codebook from input (GPU histogram + CPU tree)
- `Makefile`: build rules (NVCC)

### Requirements
- CUDA toolkit (update `CUDA_INCLUDEPATH` in `Makefile` for your install)
- A GPU supporting the specified arch (`-arch=sm_75` by default; adjust for your GPU)
- C++ compiler for host code

### Build
```bash
make pavle   # or simply: make
```
Useful options:
- `make clean`
- `make TESTING=1` to add `-DTESTING` at compile time
- `make CACHECWLUT=1` to add `-DCACHECWLUT`

### Usage
```bash
./pavle <input_file>
```
Example dataset:
```bash
./pavle ../../data/huffman/test1024_H2.206587175259.in
```
Note: An input file is required. The file is read as raw bytes. Internally, encoding operates on 32-bit words and processes 4 byte-symbols per word; non-multiple-of-4 sizes are truncated to the largest multiple of 4.

### What it does
1) Reads input and builds a 256-symbol Huffman codebook: GPU histogram (`hist.cu`) → CPU tree (`huffTree.h`).
2) Runs CPU encoder for reference and reports encoded byte size/time.
3) Runs GPU encoder and reports time. With `TESTING`, performs prefix-sum/packing and verifies GPU vs CPU output.

### Compile-time flags (see `parameters.h` and `Makefile`)
- `TESTING`: enables extra buffers, packing, and verification
- `CACHECWLUT`: cache codeword LUT in shared memory (affects shared memory size)
- `DPT`: data dwords per thread (default 4)
- `NUM_SYMBOLS`: fixed at 256

### Output
- Console timing for CPU/GPU and encoded size
- With `TESTING`, verification results (and optional debug prints if enabled)
- Stats logs may be emitted via `stats_logger` as text files in the CWD
