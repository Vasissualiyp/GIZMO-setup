#!/bin/bash

rm -f snapshot_000.hdf5
rm -f *.png
python hdf5zelgenglass.py .
mv IC.hdf5 snapshot_000.hdf5
python snapshots_to_plots.py
#cp snapshot_000.hdf5 snapshot_001.hdf5
#mv IC.hdf5 snapshot_001.hdf5
gwenview *.png
