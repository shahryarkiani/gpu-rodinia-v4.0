HIPCC         = hipcc
INCLUDES     = -I/opt/rocm/include/roctracer/
LIBS         = -L/opt/rocm/lib

# Change this to the correct gpu and corresponding SM
# gfx942 == MI300
ARCH       ?= gfx942

NVCCFLAGS  = -O3 -use_fast_math -std=c++11 --offload-arch=$(ARCH)

SRC        = bfs_gunrock.hip
TARGET     = bfs_gunrock_$(GPU).out

all: $(TARGET)

$(TARGET): $(SRC)
	$(HIPCC) $(INCLUDES) $(LIBS) -o $@ $< $(NVCCFLAGS)

clean:
	rm -f bfs_gunrock_roctx_*.out *.o *.linkinfo