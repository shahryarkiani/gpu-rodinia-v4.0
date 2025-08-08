FLAGS := -Wno-write-strings -std=c++11

all: hotspot3D_generator

hotspot3D_generator: hotspot3D_generator.cpp
	g++ $(FLAGS) -o $@ $<

clean:
	rm -f hotspot3D_generator

.PHONY: all clean 