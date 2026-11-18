CXX      ?= g++
CXXFLAGS ?= -O3 -march=native -std=c++17 -Wall -Wextra -fopenmp
BIN      := build/swapcore

$(BIN): src/main.cpp src/core.hpp src/solve.hpp src/construct.hpp
	@mkdir -p build
	$(CXX) $(CXXFLAGS) -o $@ src/main.cpp

clean:
	rm -rf build

.PHONY: clean
