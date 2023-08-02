import numpy as np

# define the start time, end time, and number of snapshots
t1 = 0.02
t2 = 0.03
n = 100

# generate the geometric sequence of snapshot times
times = np.logspace(np.log10(t1), np.log10(t2), n)
#times = np.geomspace(t1, t2, n)

# print the snapshot times
print(times)

# write the snapshot times to a file
filename = "../snapshot_times.txt"
with open(filename, 'w') as f:
	for t in times:
		f.write(str(t) + "\n")
