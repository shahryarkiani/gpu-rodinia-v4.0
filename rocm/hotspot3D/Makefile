CC := hipcc

SRC = 3D.hip

EXE = 3D 

OUTPUT = *.out

release: $(SRC)
	$(CC) $(KERNEL_DIM) $(FLAGS) $(SRC) -o $(EXE) -O3

enum: $(SRC)
	$(CC) $(KERNEL_DIM) $(FLAGS) -deviceemu $(SRC) -o $(EXE) -O3

debug: $(SRC)
	$(CC) $(KERNEL_DIM) $(FLAGS) -g $(SRC) -o $(EXE) -O3
debugenum: $(SRC)
	$(CC) $(KERNEL_DIM) $(FLAGS) -g -deviceemu $(SRC) -O3

clean: $(SRC)
	rm -f $(EXE) $(EXE).linkinfo $(OUTPUT) 
