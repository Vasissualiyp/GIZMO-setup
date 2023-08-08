#!/bin/bash

cd gizmo

module load intel intelmpi gsl hdf5 fftw

#Compile and submit
make clean
make -j10
cd ..
./autosub.sh
