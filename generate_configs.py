import numpy as np
from itertools import product


generated_softenings = np.ones(5) * 8 # since 1000/128 ~ 2^3
for i in range(np.size(generated_softenings)):
    generated_softenings[i] = generated_softenings[i] * 10**(-i-7)
generated_memory = [3500, 3800, 4000, 15000, 30000]


powers_of_2 = np.ones(3) * 16
for i in range(np.size(powers_of_2)):
    powers_of_2[i] =  powers_of_2[i] * 2**i
powers_of_2 = powers_of_2.astype(int)


# Define the parameters and their values
parameters = {
    "Config.sh": [
        #("ADAPTIVE_GRAVSOFT_FORALL", [2, 3]),
        ("MULTIPLEDOMAINS", ['-', 4, 8, 16, 32, 64, 128, 256]),
        #("PMGRID", 4*powers_of_2),
    ],
    "zel.params": [
        #("Softening_Type0", generated_softenings.tolist()), # Convert to Python list
        ("MaxMemSize", generated_memory), # Convert to Python list
    ],
}


# Define parameters to remove only for the first run
remove_first_run = {
    "Config.sh": [], # Example of removal only for the first run
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
