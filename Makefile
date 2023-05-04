CC = g++
CFLAGS = -std=c++14 -O2 -Wall -fopenmp
LDFLAGS = -L/path/to/HighFive/lib -lhdf5 -fopenmp
INCLUDES = -I/path/to/HighFive/include -I/usr/include/eigen3

SRC = hdf5gen-openmp.cpp
OBJ = $(SRC:.cpp=.o)
TARGET = zeldovich_pancake

all: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ $^ $(LDFLAGS)

%.o: %.cpp
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

clean:
	rm -f $(OBJ) $(TARGET)

# Add a run target to execute the compiled binary
# Adjust the number of threads based on your CPU information
run: $(TARGET)
	export OMP_NUM_THREADS=14 && ./$(TARGET) ./output_directory

