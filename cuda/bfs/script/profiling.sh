#!/bin/bash
################################################################################
# BFS Profiling Script - Nsight Systems (nsys) & Nsight Compute (ncu)
################################################################################
# This script profiles BFS implementations using NVIDIA profiling tools.
# It performs 5 profiled runs with nsys and 1 detailed run with ncu.
#
# CONFIGURATION INSTRUCTIONS:
# ---------------------------
# 1. Set RODINIA_ROOT to your Rodinia installation directory
# 2. Set BFS_IMPL to the implementation you want to profile:
#    - "bfs_3.1" for the original BFS implementation
#    - "bfs_frontier" for the Gunrock-style frontier implementation
# 3. Set DATASET_PATH to your graph file (Rodinia CSR format)
# 4. Set GPU_TAG to identify your GPU (e.g., "a100", "v100", "rtx3090")
# 5. Optionally set NUM_RUNS (default: 5)
#
# REQUIREMENTS:
# - CUDA Toolkit with nsys (Nsight Systems)
# - ncu (Nsight Compute) for SM >= 70 (Volta+)
# - Compiled profiling binaries (see README in profiling/ directories)
#
# USAGE:
# ./profiling.sh
#
# OUTPUT:
# - profiles/    : .nsys-rep files (open with nsys-ui)
# - stats/       : CSV exports of profiling statistics
# - ncu/         : .ncu-rep files and CSV metrics (open with ncu-ui)
################################################################################

# ============================================================================
# USER CONFIGURATION - EDIT THESE VARIABLES
# ============================================================================

# Path to Rodinia root directory (parent of cuda/bfs/)
RODINIA_ROOT="${RODINIA_ROOT:-$(cd "$(dirname "$0")/../../.." && pwd)}"

# BFS implementation to profile: "bfs_3.1" or "bfs_frontier"
BFS_IMPL="${BFS_IMPL:-bfs_frontier}"

# Path to dataset file (Rodinia CSR format)
# Example: "${RODINIA_ROOT}/data/bfs/rmat_graphs/graph1M_sparse.txt"
DATASET_PATH="${DATASET_PATH:-${RODINIA_ROOT}/data/bfs/rmat_graphs/graph1M_sparse.txt}"

# GPU identifier for output naming (lowercase recommended)
GPU_TAG="${GPU_TAG:-a100}"

# Number of profiling runs (default: 5)
NUM_RUNS="${NUM_RUNS:-5}"

# ============================================================================
# DERIVED PATHS - Automatically set based on above configuration
# ============================================================================

PROFILING_DIR="${RODINIA_ROOT}/cuda/bfs/${BFS_IMPL}/profiling"
EXECUTABLE="${PROFILING_DIR}/bfs_nvtx_${GPU_TAG}.out"

# Extract dataset name for tagging
DATASET_NAME=$(basename "$DATASET_PATH" .txt)

# Output tag
TAG="bfs_${DATASET_NAME}_${GPU_TAG}"

# Job ID (SLURM if available, otherwise PID)
JOB_ID="${SLURM_JOB_ID:-$$}"

# ============================================================================
# VALIDATION
# ============================================================================

echo "=========================================="
echo "BFS Profiling Script Configuration"
echo "=========================================="
echo "RODINIA_ROOT  : $RODINIA_ROOT"
echo "BFS_IMPL      : $BFS_IMPL"
echo "EXECUTABLE    : $EXECUTABLE"
echo "DATASET_PATH  : $DATASET_PATH"
echo "GPU_TAG       : $GPU_TAG"
echo "NUM_RUNS      : $NUM_RUNS"
echo "OUTPUT_TAG    : $TAG"
echo "JOB_ID        : $JOB_ID"
echo "=========================================="
echo ""

# Check if executable exists
if [[ ! -f "$EXECUTABLE" ]]; then
    echo "[ERROR] Executable not found: $EXECUTABLE"
    echo ""
    echo "Build the profiling binary first:"
    echo "  cd ${PROFILING_DIR}"
    echo "  make GPU=${GPU_TAG}"
    echo ""
    exit 1
