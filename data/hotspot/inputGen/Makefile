FLAGS := -Wno-write-strings

all: hotspot_generator

hotspot_generator: hotspot_generator.cpp
	g++ $(FLAGS) -o $@ $<

clean:
	rm -f hotspot_generator