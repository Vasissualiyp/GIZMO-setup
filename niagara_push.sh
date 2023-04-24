#!/bin/bash

SERVER="vasissua@niagara.scinet.utoronto.ca"
SCRATCH="/scratch/m/murray/vasissua"
SERVER_FOLDER="/Zeldovich3"

IN_FILE="IC.hdf5"

python hdf5zelgenglass.py .

rsync $IN_FILE  "$SERVER:""$SCRATCH""$SERVER_FOLDER"