fi

# Check if dataset exists
if [[ ! -f "$DATASET_PATH" ]]; then
    echo "[ERROR] Dataset not found: $DATASET_PATH"
    echo ""
    echo "Generate datasets using:"
    echo "  cd ${RODINIA_ROOT}/data/bfs/rmat_graphs"
    echo "  ./rmat_gen_sparse.sh"
    echo ""
    echo "Or download pre-generated datasets from:"
    echo "  https://virginia.box.com/s/gvyjdq8qt9ei0ojyd3itokngq7pr2al2"
    echo ""
    exit 1
fi

# Check if nsys is available
if ! command -v nsys &> /dev/null; then
    echo "[ERROR] nsys (Nsight Systems) not found in PATH"
    echo "Install CUDA Toolkit or add nsys to PATH"
    exit 1
fi

# ============================================================================
# SETUP
# ============================================================================

echo "[setup] Creating output directories..."
mkdir -p profiles stats ncu

# Clean previous runs (optional - comment out to keep)
# rm -rf profiles/* stats/* ncu/*

echo ""
echo "=========================================="
echo "System Information"
echo "=========================================="
echo "Hostname: $(hostname)"
echo "CUDA_VISIBLE_DEVICES: ${CUDA_VISIBLE_DEVICES:-all}"
echo ""
nvidia-smi -L
echo ""
nvidia-smi -q | sed -n '1,50p'
echo ""

# ============================================================================
# WARM-UP RUN
# ============================================================================

echo "=========================================="
echo "Warm-up Run (no profiling)"
echo "=========================================="
echo "[warmup] $EXECUTABLE $DATASET_PATH"
"$EXECUTABLE" "$DATASET_PATH"
echo ""

# ============================================================================
# NSIGHT SYSTEMS (nsys) PROFILING
# ============================================================================

echo "=========================================="
echo "Nsight Systems Profiling ($NUM_RUNS runs)"
echo "=========================================="

for run in $(seq 1 "$NUM_RUNS"); do
    echo ""
    echo "--- Run $run of $NUM_RUNS ---"
    
    OUTBASE="profiles/${TAG}_job${JOB_ID}_run${run}"
    
    echo "[nsys] writing ${OUTBASE}.nsys-rep"
    nsys profile \
        --trace=cuda,nvtx,osrt \
        --force-overwrite=true \
        -o "${OUTBASE}" \
        "$EXECUTABLE" "$DATASET_PATH"
    
    # Export statistics to CSV
    # Valid report names: https://docs.nvidia.com/nsight-systems/UserGuide/index.html
    REPORTS=(cuda_api_gpu_sum cuda_gpu_trace nvtx_gpu_proj_sum osrt_sum)
    
    for rep in "${REPORTS[@]}"; do
        REP_DIR="stats/${rep}"
        mkdir -p "$REP_DIR"
        
        echo "[stats] exporting $rep CSV to ${REP_DIR}"
        if ! nsys stats \
                --report="$rep" \
                --format=csv \
                --force-export=true \
                -o "${REP_DIR}/${TAG}_job${JOB_ID}_run${run}" \
                "${OUTBASE}.nsys-rep" 2>/dev/null; then
            echo "[warn] report '$rep' not available for this run; skipping"
        fi
    done
done

echo ""
echo "=========================================="
echo "Nsight Systems Profiling Complete"
echo "=========================================="
echo "Profiles : profiles/${TAG}_job${JOB_ID}_run*.nsys-rep"
echo "CSV stats: stats/*/${TAG}_job${JOB_ID}_run*.csv"
echo ""
echo "To view graphically:"
echo "  nsys-ui profiles/${TAG}_job${JOB_ID}_run1.nsys-rep"
echo ""

