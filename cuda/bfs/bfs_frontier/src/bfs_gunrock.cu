// Compile: nvcc -O3 -std=c++17 -arch=sm_80 bfs_gunrock.cu -o bfs_gunrock
// Run:     ./bfs_gunrock <rodinia_csr_graph.txt>

#include <cuda_runtime.h>
#include <cstdio>
#include <cstdlib>
#include <cstdint>
#include <cstring>
#include <vector>
#include <string>
#include <fstream>
#include <iostream>
#include <algorithm>
#include <limits>

#define CUDA_CHECK(x) do { cudaError_t e=(x); if (e!=cudaSuccess){ \
  fprintf(stderr,"CUDA %s:%d: %s\n",__FILE__,__LINE__,cudaGetErrorString(e)); \
  std::exit(1);} } while(0)

static constexpr int   TPB   = 512;      // threads per block
static constexpr float ALPHA = 15.0f;    // Ligra heuristic params
static constexpr float BETA  = 24.0f;

static constexpr int   DEG_SMALL_MAX = 32;     // degree bucket thresholds
static constexpr int   DEG_MED_MAX   = 1024;

// ---------------- Bitset helpers ----------------
__device__ __forceinline__ bool bit_test_and_set(uint32_t* __restrict__ bits, int idx) {
    uint32_t mask = 1u << (idx & 31);
    uint32_t* word = &bits[idx >> 5];
    uint32_t old = atomicOr(word, mask);
    return (old & mask) == 0; // true if previously 0
}
__device__ __forceinline__ bool bit_is_set(const uint32_t* __restrict__ bits, int idx) {
    return (bits[idx >> 5] & (1u << (idx & 31))) != 0;
}

// ---------------- Kernels ----------------

// frontier[0]=source; *frontier_size=1
__global__ void init_frontier(int* frontier, int* frontier_size, int source) {
    if (blockIdx.x==0 && threadIdx.x==0) { frontier[0]=source; *frontier_size=1; }
}

// Compute sum of degrees for a frontier
__global__ void sum_frontier_degrees(const int* __restrict__ frontier, int fsz,
                                     const int* __restrict__ row, unsigned long long* __restrict__ out_sum) {
    unsigned long long local = 0;
    for (int i = blockIdx.x*blockDim.x + threadIdx.x; i < fsz; i += blockDim.x*gridDim.x) {
        int v = frontier[i];
        local += (unsigned long long)(row[v+1] - row[v]);
    }
    atomicAdd(out_sum, local);
}

// Sum degrees for arbitrary vertex list (next frontier)
__global__ void sum_vertices_degrees(const int* __restrict__ verts, int nverts,
                                     const int* __restrict__ row, unsigned long long* __restrict__ out_sum) {
    unsigned long long local = 0;
    for (int i = blockIdx.x*blockDim.x + threadIdx.x; i < nverts; i += blockDim.x*gridDim.x) {
        int v = verts[i];
        local += (unsigned long long)(row[v+1] - row[v]);
    }
    atomicAdd(out_sum, local);
}

// Degree bucketing: split frontier into small/med/large queues
__global__ void bucket_by_degree(const int* __restrict__ frontier, int fsz,
                                 const int* __restrict__ row,
                                 int* __restrict__ smallQ, int* __restrict__ medQ, int* __restrict__ largeQ,
                                 int* __restrict__ smallN, int* __restrict__ medN, int* __restrict__ largeN) {
    for (int i = blockIdx.x*blockDim.x + threadIdx.x; i < fsz; i += blockDim.x*gridDim.x) {
        int v = frontier[i];
        int deg = row[v+1] - row[v];
        if (deg < DEG_SMALL_MAX)      smallQ[atomicAdd(smallN,1)] = v;
        else if (deg < DEG_MED_MAX)   medQ  [atomicAdd(medN,  1)] = v;
        else                          largeQ[atomicAdd(largeN,1)] = v;
    }
}

// Push: small bucket (thread-per-vertex)
__global__ void bfs_push_small(
    const int* __restrict__ row, const int* __restrict__ col,
    const int* __restrict__ smallQ, const int* __restrict__ smallN,
    int* __restrict__ nextF, int* __restrict__ nextF_sz,
    uint32_t* __restrict__ visited, int* __restrict__ dist, int level)
{
    int n = *smallN;
    for (int idx = blockIdx.x*blockDim.x + threadIdx.x; idx < n; idx += blockDim.x*gridDim.x) {
        int v = smallQ[idx];
        int beg = row[v], end = row[v+1];
        for (int e = beg; e < end; ++e) {
            int u = col[e];
            if (bit_test_and_set(visited, u)) {
                dist[u] = level + 1;
                int pos = atomicAdd(nextF_sz, 1);
                nextF[pos] = u;
            }
        }
    }
}

