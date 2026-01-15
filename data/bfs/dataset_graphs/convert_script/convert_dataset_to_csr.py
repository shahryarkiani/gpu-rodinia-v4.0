#!/usr/bin/env python3
import argparse
import gzip
import bz2
import io
import sys
from collections import defaultdict

def smart_open(path):
    path = str(path)
    if path.endswith(".gz"):
        return io.TextIOWrapper(gzip.open(path, "rb"), encoding="utf-8", newline="")
    if path.endswith(".bz2"):
        return io.TextIOWrapper(bz2.open(path, "rb"), encoding="utf-8", newline="")
    return open(path, "r", encoding="utf-8", newline="")

def parse_edge(line):
    # Accept: "u v" (optionally more columns; ignore extras)
    parts = line.strip().split()
    if len(parts) < 2:
        return None
    try:
        u = int(parts[0]); v = int(parts[1])
    except ValueError:
        return None
    return u, v

def first_pass(path, skip_comments=True, one_based=False, relabel=False, undirected=False, drop_self_loops=True):
    """
    Return:
      - n (num nodes; if relabel=True this is len(id_map))
      - deg (list of degrees per node) or dict if relabel=True
      - id_map (dict original->compact) if relabel=True else None
      - max_id (only if not relabel)
    """
    if relabel:
        id_set = set()
    max_id = -1
    deg = defaultdict(int) if relabel else None

    with smart_open(path) as f:
        for raw in f:
            s = raw.strip()
            if not s:
                continue
            if skip_comments and (s[0] == "#" or s[0] == "%"):
                continue
            pv = parse_edge(s)
            if pv is None:  # non-edge line; ignore
                continue
            u, v = pv
            if one_based:
                u -= 1; v -= 1
            if drop_self_loops and u == v:
                continue
            if relabel:
                id_set.add(u); id_set.add(v)
            else:
                if u > max_id: max_id = u
                if v > max_id: max_id = v

    if relabel:
        # Compact IDs to 0..n-1
        id_list = sorted(id_set)
        id_map = {orig:i for i,orig in enumerate(id_list)}
        n = len(id_list)
        deg = [0]*n
        # Second scan to count degrees quickly
        with smart_open(path) as f:
            for raw in f:
                s = raw.strip()
                if not s or (skip_comments and (s[0] == "#" or s[0] == "%")):
                    continue
                pv = parse_edge(s)
                if pv is None:
                    continue
                u, v = pv
                if one_based:
                    u -= 1; v -= 1
                if drop_self_loops and u == v:
                    continue
                ui = id_map[u]; vi = id_map[v]
                deg[ui] += 1
                if undirected:
                    deg[vi] += 1
        return n, deg, id_map, None
    else:
        if max_id < 0:
            return 0, [0], None, -1
        n = max_id + 1
        deg = [0]*n
        with smart_open(path) as f:
            for raw in f:
                s = raw.strip()
                if not s or (skip_comments and (s[0] == "#" or s[0] == "%")):
                    continue
                pv = parse_edge(s)
                if pv is None:
                    continue
                u, v = pv
                if one_based:
                    u -= 1; v -= 1
                if drop_self_loops and u == v:
                    continue
                deg[u] += 1
                if undirected:
                    deg[v] += 1
        return n, deg, None, max_id

def build_csr(path, n, deg, id_map=None, skip_comments=True, one_based=False, undirected=False,
              drop_self_loops=True, dedup=True, sort_neighbors=True):
    """
    Build CSR (row_ptr, col_ind). Neighbors optionally deduped and sorted.
    Two-pass: we already have 'deg' from pass-1. If dedup is requested, we build
    temporary sets then flatten (memory tradeoff).
    """
    # If dedup or sorting needed robustly, easiest is to build adjacency lists then flatten.
    # For very large graphs, this uses memory ~ O(m). That's typical for CSR build anyway.
    adj = [set() if dedup else [] for _ in range(n)]

    def map_id(x):
        return id_map[x] if id_map is not None else x

    with smart_open(path) as f:
        for raw in f:
            s = raw.strip()
            if not s:
                continue
            if skip_comments and (s[0] == "#" or s[0] == "%"):
                continue
            pv = parse_edge(s)
            if pv is None:
                continue
            u, v = pv
            if one_based:
                u -= 1; v -= 1
            if drop_self_loops and u == v:
                continue
            ui = map_id(u); vi = map_id(v)
            if dedup:
                adj[ui].add(vi)
                if undirected:
                    adj[vi].add(ui)
            else:
                adj[ui].append(vi)
                if undirected:
                    adj[vi].append(ui)

    # Prepare row_ptr and col_ind
    row_ptr = [0]*(n+1)
    for i in range(n):
        row_ptr[i+1] = row_ptr[i] + (len(adj[i]) if dedup else len(adj[i]))

    m = row_ptr[-1]
    col_ind = [0]*m

    # Fill col_ind
    for i in range(n):
        nbrs = adj[i]
        if dedup:
            nbrs = list(nbrs)
        if sort_neighbors:
            nbrs.sort()
        start = row_ptr[i]
        col_ind[start:start+len(nbrs)] = nbrs

    return row_ptr, col_ind

