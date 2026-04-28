#include <hip/hip_runtime.h>
#include <roctx.h>
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

#define HIP_CHECK(x) do { hipError_t e=(x); if (e!=hipSuccess){ \
  fprintf(stderr,"HIP %s:%d: %s\n",__FILE__,__LINE__,hipGetErrorString(e)); \
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
            auto mask = __ballot(is_new);
            int count = __popcll(mask);
            if (count) {
                int base;
                if (lane == 0) base = atomicAdd(nextF_sz, count);
                base = __shfl(base, 0);
                int offs = __popcll(mask & ((1u << lane) - 1));
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
            auto mask = __ballot(is_new);
            int count = __popcll(mask);
            if (count) {
                int base;
                if (lane == 0) base = atomicAdd(nextF_sz, count);
                base = __shfl(base, 0);
                int offs = __popcll(mask & ((1u << lane) - 1));
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
        if (row_off) hipHostFree(row_off);
        if (col_idx) hipHostFree(col_idx);
        if (row_off_T) hipHostFree(row_off_T);
        if (col_idx_T) hipHostFree(col_idx_T);
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

    hipError_t err = hipHostMalloc(&G.row_off, sizeof(int) * (n + 1));
    if (err != hipSuccess) {
        std::fprintf(stderr, "hipHostMalloc failed for row_off: %s\n", hipGetErrorString(err));
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

    err = hipHostMalloc(&G.col_idx, sizeof(int) * G.m);
    if (err != hipSuccess) {
        std::fprintf(stderr, "hipHostMalloc failed for col_idx: %s\n", hipGetErrorString(err));
        hipHostFree(G.row_off);
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
    err = hipHostMalloc(&G.row_off_T, sizeof(int) * (n + 1));
    if (err != hipSuccess) {
        std::fprintf(stderr, "hipHostMalloc failed for row_off_T: %s\n", hipGetErrorString(err));
        hipHostFree(G.row_off);
        hipHostFree(G.col_idx);
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

    err = hipHostMalloc(&G.col_idx_T, sizeof(int) * G.row_off_T[n]);
    if (err != hipSuccess) {
        std::fprintf(stderr, "hipHostMalloc failed for col_idx_T: %s\n", hipGetErrorString(err));
        hipHostFree(G.row_off);
        hipHostFree(G.col_idx);
        hipHostFree(G.row_off_T);
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
    roctxRangePush("BFS Main Program");

    if (argc != 2) {
        std::fprintf(stderr,"Usage: %s <rodinia_csr_graph.txt>\n", argv[0]);
        roctxRangePop();
        return 0;
    }

    // File I/O Phase
    roctxRangePush("File I/O - Reading Graph");

    CSR G = read_rodinia_csr_or_die(argv[1]);
    int transpose_edges = G.row_off_T[G.n];
    std::printf("Graph |V|=%d |E|=%d (transpose E=%d) source=%d\n",
                G.n, G.m, transpose_edges, G.src);

    roctxRangePop(); // End File I/O

    // Device props for launch sizing
    hipDeviceProp_t prop{}; HIP_CHECK(hipGetDeviceProperties(&prop, 0));
    const int MAX_BLOCKS = std::max(1, prop.multiProcessorCount * 8);

    // Host Memory Allocation & Initialization Phase (Pinned Memory)
    roctxRangePush("Host Memory Setup (Pinned)");

    // Allocate pinned memory for distance array and bitset
    int* h_dist = nullptr;
    hipError_t err = hipHostMalloc(&h_dist, sizeof(int) * G.n);
    if (err != hipSuccess) {
        std::fprintf(stderr, "hipHostMalloc failed for h_dist: %s\n", hipGetErrorString(err));
        roctxRangePop();
        roctxRangePop();
        return 1;
    }
    
    // Initialize costs
    for (int i = 0; i < G.n; ++i) h_dist[i] = -1;
    h_dist[G.src] = 0;
    
    int bit_words = (G.n + 31) / 32;

    roctxRangePop(); // End Host Memory Setup

    // GPU Memory Allocation Phase
    roctxRangePush("GPU Memory Allocation");

    // device allocations
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

    HIP_CHECK(hipMalloc(&d_row_out, sizeof(int)*(G.n+1)));
    HIP_CHECK(hipMalloc(&d_col_out, sizeof(int)*G.m));
    HIP_CHECK(hipMalloc(&d_row_in,  sizeof(int)*(G.n+1)));
    HIP_CHECK(hipMalloc(&d_col_in,  sizeof(int)*transpose_edges));
    HIP_CHECK(hipMalloc(&d_frontier,       sizeof(int)*G.n));
    HIP_CHECK(hipMalloc(&d_next_frontier,  sizeof(int)*G.n));
    HIP_CHECK(hipMalloc(&d_fsz,   sizeof(int)));
    HIP_CHECK(hipMalloc(&d_nfsz,  sizeof(int)));
    HIP_CHECK(hipMalloc(&d_dist,  sizeof(int)*G.n));
    HIP_CHECK(hipMalloc(&d_visited,    sizeof(uint32_t)*bit_words));
    HIP_CHECK(hipMalloc(&d_epoch,      sizeof(uint32_t)*G.n));

    HIP_CHECK(hipMalloc(&d_smallQ, sizeof(int)*G.n));
    HIP_CHECK(hipMalloc(&d_medQ,   sizeof(int)*G.n));
    HIP_CHECK(hipMalloc(&d_largeQ, sizeof(int)*G.n));
    HIP_CHECK(hipMalloc(&d_smallN, sizeof(int)));
    HIP_CHECK(hipMalloc(&d_medN,   sizeof(int)));
    HIP_CHECK(hipMalloc(&d_largeN, sizeof(int)));

    HIP_CHECK(hipMalloc(&d_sum, sizeof(unsigned long long)));

    roctxRangePop(); // End GPU Memory Allocation

    // Host to Device Memory Transfer Phase (Async with Streams)
    roctxRangePush("Async Host to Device Memory Transfer");

    // Create HIP streams for overlapping transfers
    hipStream_t stream1, stream2, stream3;
    HIP_CHECK(hipStreamCreate(&stream1));
    HIP_CHECK(hipStreamCreate(&stream2));
    HIP_CHECK(hipStreamCreate(&stream3));

    // Stream 1: OUT-graph (row offsets + column indices) - data already in pinned memory
    HIP_CHECK(hipMemcpyAsync(d_row_out, G.row_off, sizeof(int)*(G.n+1), hipMemcpyHostToDevice, stream1));
    HIP_CHECK(hipMemcpyAsync(d_col_out, G.col_idx, sizeof(int)*G.m, hipMemcpyHostToDevice, stream1));

    // Stream 2: IN-graph (transpose - row offsets + column indices) - data already in pinned memory
    HIP_CHECK(hipMemcpyAsync(d_row_in, G.row_off_T, sizeof(int)*(G.n+1), hipMemcpyHostToDevice, stream2));
    HIP_CHECK(hipMemcpyAsync(d_col_in, G.col_idx_T, sizeof(int)*transpose_edges, hipMemcpyHostToDevice, stream2));

    // Stream 3: Distance array and initialization memsets
    HIP_CHECK(hipMemcpyAsync(d_dist, h_dist, sizeof(int)*G.n, hipMemcpyHostToDevice, stream3));
    HIP_CHECK(hipMemsetAsync(d_visited, 0, sizeof(uint32_t)*bit_words, stream3));
    HIP_CHECK(hipMemsetAsync(d_epoch, 0, sizeof(uint32_t)*G.n, stream3));
    HIP_CHECK(hipMemsetAsync(d_nfsz, 0, sizeof(int), stream3));

    // Synchronize all streams
    HIP_CHECK(hipStreamSynchronize(stream1));
    HIP_CHECK(hipStreamSynchronize(stream2));
    HIP_CHECK(hipStreamSynchronize(stream3));

    // Destroy streams
    HIP_CHECK(hipStreamDestroy(stream1));
    HIP_CHECK(hipStreamDestroy(stream2));
    HIP_CHECK(hipStreamDestroy(stream3));

    roctxRangePop(); // End H2D Transfer

    // Initialization Phase
    roctxRangePush("BFS Initialization");

    // mark source visited
    {
        std::vector<uint32_t> vb(bit_words, 0);
        vb[G.src >> 5] |= (1u << (G.src & 31));
        HIP_CHECK(hipMemcpy(d_visited, vb.data(), sizeof(uint32_t)*bit_words, hipMemcpyHostToDevice));
    }

    // init frontier
    init_frontier<<<1,1>>>(d_frontier, d_fsz, G.src);
    HIP_CHECK(hipDeviceSynchronize());

    roctxRangePop(); // End Initialization

    // BFS Kernel Execution Phase
    roctxRangePush("BFS Kernel Execution Loop");

    int level=0, iters=0, h_fsz=1;
    bool in_pull = false;
    uint32_t epoch = 1;
    unsigned long long visited_edges = 0ull;

    while (true) {
        // Mark each iteration
        char iteration_msg[64];
        sprintf(iteration_msg, "BFS Iteration %d", iters);
        roctxRangePush(iteration_msg);
        HIP_CHECK(hipMemcpy(&h_fsz, d_fsz, sizeof(int), hipMemcpyDeviceToHost));
        if (h_fsz == 0) {
            roctxRangePop(); // End iteration
            break;
        }

        // Compute scout_count = sum of degrees of current frontier
        HIP_CHECK(hipMemset(d_sum, 0, sizeof(unsigned long long)));
        {
            int blocks = blocks_for(h_fsz, TPB, MAX_BLOCKS);
            sum_frontier_degrees<<<blocks, TPB>>>(d_frontier, h_fsz, d_row_out, d_sum);
        }
        unsigned long long scout_count = 0ull;
        HIP_CHECK(hipMemcpy(&scout_count, d_sum, sizeof(unsigned long long), hipMemcpyDeviceToHost));

        // Decide push or pull (Ligra heuristic)
        bool want_pull = (!in_pull) && (scout_count > (unsigned long long)((G.m - visited_edges) / ALPHA));
        bool want_push = ( in_pull) && (h_fsz < (int)(G.n / BETA));
        if (want_pull) in_pull = true;
        else if (want_push) in_pull = false;

        // Reset next frontier size
        HIP_CHECK(hipMemset(d_nfsz, 0, sizeof(int)));

        if (in_pull) {
            roctxRangePush("PULL Phase");
            // Epoch-mark current frontier (no memset)
            if (++epoch == 0u) { // rare wrap-around
                HIP_CHECK(hipMemset(d_epoch, 0, sizeof(uint32_t)*G.n));
                epoch = 1;
            }
            {
                int blocks = blocks_for(h_fsz, TPB, MAX_BLOCKS);
                mark_frontier_epoch<<<blocks, TPB>>>(d_frontier, h_fsz, d_epoch, epoch);
            }
            // Pull on IN-edges
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
            roctxRangePop(); // End PULL Phase
        } else {
            roctxRangePush("PUSH Phase");
            // PUSH: bucket by degree
            HIP_CHECK(hipMemset(d_smallN, 0, sizeof(int)));
            HIP_CHECK(hipMemset(d_medN,   0, sizeof(int)));
            HIP_CHECK(hipMemset(d_largeN, 0, sizeof(int)));
            {
                int blocks = blocks_for(h_fsz, TPB, MAX_BLOCKS);
                bucket_by_degree<<<blocks, TPB>>>(d_frontier, h_fsz, d_row_out,
                                                  d_smallQ, d_medQ, d_largeQ,
                                                  d_smallN, d_medN, d_largeN);
            }

            // Read bucket sizes
            int h_smallN=0, h_medN=0, h_largeN=0;
            HIP_CHECK(hipMemcpy(&h_smallN, d_smallN, sizeof(int), hipMemcpyDeviceToHost));
            HIP_CHECK(hipMemcpy(&h_medN,   d_medN,   sizeof(int), hipMemcpyDeviceToHost));
            HIP_CHECK(hipMemcpy(&h_largeN, d_largeN, sizeof(int), hipMemcpyDeviceToHost));

            // Small
            if (h_smallN > 0) {
                roctxRangePush("Push Small Kernel");
                int blocks = blocks_for(h_smallN, TPB, MAX_BLOCKS);
                bfs_push_small<<<blocks, TPB>>>(
                    d_row_out, d_col_out, d_smallQ, d_smallN,
                    d_next_frontier, d_nfsz, d_visited, d_dist, level
                );
                roctxRangePop();
            }
            // Medium: launch an occupancy-friendly grid; kernel grid-strides over WARPS
            if (h_medN > 0) {
                roctxRangePush("Push Medium Kernel");
                int threads = TPB;                 // multiple warps per block
                int blocks  = std::min(MAX_BLOCKS, std::max(1, prop.multiProcessorCount*6));
                bfs_push_medium<<<blocks, threads>>>(
                    d_row_out, d_col_out, d_medQ, d_medN,
                    d_next_frontier, d_nfsz, d_visited, d_dist, level
                );
                roctxRangePop();
            }
            // Large: launch an occupancy-friendly grid; kernel grid-strides over CTAs
            if (h_largeN > 0) {
                roctxRangePush("Push Large Kernel");
                int blocks = std::min(MAX_BLOCKS, std::max(1, prop.multiProcessorCount*6));
                bfs_push_large<<<blocks, TPB>>>(
                    d_row_out, d_col_out, d_largeQ, d_largeN,
                    d_next_frontier, d_nfsz, d_visited, d_dist, level
                );
                roctxRangePop();
            }
            roctxRangePop(); // End PUSH Phase
        }

        // Update visited_edges by summing degrees of the NEXT frontier
        int h_next = 0;
        HIP_CHECK(hipMemcpy(&h_next, d_nfsz, sizeof(int), hipMemcpyDeviceToHost));
        if (h_next > 0) {
            HIP_CHECK(hipMemset(d_sum, 0, sizeof(unsigned long long)));
            int blocks = blocks_for(h_next, TPB, MAX_BLOCKS);
            sum_vertices_degrees<<<blocks, TPB>>>(d_next_frontier, h_next, d_row_out, d_sum);
            unsigned long long add = 0ull;
            HIP_CHECK(hipMemcpy(&add, d_sum, sizeof(unsigned long long), hipMemcpyDeviceToHost));
            visited_edges += add;
        }

        // prepare next iter
        HIP_CHECK(hipMemcpy(d_fsz, d_nfsz, sizeof(int), hipMemcpyDeviceToDevice));
        std::swap(d_frontier, d_next_frontier);
        ++level; ++iters;
        
        roctxRangePop(); // End iteration
        
        if (iters > G.n) { fprintf(stderr,"[warn] iterations > |V|; break\n"); break; }
    }

    roctxRangePop(); // End BFS Kernel Execution

    // Device to Host Memory Transfer Phase
    roctxRangePush("Device to Host Memory Transfer");

    // Copy result back
    HIP_CHECK(hipMemcpy(h_dist, d_dist, sizeof(int)*G.n, hipMemcpyDeviceToHost));

    roctxRangePop(); // End D2H Transfer

    // Result Output Phase
    roctxRangePush("Result Output to File");

    write_result("result_gunrock_style.txt", h_dist, G.n);

    roctxRangePop(); // End Result Output

    // Memory Cleanup Phase
    roctxRangePush("Memory Cleanup");

    // Free device memory
    hipFree(d_row_out); hipFree(d_col_out); hipFree(d_row_in); hipFree(d_col_in);
    hipFree(d_frontier); hipFree(d_next_frontier);
    hipFree(d_fsz); hipFree(d_nfsz);
    hipFree(d_dist); hipFree(d_visited); hipFree(d_epoch);
    hipFree(d_smallQ); hipFree(d_medQ); hipFree(d_largeQ);
    hipFree(d_smallN); hipFree(d_medN); hipFree(d_largeN);
    hipFree(d_sum);

    // Free pinned host memory
    hipHostFree(h_dist);
    // G's memory (row_off, col_idx, row_off_T, col_idx_T) freed by destructor

    roctxRangePop(); // End Memory Cleanup

    std::printf("BFS done. Levels=%d, iters=%d (%s)\n", level, iters, "direction-optimized");

    roctxRangePop(); // End BFS Main Program
    return 0;
}