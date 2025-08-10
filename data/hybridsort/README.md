## Hybridsort datasets

This folder contains input data for the Hybridsort benchmark and scripts to generate more. Files are plain-text, space-separated floating-point numbers in [0, 1).

### File formats
- Format A (count-prefixed): first token is N (number of values), followed by N floats on the same line.
  - Example (`100.txt` begins with `100 ...`):
  - `100 0.174194 0.953338 0.944811 ...`
- Format B (generator output): N floats only, no leading count. Consumers should infer N by counting tokens.
  - Produced by `hybrid_gen.py`.

Notes
- Values use 6 decimal places by default.
- Files may be a single very long line. Do not assume one number per line.

### Existing files
- `100.txt`: sample with 100 values (count-prefixed)
- `500000.txt`: larger sample (~4.3 MB)

### Generate data
Using Python (recommended on all platforms):
```bash
python hybrid_gen.py <size> <name_suffix>
# writes <name_suffix>.txt with <size> random floats

# examples
python hybrid_gen.py 1000 1K
python hybrid_gen.py 100000 100K
```

Using the shell script (Linux/macOS, or Git Bash on Windows):
```bash
bash data_gen.sh
# generates 1K.txt, 10K.txt, 100K.txt, 1M.txt, 10M.txt, 100M.txt
```

### Verifying files
- Count tokens (works for both formats):
  - Python: `python -c "import sys;print(len(open(sys.argv[1]).read().split()))" <file>`
  - Bash: `tr -s ' \n' ' ' < <file> | wc -w`

### Consumers
Benchmarks should accept both formats (with or without leading N). If your loader requires one format, convert as needed (e.g., strip/insert the first token).