// Push: medium bucket (warp-per-vertex) with **grid-stride over warps**
__global__ void bfs_push_medium(
    const int* __restrict__ row, const int* __restrict__ col,
    const int* __restrict__ medQ, const int* __restrict__ medN,
    int* __restrict__ nextF, int* __restrict__ nextF_sz,
    uint32_t* __restrict__ visited, int* __restrict__ dist, int level)
{
    const int n = *medN;

    // global warp id & total warps
    const int lanes_per_warp = 32;
    const int lane           = threadIdx.x & (lanes_per_warp - 1);
    const int warps_per_block= blockDim.x / lanes_per_warp;
    const int warp_in_block  = threadIdx.x / lanes_per_warp;
    int global_warp          = blockIdx.x * warps_per_block + warp_in_block;
    int total_warps          = gridDim.x * warps_per_block;

    for (int warp_id = global_warp; warp_id < n; warp_id += total_warps) {
        int v   = medQ[warp_id];
        int beg = row[v], end = row[v+1];

        for (int e = beg + lane; e < end; e += lanes_per_warp) {
            int u = col[e];
            bool is_new = bit_test_and_set(visited, u);
            unsigned mask = __ballot_sync(0xFFFFFFFF, is_new);
            int count = __popc(mask);
            if (count) {
                int base;
                if (lane == 0) base = atomicAdd(nextF_sz, count);
                base = __shfl_sync(0xFFFFFFFF, base, 0);
                int offs = __popc(mask & ((1u << lane) - 1));
                if (is_new) {
                    nextF[base + offs] = u;
                    dist[u] = level + 1;
                }
            }
        }
    }
}

// Push: large bucket (CTA-per-vertex) with **grid-stride over CTAs**
__global__ void bfs_push_large(
    const int* __restrict__ row, const int* __restrict__ col,
    const int* __restrict__ largeQ, const int* __restrict__ largeN,
    int* __restrict__ nextF, int* __restrict__ nextF_sz,
    uint32_t* __restrict__ visited, int* __restrict__ dist, int level)
{
    const int n = *largeN;
    const int lane = threadIdx.x & 31;

    for (int bid = blockIdx.x; bid < n; bid += gridDim.x) { // grid-stride over CTAs
        int v   = largeQ[bid];
        int beg = row[v], end = row[v+1];

        // strip-mine edges across all threads in the block
        for (int e = beg + threadIdx.x; e < end; e += blockDim.x) {
            int u = col[e];
            bool is_new = bit_test_and_set(visited, u);
            unsigned mask = __ballot_sync(0xFFFFFFFF, is_new);
            int count = __popc(mask);
            if (count) {
                int base;
                if (lane == 0) base = atomicAdd(nextF_sz, count);
                base = __shfl_sync(0xFFFFFFFF, base, 0);
                int offs = __popc(mask & ((1u << lane) - 1));
                if (is_new) {
                    nextF[base + offs] = u;
                    dist[u] = level + 1;
                }
            }
        }
    }
}

// Epoch-mark frontier (no bitmap memset)
__global__ void mark_frontier_epoch(const int* __restrict__ frontier, int fsz,
                                    uint32_t* __restrict__ epoch_arr, uint32_t epoch) {
    for (int i = blockIdx.x*blockDim.x + threadIdx.x; i < fsz; i += blockDim.x*gridDim.x) {
        epoch_arr[frontier[i]] = epoch;
    }
}

// Pull: scan unvisited v, check if any IN-neighbor is in current frontier (epoch)
__global__ void bfs_pull_kernel(
    const int* __restrict__ row_in, const int* __restrict__ col_in,
    const uint32_t* __restrict__ epoch_arr, uint32_t epoch,
    uint32_t* __restrict__ visited, int* __restrict__ nextF, int* __restrict__ nextF_sz,
    int* __restrict__ dist, int num_nodes, int level)
{
    for (int v = blockIdx.x*blockDim.x + threadIdx.x; v < num_nodes; v += blockDim.x*gridDim.x) {
        if (bit_is_set(visited, v)) continue;
        int beg = row_in[v], end = row_in[v+1];
        for (int e = beg; e < end; ++e) {
            int pred = col_in[e];
            if (epoch_arr[pred] == epoch) {
                if (bit_test_and_set(visited, v)) {
                    dist[v] = level + 1;
                    int pos = atomicAdd(nextF_sz, 1);
                    nextF[pos] = v;
                }
                break;
            }
        }
    }
}

