include ../../common/make.config

HIPCC = hipcc

HIP_FLAGS =

TARGET_G = sc_gpu


# make dbg=1 tells nvcc to add debugging symbols to the binary
ifeq ($(dbg),1)
	HIP_FLAGS += -g -O0
else
	HIP_FLAGS += -O3
endif

# make emu=1 compiles the CUDA kernels for emulation
ifeq ($(emu),1)
	HIP_FLAGS += -deviceemu
endif

# make dp=1 compiles the CUDA kernels with double-precision support
ifeq ($(dp),1)
	HIP_FLAGS += --gpu-name sm_13
endif


$(TARGET_G): streamcluster.cpp streamcluster.hip streamcluster_header.hip
	$(HIPCC) $(NVCC_FLAGS) streamcluster.cpp streamcluster.hip streamcluster_header.hip -o $(TARGET_G)
	

clean:
	rm -f *.o *~ *.txt $(TARGET_G) *.linkinfo
	
