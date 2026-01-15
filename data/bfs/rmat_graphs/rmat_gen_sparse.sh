#!/bin/bash

#Usage:  Required command line arguments:
#                -Number of edges. E.g., -nEdges 1021
#                -NUmber of vertices. E.g., -nVertices 51
#        Additional arguments:
#                -Output file (default: out.txt). E.g., -output myout.txt
#                -RMAT a parameter (default: 0.45). E.g., -a 0.42
#                -RMAT b parameter (default: 0.22). E.g., -b 0.42
#                -RMAT c parameter (default: 0.22). E.g., -c 0.42
#                -Number of worker CPU threads (default: queried/1). E.g., -threads 4
#                -Output should be sorted based on source index (default: not sorted). To sort: -sorted
#                -Allow edge to self (default:yes). To disable: -noEdgeToSelf
#                -Allow duplicate edges (default:yes). To disable: -noDuplicateEdges
#                -Will the graph be directed (default:yes). To make it undirected: -undirected
#                -Usage of available system memory (default: 0.5 which means up to half of available RAM may be requested). E.g., -memUsage 0.9


EDGE_FACTOR=8
EXEC="PaRMAT_gen"
CONVERT="convert_rmat_to_csr.py"

A=0.57
B=0.19
C=0.19
SRC_NODE=0

declare -A LABELS=(
  [1024]="1k"
  [2048]="2k"
  [4096]="4k"
  [8192]="8k"
  [16384]="16k"
  [32768]="32k"
  [65536]="64k"
  [131072]="128k"
  [262144]="256k"
  [524288]="512k"
  [1048576]="1M"
  [2097152]="2M"
  [4194304]="4M"
  [8388608]="8M"
  [16777216]="16M"
  [33554432]="32M"
)

for V in 1024 2048 4096 8192 16384 32768 65536 131072 262144 524288 1048576 2097152 4194304 8388608 16777216 33554432
do
    LABEL=${LABELS[$V]}
    E=$((V * EDGE_FACTOR))
    RAW_OUT="rmat_${LABEL}.txt"
    ROD_OUT="graph${LABEL}_sparse.txt"

    echo "--------------------------------------------"
    echo "[1] Generating $RAW_OUT ($V vertices, $E edges)"
    $EXEC -nVertices $V -nEdges $E -a $A -b $B -c $C \
          -sorted -noDuplicateEdges -noEdgeToSelf -undirected \
          -output $RAW_OUT

    echo "[2] Converting to Rodinia format -> $ROD_OUT"
    python3 $CONVERT $RAW_OUT $ROD_OUT $SRC_NODE

    echo "[?] Done: $ROD_OUT"
    echo
done

echo "? All RMAT graphs generated and converted successfully."
