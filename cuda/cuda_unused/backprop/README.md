# Backpropagation CUDA Implementation

## Overview

GPU-accelerated implementation of the backpropagation neural network training algorithm. This benchmark demonstrates parallel computation of neural network forward propagation and backpropagation weight updates using CUDA kernels.

## Algorithm Description

The backpropagation algorithm consists of two main phases:

1. **Forward Propagation**: Input signals flow forward through the network
   - Input layer → Hidden layer → Output layer
   - Each layer applies weights and activation functions

2. **Backward Propagation**: Error signals propagate backward to update weights
   - Compute output layer errors
   - Propagate errors to hidden layers
   - Update weights using gradient descent

## Network Architecture

- **Configurable layers**: Input, Hidden, and Output layers
- **Activation function**: Sigmoid function used throughout the network
- **Weight updates**: Uses gradient descent with momentum
- **Learning parameters**:
  - Learning rate (η) = 0.3
  - Momentum = 0.3

## Building

### Standard Build
```bash
make clean
make
```

### Alternative Build (NVIDIA-specific)
```bash
make -f Makefile_nvidia
```

## Running the Benchmark

### Command Format
```bash
./backprop <input_size>
```

### Example Usage
```bash
# Standard test with ~2M input neurons
./backprop 2097152

# Smaller test for quick verification
./backprop 65536

# Large scale test
./backprop 8388608
```

**Parameters:**
- `input_size`: Number of input neurons (determines network size)

### Network Configuration
The network automatically configures based on input size:
- **Input layer**: `input_size` neurons
- **Hidden layer**: `input_size / 2` neurons  
- **Output layer**: `1` neuron

## CUDA Implementation Details

### Kernel Organization
- **Thread blocks**: 256 threads per block
- **Shared memory**: 16x16 tiles for weight matrices
- **Memory access**: Optimized coalesced global memory access
- **Parallelization**: Both forward and backward passes parallelized

### Memory Management
- **Input data**: Generated synthetically (no external files needed)
- **Weight matrices**: Allocated in GPU global memory
- **Shared memory**: Used for tile-based matrix operations
- **Host-device transfers**: Minimized for performance

## Performance Characteristics

- **Computational pattern**: Dense matrix operations
- **Memory access**: Regular, coalesced access patterns
- **Scalability**: Performance scales with input size and GPU cores
- **Bottlenecks**: Memory bandwidth for large networks

## Algorithm Applications

Backpropagation is fundamental to:
- **Neural network training**: Core algorithm for deep learning
- **Pattern recognition**: Image, speech, and text classification
- **Function approximation**: Non-linear regression problems
- **Control systems**: Adaptive controllers and system identification

## Data Generation

This benchmark is **self-contained** and generates its training data internally:
- **Input patterns**: Random floating-point values
- **Target outputs**: Synthetically generated targets
- **Weight initialization**: Random initial weights
- **No external data files required**

## Performance Testing

Different input sizes suitable for various testing scenarios:

- **Small** (64K - 256K): Algorithm verification and debugging
- **Medium** (1M - 4M): Standard benchmarking
- **Large** (8M+): Performance stress testing and memory evaluation

The computational complexity scales quadratically with network size, making it suitable for evaluating GPU performance across different scales.

## Credits

Based on standard backpropagation neural network training algorithms. Implementation optimized for GPU parallel execution using CUDA.
