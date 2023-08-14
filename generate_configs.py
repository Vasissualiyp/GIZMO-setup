import numpy as np
from itertools import product

# Define the parameters and their values
generated_softenings = np.ones(5) * 1000 / 128
for i in range(np.size(generated_softenings)):
    generated_softenings[i] = generated_softenings[i] * 10**(-i)

parameters = {
    "Config.sh": [
        #("PMGRID", [16, 32]),
        #("MULTIPLEDOMAINS", [16, 32]),
    ],
    "zel.params": [
        ("Softening_Type0", generated_softenings.tolist()), # Convert to Python list
    ],
}


# Define parameters to remove only for the first run
remove_first_run = {
    "Config.sh": ["PMGRID", "MULTIPLEDOMAINS"], # Example of removal only for the first run
}

# Create an empty list to store the lines
lines = []

# Iterate through the files and their parameters
for filename, params in parameters.items():
    if params: # Check if params not empty
        # Extract the parameter names and values
        param_names, param_values = zip(*params)

        # Handle removal only for the first run
        if filename in remove_first_run:
            param_str = " ".join(f"{name}={value}" for name, value in zip(param_names, param_values[0]))
            for param_to_remove in remove_first_run[filename]:
                param_str += f" -{param_to_remove}"
            line = f"{filename}: {param_str}"
            lines.append(line)
            lines.append("###")

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