// ---------------- Host-side graph I/O & utilities ----------------
struct CSR {
    int n=0, m=0, src=0;
    int *row_off=nullptr, *col_idx=nullptr;          // OUT-edges CSR (pinned memory)
    int *row_off_T=nullptr, *col_idx_T=nullptr;      // IN-edges CSR transpose (pinned memory)
    
    ~CSR() {
        if (row_off) cudaFreeHost(row_off);
        if (col_idx) cudaFreeHost(col_idx);
        if (row_off_T) cudaFreeHost(row_off_T);
        if (col_idx_T) cudaFreeHost(col_idx_T);
    }
};

static CSR read_rodinia_csr_or_die(const char* path) {
    FILE* fp = fopen(path, "r");
    if (!fp) { 
        std::fprintf(stderr, "Cannot open %s\n", path); 
        std::exit(1); 
    }

    int n;
    if (fscanf(fp, "%d", &n) != 1) {
        std::fprintf(stderr, "Malformed: missing n\n");
        fclose(fp);
        std::exit(1);
    }

    // Temporary storage for reading
    int* temp_starts = (int*)malloc(sizeof(int) * n);
    int* temp_deg = (int*)malloc(sizeof(int) * n);
    if (!temp_starts || !temp_deg) {
        std::fprintf(stderr, "Failed to allocate temp arrays\n");
        fclose(fp);
        std::exit(1);
    }

    for (int i = 0; i < n; ++i) {
        if (fscanf(fp, "%d %d", &temp_starts[i], &temp_deg[i]) != 2) {
            std::fprintf(stderr, "Malformed (start,deg) at node %d\n", i);
            fclose(fp);
            free(temp_starts);
            free(temp_deg);
            std::exit(1);
        }
    }

    int source, m;
    if (fscanf(fp, "%d", &source) != 1) {
        std::fprintf(stderr, "Malformed: missing source\n");
        fclose(fp);
        free(temp_starts);
        free(temp_deg);
        std::exit(1);
    }
    if (fscanf(fp, "%d", &m) != 1) {
        std::fprintf(stderr, "Malformed: missing m\n");
        fclose(fp);
        free(temp_starts);
        free(temp_deg);
        std::exit(1);
    }

    // Read edges
    int* temp_edge_dst = (int*)malloc(sizeof(int) * m);
    if (!temp_edge_dst) {
        std::fprintf(stderr, "Failed to allocate temp edge array\n");
        fclose(fp);
        free(temp_starts);
        free(temp_deg);
        std::exit(1);
    }
    
    int min_dst = std::numeric_limits<int>::max();
    int max_dst = std::numeric_limits<int>::min();
    for (int i = 0; i < m; ++i) {
        int id, cost;
        if (fscanf(fp, "%d %d", &id, &cost) != 2) {
            std::fprintf(stderr, "Malformed edge at %d\n", i);
            fclose(fp);
            free(temp_starts);
            free(temp_deg);
            free(temp_edge_dst);
            std::exit(1);
        }
        temp_edge_dst[i] = id;
        min_dst = std::min(min_dst, id);
        max_dst = std::max(max_dst, id);
    }
    fclose(fp);

    // Detect 1-based indexing
    bool starts_one_based = false;
    for (int i = 0; i < n; ++i) {
        if ((long long)temp_starts[i] + temp_deg[i] > (long long)m) {
            starts_one_based = true;
            break;
        }
    }
    if (starts_one_based) {
        for (int i = 0; i < n; ++i) temp_starts[i]--;
    }

    bool ids_one_based = (min_dst >= 1 && max_dst == n);
    if (ids_one_based) {
        for (int i = 0; i < m; ++i) temp_edge_dst[i]--;
        source--;
    }

    if (source < 0 || source >= n) {
        std::fprintf(stderr, "[error] source %d out of range\n", source);
        free(temp_starts);
        free(temp_deg);
        free(temp_edge_dst);
        std::exit(1);
    }

    // Allocate pinned memory for CSR
    CSR G;
    G.n = n;
    G.src = source;

    cudaError_t err = cudaMallocHost(&G.row_off, sizeof(int) * (n + 1));
    if (err != cudaSuccess) {
        std::fprintf(stderr, "cudaMallocHost failed for row_off: %s\n", cudaGetErrorString(err));
        free(temp_starts);
        free(temp_deg);
        free(temp_edge_dst);
        std::exit(1);
    }

    // Build row offsets
    G.row_off[0] = 0;
    for (int i = 0; i < n; ++i) {
        G.row_off[i + 1] = G.row_off[i] + temp_deg[i];
    }
    G.m = G.row_off[n];

    err = cudaMallocHost(&G.col_idx, sizeof(int) * G.m);
    if (err != cudaSuccess) {
        std::fprintf(stderr, "cudaMallocHost failed for col_idx: %s\n", cudaGetErrorString(err));
        cudaFreeHost(G.row_off);
        free(temp_starts);
        free(temp_deg);
        free(temp_edge_dst);
        std::exit(1);
    }

    // Fill column indices
    for (int v = 0; v < n; ++v) {
        int s = temp_starts[v];
        int d = temp_deg[v];
        int ro = G.row_off[v];
        for (int j = 0; j < d && ro + j < G.m; ++j) {
            int idx = s + j;
            if (idx >= 0 && idx < m) {
                int u = temp_edge_dst[idx];
                if (u >= 0 && u < n) {
                    G.col_idx[ro + j] = u;
                }
            }
        }
    }

    // Build transpose CSR for pull phase
    err = cudaMallocHost(&G.row_off_T, sizeof(int) * (n + 1));
    if (err != cudaSuccess) {
        std::fprintf(stderr, "cudaMallocHost failed for row_off_T: %s\n", cudaGetErrorString(err));
        cudaFreeHost(G.row_off);
        cudaFreeHost(G.col_idx);
        free(temp_starts);
        free(temp_deg);
        free(temp_edge_dst);
        std::exit(1);
    }

    memset(G.row_off_T, 0, sizeof(int) * (n + 1));
    for (int e = 0; e < G.m; ++e) {
        int u = G.col_idx[e];
        if (u >= 0 && u < n) G.row_off_T[u + 1]++;
    }
    for (int i = 0; i < n; ++i) {
        G.row_off_T[i + 1] += G.row_off_T[i];
    }

    err = cudaMallocHost(&G.col_idx_T, sizeof(int) * G.row_off_T[n]);
    if (err != cudaSuccess) {
        std::fprintf(stderr, "cudaMallocHost failed for col_idx_T: %s\n", cudaGetErrorString(err));
        cudaFreeHost(G.row_off);
        cudaFreeHost(G.col_idx);
        cudaFreeHost(G.row_off_T);
        free(temp_starts);
        free(temp_deg);
        free(temp_edge_dst);
        std::exit(1);
    }

    int* cursor = (int*)malloc(sizeof(int) * n);
    memcpy(cursor, G.row_off_T, sizeof(int) * n);
    for (int v = 0; v < n; ++v) {
        int beg = G.row_off[v];
        int end = G.row_off[v + 1];
        for (int e = beg; e < end; ++e) {
            int u = G.col_idx[e];
            if (u >= 0 && u < n) {
                int pos = cursor[u]++;
                G.col_idx_T[pos] = v;
            }
        }
    }

    free(cursor);
    free(temp_starts);
    free(temp_deg);
    free(temp_edge_dst);
    
    return G;
}

