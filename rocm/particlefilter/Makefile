#makefile

include ../../common/make.config

CC := hipcc


all: naive float

naive: ex_particle_naive_seq.hip
	$(CC) -O3 -use_fast_math $< -o particlefilter_naive
	
float: ex_particle_float_seq.hip
	$(CC) -O3 -use_fast_math $< -o particlefilter_float

clean:
	rm particlefilter_naive particlefilter_float
