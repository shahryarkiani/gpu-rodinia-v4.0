# Makefile for BFS NVTX Profiling (with GPU tag)
include ../../../common/make.config

NVCC         = $(CUDA_DIR)/bin/nvcc
INCLUDES     = -I$(CUDA_DIR)/include -I../util
LIBS         = -L$(CUDA_DIR)/lib64

# Change this to the correct gpu and corresponding SM

GPU        ?= a100
ARCH       ?= sm_80

NVCCFLAGS  = -O3 -lineinfo -use_fast_math -std=c++11 -arch=$(ARCH)

SRC        = bfs_gunrock.cu
TARGET     = bfs_gunrock_$(GPU).out

all: $(TARGET)

$(TARGET): $(SRC)
	$(NVCC) $(INCLUDES) $(LIBS) -o $@ $< $(NVCCFLAGS)

clean:
	rm -f bfs_gunrock_*.out *.o *.linkinfo