static void write_result(const char* path, const int* dist, int n) {
    FILE* fp = fopen(path, "w");
    if (!fp) {
        std::fprintf(stderr, "Cannot write to %s\n", path);
        return;
    }
    for (int i = 0; i < n; ++i) {
        fprintf(fp, "%d) cost:%d\n", i, dist[i]);
    }
    fclose(fp);
    std::printf("Result stored in %s\n", path);
}

// ---------------- Helpers ----------------
static inline int blocks_for(long long work_items, int tpb, int max_blocks) {
    if (work_items <= 0) return 1;
    long long b = (work_items + tpb - 1) / tpb;
    if (b < 1) b = 1;
    if (b > max_blocks) b = max_blocks;
    return (int)b;
}

// ---------------- Main ----------------
int main(int argc, char** argv) {
    if (argc != 2) {
        std::fprintf(stderr,"Usage: %s <rodinia_csr_graph.txt>\n", argv[0]);
        return 0;
    }

    std::printf("Reading graph file...\n");
    CSR G = read_rodinia_csr_or_die(argv[1]);
    int transpose_edges = G.row_off_T[G.n];
    std::printf("Graph |V|=%d |E|=%d (transpose E=%d) source=%d\n",
                G.n, G.m, transpose_edges, G.src);

    // Device props for launch sizing
    cudaDeviceProp prop{}; CUDA_CHECK(cudaGetDeviceProperties(&prop, 0));
    const int MAX_BLOCKS = std::max(1, prop.multiProcessorCount * 8);

    // Allocate pinned memory for distance array
    std::printf("Allocating host memory...\n");
    int* h_dist = nullptr;
    cudaError_t err = cudaMallocHost(&h_dist, sizeof(int) * G.n);
    if (err != cudaSuccess) {
        std::fprintf(stderr, "cudaMallocHost failed for h_dist: %s\n", cudaGetErrorString(err));
        return 1;
    }
    
    // Initialize costs
    for (int i = 0; i < G.n; ++i) h_dist[i] = -1;
    h_dist[G.src] = 0;
    
    int bit_words = (G.n + 31) / 32;

    // GPU memory allocation
    std::printf("Allocating device memory...\n");
    int *d_row_out=nullptr, *d_col_out=nullptr, *d_row_in=nullptr, *d_col_in=nullptr;
    int *d_frontier=nullptr, *d_next_frontier=nullptr;
    int *d_fsz=nullptr, *d_nfsz=nullptr;
    int *d_dist=nullptr;
    uint32_t *d_visited=nullptr;
    uint32_t *d_epoch=nullptr;

    // degree buckets
    int *d_smallQ=nullptr, *d_medQ=nullptr, *d_largeQ=nullptr;
    int *d_smallN=nullptr, *d_medN=nullptr, *d_largeN=nullptr;

    // reductions
    unsigned long long *d_sum=nullptr;

    CUDA_CHECK(cudaMalloc(&d_row_out, sizeof(int)*(G.n+1)));
    CUDA_CHECK(cudaMalloc(&d_col_out, sizeof(int)*G.m));
    CUDA_CHECK(cudaMalloc(&d_row_in,  sizeof(int)*(G.n+1)));
    CUDA_CHECK(cudaMalloc(&d_col_in,  sizeof(int)*transpose_edges));
    CUDA_CHECK(cudaMalloc(&d_frontier,       sizeof(int)*G.n));
    CUDA_CHECK(cudaMalloc(&d_next_frontier,  sizeof(int)*G.n));
    CUDA_CHECK(cudaMalloc(&d_fsz,   sizeof(int)));
    CUDA_CHECK(cudaMalloc(&d_nfsz,  sizeof(int)));
    CUDA_CHECK(cudaMalloc(&d_dist,  sizeof(int)*G.n));
    CUDA_CHECK(cudaMalloc(&d_visited,    sizeof(uint32_t)*bit_words));
    CUDA_CHECK(cudaMalloc(&d_epoch,      sizeof(uint32_t)*G.n));

    CUDA_CHECK(cudaMalloc(&d_smallQ, sizeof(int)*G.n));
    CUDA_CHECK(cudaMalloc(&d_medQ,   sizeof(int)*G.n));
    CUDA_CHECK(cudaMalloc(&d_largeQ, sizeof(int)*G.n));
    CUDA_CHECK(cudaMalloc(&d_smallN, sizeof(int)));
    CUDA_CHECK(cudaMalloc(&d_medN,   sizeof(int)));
    CUDA_CHECK(cudaMalloc(&d_largeN, sizeof(int)));

    CUDA_CHECK(cudaMalloc(&d_sum, sizeof(unsigned long long)));

    // Transfer data to device (async with streams)
    std::printf("Transferring data to device...\n");
    cudaStream_t stream1, stream2, stream3;
    CUDA_CHECK(cudaStreamCreate(&stream1));
    CUDA_CHECK(cudaStreamCreate(&stream2));
    CUDA_CHECK(cudaStreamCreate(&stream3));

    CUDA_CHECK(cudaMemcpyAsync(d_row_out, G.row_off, sizeof(int)*(G.n+1), cudaMemcpyHostToDevice, stream1));
    CUDA_CHECK(cudaMemcpyAsync(d_col_out, G.col_idx, sizeof(int)*G.m, cudaMemcpyHostToDevice, stream1));

    CUDA_CHECK(cudaMemcpyAsync(d_row_in, G.row_off_T, sizeof(int)*(G.n+1), cudaMemcpyHostToDevice, stream2));
    CUDA_CHECK(cudaMemcpyAsync(d_col_in, G.col_idx_T, sizeof(int)*transpose_edges, cudaMemcpyHostToDevice, stream2));

    CUDA_CHECK(cudaMemcpyAsync(d_dist, h_dist, sizeof(int)*G.n, cudaMemcpyHostToDevice, stream3));
    CUDA_CHECK(cudaMemsetAsync(d_visited, 0, sizeof(uint32_t)*bit_words, stream3));
    CUDA_CHECK(cudaMemsetAsync(d_epoch, 0, sizeof(uint32_t)*G.n, stream3));
    CUDA_CHECK(cudaMemsetAsync(d_nfsz, 0, sizeof(int), stream3));

    CUDA_CHECK(cudaStreamSynchronize(stream1));
    CUDA_CHECK(cudaStreamSynchronize(stream2));
    CUDA_CHECK(cudaStreamSynchronize(stream3));

    CUDA_CHECK(cudaStreamDestroy(stream1));
    CUDA_CHECK(cudaStreamDestroy(stream2));
    CUDA_CHECK(cudaStreamDestroy(stream3));

    // Initialize BFS
    std::printf("Initializing BFS...\n");
    {
        std::vector<uint32_t> vb(bit_words, 0);
        vb[G.src >> 5] |= (1u << (G.src & 31));
        CUDA_CHECK(cudaMemcpy(d_visited, vb.data(), sizeof(uint32_t)*bit_words, cudaMemcpyHostToDevice));
    }

    init_frontier<<<1,1>>>(d_frontier, d_fsz, G.src);
    CUDA_CHECK(cudaDeviceSynchronize());

    // BFS main loop
    std::printf("Running BFS...\n");
    int level=0, iters=0, h_fsz=1;
    bool in_pull = false;
    uint32_t epoch = 1;
    unsigned long long visited_edges = 0ull;

    while (true) {
        CUDA_CHECK(cudaMemcpy(&h_fsz, d_fsz, sizeof(int), cudaMemcpyDeviceToHost));
        if (h_fsz == 0) break;

        // Compute scout_count = sum of degrees of current frontier
        CUDA_CHECK(cudaMemset(d_sum, 0, sizeof(unsigned long long)));
        {
            int blocks = blocks_for(h_fsz, TPB, MAX_BLOCKS);
            sum_frontier_degrees<<<blocks, TPB>>>(d_frontier, h_fsz, d_row_out, d_sum);
        }
        unsigned long long scout_count = 0ull;
        CUDA_CHECK(cudaMemcpy(&scout_count, d_sum, sizeof(unsigned long long), cudaMemcpyDeviceToHost));

        // Decide push or pull (Ligra heuristic)
        bool want_pull = (!in_pull) && (scout_count > (unsigned long long)((G.m - visited_edges) / ALPHA));
        bool want_push = ( in_pull) && (h_fsz < (int)(G.n / BETA));
        if (want_pull) in_pull = true;
        else if (want_push) in_pull = false;

        // Reset next frontier size
        CUDA_CHECK(cudaMemset(d_nfsz, 0, sizeof(int)));

        if (in_pull) {
            // PULL phase
            if (++epoch == 0u) { // rare wrap-around
                CUDA_CHECK(cudaMemset(d_epoch, 0, sizeof(uint32_t)*G.n));
                epoch = 1;
            }
            {
                int blocks = blocks_for(h_fsz, TPB, MAX_BLOCKS);
                mark_frontier_epoch<<<blocks, TPB>>>(d_frontier, h_fsz, d_epoch, epoch);
            }
            {
                int blocks = blocks_for(G.n, TPB, MAX_BLOCKS);
                bfs_pull_kernel<<<blocks, TPB>>>(
                    d_row_in, d_col_in,
                    d_epoch, epoch,
                    d_visited,
                    d_next_frontier, d_nfsz,
                    d_dist, G.n, level
                );
            }
        } else {
            // PUSH phase: bucket by degree
            CUDA_CHECK(cudaMemset(d_smallN, 0, sizeof(int)));
            CUDA_CHECK(cudaMemset(d_medN,   0, sizeof(int)));
            CUDA_CHECK(cudaMemset(d_largeN, 0, sizeof(int)));
            {
                int blocks = blocks_for(h_fsz, TPB, MAX_BLOCKS);
                bucket_by_degree<<<blocks, TPB>>>(d_frontier, h_fsz, d_row_out,
                                                  d_smallQ, d_medQ, d_largeQ,
                                                  d_smallN, d_medN, d_largeN);
            }

            // Read bucket sizes
            int h_smallN=0, h_medN=0, h_largeN=0;
            CUDA_CHECK(cudaMemcpy(&h_smallN, d_smallN, sizeof(int), cudaMemcpyDeviceToHost));
            CUDA_CHECK(cudaMemcpy(&h_medN,   d_medN,   sizeof(int), cudaMemcpyDeviceToHost));
            CUDA_CHECK(cudaMemcpy(&h_largeN, d_largeN, sizeof(int), cudaMemcpyDeviceToHost));

            // Small bucket
            if (h_smallN > 0) {
                int blocks = blocks_for(h_smallN, TPB, MAX_BLOCKS);
                bfs_push_small<<<blocks, TPB>>>(
                    d_row_out, d_col_out, d_smallQ, d_smallN,
                    d_next_frontier, d_nfsz, d_visited, d_dist, level
                );
            }
            
            // Medium bucket
            if (h_medN > 0) {
                int threads = TPB;
                int blocks  = std::min(MAX_BLOCKS, std::max(1, prop.multiProcessorCount*6));
                bfs_push_medium<<<blocks, threads>>>(
                    d_row_out, d_col_out, d_medQ, d_medN,
                    d_next_frontier, d_nfsz, d_visited, d_dist, level
                );
            }
            
            // Large bucket
            if (h_largeN > 0) {
                int blocks = std::min(MAX_BLOCKS, std::max(1, prop.multiProcessorCount*6));
                bfs_push_large<<<blocks, TPB>>>(
                    d_row_out, d_col_out, d_largeQ, d_largeN,
                    d_next_frontier, d_nfsz, d_visited, d_dist, level
                );
            }
        }

        // Update visited_edges by summing degrees of the NEXT frontier
        int h_next = 0;
        CUDA_CHECK(cudaMemcpy(&h_next, d_nfsz, sizeof(int), cudaMemcpyDeviceToHost));
        if (h_next > 0) {
            CUDA_CHECK(cudaMemset(d_sum, 0, sizeof(unsigned long long)));
            int blocks = blocks_for(h_next, TPB, MAX_BLOCKS);
            sum_vertices_degrees<<<blocks, TPB>>>(d_next_frontier, h_next, d_row_out, d_sum);
            unsigned long long add = 0ull;
            CUDA_CHECK(cudaMemcpy(&add, d_sum, sizeof(unsigned long long), cudaMemcpyDeviceToHost));
            visited_edges += add;
        }

        // Prepare next iteration
        CUDA_CHECK(cudaMemcpy(d_fsz, d_nfsz, sizeof(int), cudaMemcpyDeviceToDevice));
        std::swap(d_frontier, d_next_frontier);
        ++level; ++iters;
        
        if (iters > G.n) { 
            fprintf(stderr,"[warn] iterations > |V|; break\n"); 
            break; 
        }
    }

    std::printf("BFS complete. Levels=%d, iters=%d (%s)\n", 
                level, iters, "direction-optimized");

    // Copy result back
    std::printf("Copying results back...\n");
    CUDA_CHECK(cudaMemcpy(h_dist, d_dist, sizeof(int)*G.n, cudaMemcpyDeviceToHost));

    // Write results
    write_result("result_gunrock.txt", h_dist, G.n);

    // Cleanup
    std::printf("Cleaning up...\n");
    cudaFree(d_row_out); cudaFree(d_col_out); cudaFree(d_row_in); cudaFree(d_col_in);
    cudaFree(d_frontier); cudaFree(d_next_frontier);
    cudaFree(d_fsz); cudaFree(d_nfsz);
    cudaFree(d_dist); cudaFree(d_visited); cudaFree(d_epoch);
    cudaFree(d_smallQ); cudaFree(d_medQ); cudaFree(d_largeQ);
    cudaFree(d_smallN); cudaFree(d_medN); cudaFree(d_largeN);
    cudaFree(d_sum);

    cudaFreeHost(h_dist);

    std::printf("Done.\n");
    return 0;
}

