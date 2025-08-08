# CFD CUDA Implementation

## Overview
GPU-accelerated Computational Fluid Dynamics benchmark simulating 3D unstructured Euler equations for compressible fluid flow using finite volume method on tetrahedral meshes.

## CFD Variants

- **euler3d** - Standard precision, redundant flux computation
- **euler3d_double** - Double precision, redundant flux computation  
- **pre_euler3d** - Standard precision, pre-computed fluxes (faster)
- **pre_euler3d_double** - Double precision, pre-computed fluxes (faster)

## Building

### Standard Build
```bash
make clean
make
```

### Custom Work Group Sizes
```bash
make clean
make KERNEL_DIM="-DRD_WG_SIZE_1=128 -DRD_WG_SIZE_2=192 -DRD_WG_SIZE_3=128 -DRD_WG_SIZE_4=256"
```

**Work Group Parameters:**
- RD_WG_SIZE_1: initialize_variables kernel
- RD_WG_SIZE_2: compute_step_factor kernel  
- RD_WG_SIZE_3: compute_flux kernel
- RD_WG_SIZE_4: time_step kernel
- Default: 192 threads per block

## Running CFD Simulations

### Command Format
```bash
./<variant> <mesh_file>
```

### Examples
```bash
# Standard testing
./euler3d ../../data/cfd/cfd.domn.100K

# Large simulation with faster variant
./pre_euler3d ../../data/cfd/missile.domn.0.2M

# Double precision
./euler3d_double ../../data/cfd/fvcorr.domn.193K
```

### Available Test Data
Navigate to ../../data/cfd/ for mesh files:
- cfd.domn.97K / cfd.domn.100K (standard testing)
- fvcorr.domn.097K / fvcorr.domn.193K (alternative format)
- missile.domn.0.2M (large missile geometry)

## Algorithm Details
- **Method**: 3rd-order Runge-Kutta time integration
- **Parameters**: Mach 1.2, γ=1.4, 2000 iterations
- **Performance**: Pre-computed flux variants typically faster

## Credits
Original CFD codes by Andrew Corrigan (George Mason University) based on AIAA-2009-4001 paper.