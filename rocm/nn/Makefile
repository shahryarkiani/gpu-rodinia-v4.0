LOCAL_CC = gcc -g -O3 -Wall
CC := hipcc

all : nn hurricane_gen

clean :
	rm -rf *.o nn hurricane_gen

nn : nn_rocm.hip
	$(CC) -o $@ $<

hurricane_gen : ../../cuda/nn/hurricane_gen.c
	$(LOCAL_CC) -o $@ $< -lm

#data :
#	mkdir data
#	./gen_dataset.sh