def write_csr_text(path_out, n, m, row_ptr, col_ind):
    with open(path_out, "w", encoding="utf-8") as out:
        out.write(f"{n} {m}\n")
        out.write(" ".join(map(str, row_ptr)) + "\n")
        out.write(" ".join(map(str, col_ind)) + "\n")

def write_rodinia_bfs_text(path_out, n, m, row_ptr, col_ind, source=0):
    """
    Rodinia BFS text layout (weights set to 1):
      <num_nodes>
      <row_ptr[i]> <degree_i>   for i=0..n-1
      [blank line]
      <source_node>
      [blank line]
      <total_edges>
      <dst_0> 1
      <dst_1> 1
      ...
    """
    with open(path_out, "w", encoding="utf-8") as out:
        out.write(f"{n}\n")
        for i in range(n):
            deg_i = row_ptr[i+1] - row_ptr[i]
            out.write(f"{row_ptr[i]} {deg_i}\n")
        out.write("\n")
        out.write(f"{source}\n\n")
        out.write(f"{m}\n")
        for j in range(m):
            out.write(f"{col_ind[j]} 1\n")

def main():
    ap = argparse.ArgumentParser(description="Convert edge list graph to CSR (and optional Rodinia BFS text).")
    ap.add_argument("input", help="Input edge list file (.txt, .gz, .bz2). Lines like 'u v'. Comments starting with # or % are ignored.")
    ap.add_argument("output", help="Output file (text).")
    ap.add_argument("--format", choices=["csr_text", "rodinia"], default="rodinia",
                    help="Output format. 'csr_text' or 'rodinia' (default).")
    ap.add_argument("--undirected", action="store_true", help="Make the graph undirected by adding reverse edges.")
    ap.add_argument("--one-based", action="store_true", help="Treat input node IDs as 1-based; convert to 0-based.")
    ap.add_argument("--keep-self-loops", action="store_true", help="Keep self loops (u==v). Default: dropped.")
    ap.add_argument("--no-dedup", action="store_true", help="Do not deduplicate parallel edges.")
    ap.add_argument("--no-sort", action="store_true", help="Do not sort neighbor lists.")
    ap.add_argument("--relabel", action="store_true", help="Relabel non-contiguous IDs to 0..n-1 (use if IDs are sparse).")
    ap.add_argument("--source", type=int, default=0, help="Source node for Rodinia output (default: 0).")
    args = ap.parse_args()

    drop_self = not args.keep_self_loops
    dedup = not args.no_dedup
    sort_neighbors = not args.no_sort

    # Pass 1: count degrees (and optionally relabel)
    n, deg, id_map, _ = first_pass(
        args.input,
        skip_comments=True,
        one_based=args.one_based,
        relabel=args.relabel,
        undirected=args.undirected,
        drop_self_loops=drop_self
    )

    if n == 0:
        print("Input appears empty or unparsable.", file=sys.stderr)
        sys.exit(1)

    # Pass 2: build CSR
    row_ptr, col_ind = build_csr(
        args.input,
        n, deg,
        id_map=id_map,
        skip_comments=True,
        one_based=args.one_based,
        undirected=args.undirected,
        drop_self_loops=drop_self,
        dedup=dedup,
        sort_neighbors=sort_neighbors
    )

    m = row_ptr[-1]

    if args.format == "csr_text":
        write_csr_text(args.output, n, m, row_ptr, col_ind)
    else:
        # Rodinia BFS text format
        source = args.source
        if args.relabel and source != 0:
            # If user passed a *original* source when relabeling, they likely want it remapped.
            # We can't know without context; safest is to warn if out-of-range.
            if source >= n or source < 0:
                print(f"Warning: source {source} is out of range after relabeling (n={n}). Using 0.", file=sys.stderr)
                source = 0
        write_rodinia_bfs_text(args.output, n, m, row_ptr, col_ind, source=source)

    print(f"Done. Nodes: {n}, Edges (stored): {m}")
    print(f"Wrote: {args.output}")

if __name__ == "__main__":
    main()

