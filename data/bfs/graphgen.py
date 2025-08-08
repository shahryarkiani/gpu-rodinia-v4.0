"""
Graph Generator for BFS (Breadth-First Search) - Rodinia Benchmark

Usage:
    python graphgen.py <num_nodes> [filename_bit] [options]

Required:
    num_nodes        Number of nodes (minimum 20)

Optional:
    filename_bit     Custom name for output file (default: num_nodes)
                    Output will be "graph<filename_bit>.txt"

Additional Options:
    --min-edges N    Minimum edges per node (default: 2)
    --max-edges N    Maximum edges per node (default: 4)
    --min-weight N   Minimum edge weight (default: 1)
    --max-weight N   Maximum edge weight (default: 10)

Examples:
    python graphgen.py 1000                 # Creates graph1000.txt
    python graphgen.py 1000 test            # Creates graphtest.txt
    python graphgen.py 1000 --max-edges 6   # More edges per node
"""

import random
import argparse
import sys

# constants matching the C++ version
MIN_NODES = 20
MAX_NODES = sys.maxsize  # equivalent to ULONG_MAX
MIN_EDGES = 2
MAX_INIT_EDGES = 4  # nodes will have, on average, 2*MAX_INIT_EDGES edges
MIN_WEIGHT = 1
MAX_WEIGHT = 10

class Edge:
    def __init__(self, dest, weight):
        self.dest = dest
        self.weight = weight

def generate_graph(num_nodes, min_edges=MIN_EDGES, max_edges=MAX_INIT_EDGES, 
                  min_weight=MIN_WEIGHT, max_weight=MAX_WEIGHT):
    """Generate graph following the C++ implementation pattern"""
    # initialize graph structure similar to C++ version
    graph = [[] for _ in range(num_nodes)]  # list of lists for edges
    
    random.seed()  # similar to srand(time(NULL))
    
    # Generate graph edges
    for i in range(num_nodes):
        # calculate number of edges for this node
        num_edges = random.randint(min_edges, max_edges)
        
        for _ in range(num_edges):
            # choose target node
            node_id = random.randint(0, num_nodes - 1)
            weight = random.randint(min_weight, max_weight)
            
            # add edges in both directions (matching C++ behavior)
            graph[i].append(Edge(node_id, weight))
            graph[node_id].append(Edge(i, weight))
    
    return graph

def save_graph(graph, num_nodes, filename):
    """Save the graph in exact Rodinia BFS format matching C++ output"""
    print(f'Writing to file "{filename}"...')
    
    with open(filename, 'w') as f:
        # write number of nodes
        f.write(f"{num_nodes}\n")
        
        # write node data: starting edge index and number of edges
        total_edges = 0
        for i in range(num_nodes):
            num_edges = len(graph[i])
            f.write(f"{total_edges} {num_edges}\n")
            total_edges += num_edges
        
        # write source node (randomly chosen)
        f.write(f"\n{random.randint(0, num_nodes-1)}\n\n")
        
        # write total edges
        f.write(f"{total_edges}\n")
        
        # write edge list
        for i in range(num_nodes):
            for edge in graph[i]:
                f.write(f"{edge.dest} {edge.weight}\n")

def print_stats(graph, num_nodes):
    """Print basic statistics about the generated graph"""
    edge_counts = [len(edges) for edges in graph]
    total_edges = sum(edge_counts)
    
    print(f"\nGraph Statistics:")
    print(f"Nodes: {num_nodes}")
    print(f"Total Edges: {total_edges}")
    print(f"Average edges per node: {total_edges/num_nodes:.2f}")

def main():
    parser = argparse.ArgumentParser(
        description='Generate graph for Rodinia BFS benchmark',
        usage='%(prog)s <num_nodes> [filename_bit]'
    )
    parser.add_argument('num_nodes', type=int, help='Number of nodes')
    parser.add_argument('filename_bit', nargs='?', help='Optional filename bit')
    
    # some additional customization
    parser.add_argument('--min-edges', type=int, default=MIN_EDGES, 
                       help=f'Minimum edges per node (default: {MIN_EDGES})')
    parser.add_argument('--max-edges', type=int, default=MAX_INIT_EDGES,
                       help=f'Maximum edges per node (default: {MAX_INIT_EDGES})')
    parser.add_argument('--min-weight', type=int, default=MIN_WEIGHT,
                       help=f'Minimum edge weight (default: {MIN_WEIGHT})')
    parser.add_argument('--max-weight', type=int, default=MAX_WEIGHT,
                       help=f'Maximum edge weight (default: {MAX_WEIGHT})')
    
    args = parser.parse_args()
    
    # match the C++ verification
    if args.num_nodes < MIN_NODES or args.num_nodes > MAX_NODES:
        print(f"Error: Invalid argument: {args.num_nodes}", file=sys.stderr)
        sys.exit(1)
    
    # set filename in bit pattern
    filename_bit = args.filename_bit if args.filename_bit else str(args.num_nodes)
    filename = f"graph{filename_bit}.txt"
    
    print(f"Generating graph with {args.num_nodes} nodes...")
    
    graph = generate_graph(
        num_nodes=args.num_nodes,
        min_edges=args.min_edges,
        max_edges=args.max_edges,
        min_weight=args.min_weight,
        max_weight=args.max_weight
    )
    
    save_graph(graph, args.num_nodes, filename)
    print_stats(graph, args.num_nodes)

if __name__ == '__main__':
    main()