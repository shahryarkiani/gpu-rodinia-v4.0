#!/usr/bin/env python3
"""
Fast converter from RMAT edge list format to Rodinia CSR format.

RMAT format (input):
    source destination
    source destination
    ...

Rodinia CSR format (output):
    <num_nodes>
    <start_edge_idx_0> <num_edges_0>
    <start_edge_idx_1> <num_edges_1>
    ...
    
    <source_node>
    
    <total_edges>
    <dest_0> <weight_0>
    <dest_1> <weight_1>
    ...
"""

import numpy as np
import sys
from collections import defaultdict

def convert_rmat_to_rodinia(input_file, output_file, source_node=0):
    """
    Convert RMAT edge list to Rodinia CSR format.
    
    Args:
        input_file: Path to RMAT edge list file
        output_file: Path to output Rodinia format file
        source_node: Starting node for BFS (default: 0)
    """
    print(f"Reading RMAT edge list from {input_file}...")
    
    # Read edge list - optimized for speed
    try:
        edges = np.loadtxt(input_file, dtype=np.int32, ndmin=2)
        if edges.shape[0] == 0:
            print("Error: Empty input file")
            return
        
        if edges.shape[1] != 2:
            print(f"Error: Expected 2 columns, got {edges.shape[1]}")
            return
            
    except Exception as e:
        print(f"Error reading file: {e}")
        return
    
    sources = edges[:, 0]
    destinations = edges[:, 1]
    num_edges = len(edges)
    
    print(f"  Loaded {num_edges:,} edges")
    
    # Find number of nodes
    num_nodes = max(sources.max(), destinations.max()) + 1
    print(f"  Detected {num_nodes:,} nodes (0 to {num_nodes-1})")
    
    # Build CSR format using efficient sorting
    print("Building CSR format...")
    
    # Sort edges by source node for CSR construction
    sort_idx = np.argsort(sources, kind='stable')
    sources_sorted = sources[sort_idx]
    destinations_sorted = destinations[sort_idx]
    
    # Build row offsets and count edges per node
    node_edge_counts = np.bincount(sources_sorted, minlength=num_nodes)
    row_offsets = np.zeros(num_nodes, dtype=np.int64)
    row_offsets[1:] = np.cumsum(node_edge_counts[:-1])
    
    # Create edge list in CSR order
    edge_list = destinations_sorted
    
    print(f"  CSR construction complete")
    print(f"  Average degree: {num_edges/num_nodes:.2f}")
    print(f"  Max degree: {node_edge_counts.max()}")
    
    # Write to Rodinia format
    print(f"Writing Rodinia format to {output_file}...")
    
    with open(output_file, 'w') as f:
        # Write number of nodes
        f.write(f"{num_nodes}\n")
        
        # Write node information (start_index, num_edges)
        for i in range(num_nodes):
            f.write(f"{row_offsets[i]} {node_edge_counts[i]}\n")
        
        # Empty line
        f.write("\n")
        
        # Write source node
        f.write(f"{source_node}\n")
        
        # Empty line
        f.write("\n")
        
        # Write total number of edges
        f.write(f"{num_edges}\n")
        
        # Write edge list (destination, weight)
        # For unweighted graphs, use weight = 1
        for dest in edge_list:
            f.write(f"{dest} 1\n")
    
    print(f"Conversion complete!")
    print(f"  Output: {output_file}")
    print(f"  Nodes: {num_nodes:,}")
    print(f"  Edges: {num_edges:,}")
    print(f"  Source node: {source_node}")


def main():
    if len(sys.argv) < 2:
        print("Usage: python convert_rmat_to_rodinia.py <input_rmat_file> [output_file] [source_node]")
        print("\nExample:")
        print("  python convert_rmat_to_rodinia.py out.txt graph.txt 0")
        print("\nDefault output file: <input>_rodinia.txt")
        print("Default source node: 0")
        sys.exit(1)
    
    input_file = sys.argv[1]
    
    # Determine output file
    if len(sys.argv) >= 3:
        output_file = sys.argv[2]
    else:
        # Generate default output filename
        if input_file.endswith('.txt'):
            output_file = input_file[:-4] + '_rodinia.txt'
        else:
            output_file = input_file + '_rodinia.txt'
    
    # Get source node
    source_node = int(sys.argv[3]) if len(sys.argv) >= 4 else 0
    
    convert_rmat_to_rodinia(input_file, output_file, source_node)


if __name__ == "__main__":
    main()



