from itertools import product

# Define the parameters and their values
parameters = {
    "Config.sh": [
        ("PMGRID", [16, 32]),
        ("MULTIPLEDOMAINS", [16, 32]),
    ],
    "zel.params": [
        ("TimeBetSnapshots", [0.01, 0.02]),
    ],
}

# Create an empty list to store the lines
lines = []

# Iterate through the files and their parameters
for filename, params in parameters.items():
    # Extract the parameter names and values
    param_names, param_values = zip(*params)
    
    # Iterate through the cartesian product of the parameter values
    for values in product(*param_values):
        # Combine the parameter names and values
        param_str = " ".join(f"{name}={value}" for name, value in zip(param_names, values))
        line = f"{filename}: {param_str}"
        lines.append(line)

    # Add separator
    lines.append("###")

# Write the lines to the configs.txt file
with open("configs.txt", "w") as file:
    file.write("\n".join(lines))

print("configs.txt file generated successfully!")

