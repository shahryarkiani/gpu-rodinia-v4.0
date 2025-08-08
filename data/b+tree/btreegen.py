import sys
import os

def generate_data(size, name_suffix):
    """Generate sequential data and commands"""
    # Generate filenames
    data_file = f"btree{name_suffix}.txt"
    command_file = f"command{name_suffix}.txt"
    
    # Generate data file
    print(f"Generating data file for size {size:,} numbers")
    with open(data_file, "w") as f:
        # First line is the total count
        f.write(f"{size}\n")
        # Generate sequential numbers
        for i in range(1, size + 1):
            f.write(f"{i}\n")
    
    # Generate command file
    # Scale searches based on data size
    k_searches = min(size // 100, 50000)  # Cap at 50K searches
    j_searches = k_searches // 2          # Half as many range searches
    range_size = max(size // 1000, 100)   # Range size is 0.1% of data size
    
    with open(command_file, "w") as f:
        f.write(f"k {k_searches}\n")
        f.write(f"j {j_searches} {range_size}\n")
    
    # Print summary
    print(f"\nFiles generated:")
    print(f"  {data_file}: {size:,} numbers")
    print(f"  {command_file}:")
    print(f"    - {k_searches:,} point searches")
    print(f"    - {j_searches:,} range searches (size: {range_size:,})")

def main():
    # Check command line arguments
    if len(sys.argv) != 3:
        print("Usage: python btreegen.py <size> <name_suffix>")
        print("Examples:")
        print("  python btreegen.py 1000 1k      # Creates btree1k.txt")
        print("  python btreegen.py 10000 10k    # Creates btree10k.txt")
        print("  python btreegen.py 1000000 1M   # Creates btree1M.txt")
        print("  python btreegen.py 10000000 10M # Creates btree10M.txt")
        sys.exit(1)

    # Get size and name suffix from command line
    try:
        size = int(sys.argv[1])
        if size <= 0:
            raise ValueError("Size must be positive")
    except ValueError:
        print("Error: Please provide a valid positive number for size")
        sys.exit(1)
    
    name_suffix = sys.argv[2]
    
    # Generate data
    generate_data(size, name_suffix)

if __name__ == "__main__":
    main()