# ============================================================================
# NSIGHT COMPUTE (ncu) PROFILING
# ============================================================================

echo "=========================================="
echo "Nsight Compute Profiling"
echo "=========================================="

# Check GPU compute capability
SM_VER=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader | head -n1)
SM_MAJOR=${SM_VER%.*}

if (( SM_MAJOR >= 7 )); then
    # Check if ncu is available
    if ! command -v ncu &> /dev/null; then
        echo "[ncu] WARNING: ncu (Nsight Compute) not found in PATH"
        echo "[ncu] SKIPPED: Install CUDA Toolkit or add ncu to PATH"
    else
        NCU_BASE="ncu/${TAG}_job${JOB_ID}"
        
        echo "[ncu] profiling -> ${NCU_BASE}.ncu-rep"
        ncu --set full \
            --target-processes all \
            -f -o "${NCU_BASE}" \
            "$EXECUTABLE" "$DATASET_PATH"
        
        echo "[ncu] exporting metrics to CSV"
        
        # Key metrics for BFS analysis
        METRICS="gpu__time_duration.sum,\
sm__throughput.avg.pct_of_peak_sustained_elapsed,\
gpu__compute_memory_throughput.avg.pct_of_peak_sustained_elapsed,\
l1tex__t_sector_hit_rate.pct,\
lts__t_sector_hit_rate.pct,\
dram__bytes.sum.per_second,\
l1tex__throughput.avg.pct_of_peak_sustained_active,\
lts__throughput.avg.pct_of_peak_sustained_elapsed,\
gpu__dram_throughput.avg.pct_of_peak_sustained_elapsed,\
sm__warps_active.avg.pct_of_peak_sustained_active,\
sm__instruction_throughput.avg.pct_of_peak_sustained_active,\
sm__cycles_active.avg,\
sm__inst_executed.sum,\
sm__inst_executed_per_cycle_active.avg"
        
        ncu --import "${NCU_BASE}.ncu-rep" \
            --page raw \
            --csv \
            --metrics "$METRICS" \
            --log-file "${NCU_BASE}_metrics.csv"
        
        echo ""
        echo "=========================================="
        echo "Nsight Compute Profiling Complete"
        echo "=========================================="
        echo "Profile : ${NCU_BASE}.ncu-rep"
        echo "Metrics : ${NCU_BASE}_metrics.csv"
        echo ""
        echo "To view graphically:"
        echo "  ncu-ui ${NCU_BASE}.ncu-rep"
        echo ""
    fi
else
    echo "[ncu] SKIPPED: GPU compute capability ${SM_VER} (SM ${SM_MAJOR}x)"
    echo "[ncu] Nsight Compute requires SM >= 70 (Volta/Turing/Ampere/Hopper)"
    echo "[tip] Run on a V100, A100, H100, or RTX 20xx/30xx/40xx GPU"
    echo ""
fi

# ============================================================================
# SUMMARY
# ============================================================================

echo "=========================================="
echo "Profiling Complete!"
echo "=========================================="
echo ""
echo "Output files:"
echo "  Nsight Systems: profiles/${TAG}_job${JOB_ID}_run*.nsys-rep"
echo "  Statistics CSV: stats/*/"
echo "  Nsight Compute: ncu/${TAG}_job${JOB_ID}.ncu-rep"
echo ""
echo "Next steps:"
echo "  1. View profiles: nsys-ui profiles/${TAG}_job${JOB_ID}_run1.nsys-rep"
if (( SM_MAJOR >= 7 )) && command -v ncu &> /dev/null; then
    echo "  2. View detailed kernel metrics: ncu-ui ncu/${TAG}_job${JOB_ID}.ncu-rep"
fi
echo "  3. Analyze CSV files in stats/ directory"
echo ""
echo "Documentation:"
echo "  Nsight Systems: https://docs.nvidia.com/nsight-systems/"
echo "  Nsight Compute: https://docs.nvidia.com/nsight-compute/"
echo ""
