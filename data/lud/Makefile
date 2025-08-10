CC = gcc
CFLAGS = -Wall -O2

# Target executable
TARGET = lud_gen

# Source file
SOURCE = simple_lud_generator.c

# Build the generator
$(TARGET): $(SOURCE)
	$(CC) $(CFLAGS) $(SOURCE) -o $(TARGET)

# Generate common matrix sizes
generate: $(TARGET)
	@echo "Generating common LUD matrix sizes..."
	./$(TARGET) 64
	./$(TARGET) 128
	./$(TARGET) 256
	./$(TARGET) 512
	./$(TARGET) 1024
	@echo "Generation complete!"

# Generate test sizes
test: $(TARGET)
	@echo "Generating test matrices..."
	./$(TARGET) 16
	./$(TARGET) 32
	@echo "Test generation complete!"

# Clean generated files
clean:
	rm -f $(TARGET)
	rm -f *.dat

# Clean only data files
clean-data:
	rm -f *.dat

.PHONY: generate test clean clean-data 