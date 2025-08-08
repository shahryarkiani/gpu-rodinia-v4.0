from datetime import datetime
from optparse import OptionParser
import random
import sys

def format_size_str(size):
    """Convert size number to formatted string (e.g., 97000 to '97K')"""
    if size >= 1000000:
        return f"{size/1000000:.1f}M".replace('.0', '')
    elif size >= 1000:
        return f"{size//1000}K"
    return str(size)

if __name__ == '__main__':
    parser = OptionParser()
    parser.add_option('-s', '--size', type="int", default=100000, help='Number of elements')
    (options, args) = parser.parse_args()

    # check options
    if options.size <= 0:
        print("Error: Number of elements must be positive.")
        sys.exit()

    # Format size for filename
    size_str = format_size_str(options.size)
    output_file = f"cfd.domn.{size_str}"
    
    print(f"Generating input with {options.size:,} elements")
    print(f"Output file: {output_file}")

    random.seed(int(datetime.now().timestamp()))
    with open(output_file, 'w') as f:
        # write header line
        f.write(f'{options.size}\n')
        # number of floats
        for i in range(options.size):
            f.write(f'{random.uniform(0, 1):0.7f}   ')
            for j in range(4):
                f.write(f'{int(random.uniform(i - 10, i + 10))} ')
                for k in range(3):
                    f.write(f'{random.uniform(-0.5, 0.5):0.7f} ')
            f.write('\n')