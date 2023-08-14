from itertools import product

# Define the values for the parameters
pmgrid_values = [16, 32]
multipledomains_values = [16, 32]
timebetsnapshots_values = [0.01, 0.02]

# Create an empty list to store the lines
lines = []

# Iterate through the cartesian product of the parameter values
for pmgrid, multipledomains, timebetsnapshots in product(pmgrid_values, multipledomains_values, timebetsnapshots_values):
    config_line = f"Config.sh: PMGRID={pmgrid} MULTIPLEDOMAINS={multipledomains}"
    params_line = f"zel.params: TimeBetSnapshots={timebetsnapshots}"
    lines.append(config_line)
    lines.append(params_line)
    lines.append("###")

# Write the lines to the configs.txt file
with open("configs.txt", "w") as file:
    file.write("\n".join(lines))

print("configs.txt file generated successfully!")

