#!/bin/bash

# CFD Data Generation Script
# Generates datasets from small to large for CFD benchmark testing

echo "Generating CFD datasets..."

# Small datasets (for quick testing)
echo "Generating small datasets..."
python cfd_gen.py -s 1000      # 1K elements
python cfd_gen.py -s 5000      # 5K elements
python cfd_gen.py -s 10000     # 10K elements
python cfd_gen.py -s 25000     # 25K elements

# Medium datasets
echo "Generating medium datasets..."
python cfd_gen.py -s 50000     # 50K elements
python cfd_gen.py -s 75000     # 75K elements
python cfd_gen.py -s 97000     # 97K elements (matches existing)
python cfd_gen.py -s 100000    # 100K elements (matches existing)

# Large datasets
echo "Generating large datasets..."
python cfd_gen.py -s 150000    # 150K elements
python cfd_gen.py -s 193000    # 193K elements (matches existing fvcorr)
python cfd_gen.py -s 200000    # 200K elements (matches existing missile)
python cfd_gen.py -s 250000    # 250K elements

# Very large datasets (for performance testing)
echo "Generating very large datasets..."
python cfd_gen.py -s 500000    # 500K elements
python cfd_gen.py -s 750000    # 750K elements
python cfd_gen.py -s 1000000   # 1M elements
python cfd_gen.py -s 2000000   # 2M elements

echo "CFD dataset generation complete!"
echo ""
echo "Generated files:"
ls -lh cfd.domn.*
echo ""
echo "To test with CFD benchmark:"
echo "cd ../../cuda/cfd"
echo "make"
echo "./euler3d ../../data/cfd/cfd.domn.1K"
