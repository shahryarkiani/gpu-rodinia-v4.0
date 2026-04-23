CC = gcc
HIPCC = hipcc

DEFS += \
		-DGPU_TIMER \
		$(SPACE)

HIPCCFLAGS += -I../common \
			 -O3 \
			 -use_fast_math \
			 $(SPACE)

CFLAGS += -I../common \
			-I/usr/include/rocm \
		  -O3 \
		  -Wall \
		  $(SPACE)

# Add source files here
EXECUTABLE  := lud_rocm
# Cuda source files (compiled with cudacc)
CUFILES     := lud_kernel.hip
# C/C++ source files (compiled with gcc / c++)
CCFILES     := lud.c ../common/common.c

OBJS = ../common/common.o lud.o lud_kernel.o

.PHONY: all clean 
all : $(EXECUTABLE)

.c.o : 
	$(HIPCC) $(KERNEL_DIM) $(HIPCCFLAGS) $(DEFS) -o $@ -c $<

%.o:	%.hip
	$(HIPCC) $(KERNEL_DIM) $(HIPCCFLAGS) $(DEFS) -o $@ -c $<

clang: $(SRC)
	clang++ lud.cu lud_kernel.cu ../common/common.c -o $(EXECUTABLE) \
		-I../common -I../../util --cuda-gpu-arch=sm_20 \
		-L/usr/local/cuda/lib64 -lcudart_static -ldl -lrt -pthread -DTIMING

$(EXECUTABLE) : $(OBJS)
	$(HIPCC) $(HIPCCFLAGS) -o $@  $?

clean:
	rm -f $(EXECUTABLE) $(OBJS) *.linkinfo
