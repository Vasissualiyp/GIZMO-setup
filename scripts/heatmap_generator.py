import matplotlib.pyplot as plt
import os
import numpy as np

# Range of attempts to consider (inclusive)
#attempt_range = (41, 100)
attempt_range = (188, 253)
zero_runtime_log_addition = 60

generated_softenings = np.ones(6) * 8 # since 1000/128 ~ 2^3
for i in range(np.size(generated_softenings)):
    generated_softenings[i] = generated_softenings[i] * 10**(-2*(i-3)-5)

# Example usage
"""
parameters = {
    "MULTIPLEDOMAINS": [0, 4, 8, 16, 32, 64, 128, 256, 512, 1024],
    "MemSize": [30000, 60000, 100000, 150000, 180000, 200000]
}
parameters = {
    "MULTIPLEDOMAINS": [0, 4, 8, 16, 32, 64, 128, 256],
    "MemSize": [3500, 3800, 4000, 15000, 30000]
}
"""
parameters = {
    "MULTIPLEDOMAINS": [0, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048],
    #"MemSize": [20000, 30000, 40000, 50000, 60000, 70000]
    "Softening": generated_softenings,
}

# Plot heatmap {{{

# Function to get max timestep from cpu.txt {{{
def get_max_timestep(attempt_path):
    cpu_file = os.path.join(attempt_path, 'cpu.txt')
    if not os.path.exists(cpu_file):
        return None

    max_timestep = 0
    with open(cpu_file, 'r') as file:
        for line in file.readlines():
            if line.startswith('Step'):
                timestep = int(line.split(',')[0].split()[1])
                max_timestep = max(max_timestep, timestep)

    return max_timestep
# }}}

# Modified plot_heatmap function {{{
def plot_heatmap(parameters, attempt_range=None, highlight_attempts=None):
    # The previous code to read data lines remains the same

    # Initialize grids with zeros for both metrics
    run_times_grid = np.zeros((num_rows, num_cols))
    timesteps_grid = np.zeros((num_rows, num_cols))

    # Process each data line to extract runtimes and timesteps
    for line in data_lines:
        # Previous code for extracting run time remains the same

        # Extract attempt path and get max timestep
        attempt_path = os.path.join('./output', name_variable + ':' + str(attempt + min_attempt))
        max_timestep = get_max_timestep(attempt_path)
        if max_timestep is not None:
            timesteps_grid[row_idx, col_idx] = max_timestep

        # Rest of the code for assigning runtimes and highlighting remains the same

    # Plot the heatmaps for both metrics
    fig, axes = plt.subplots(1, 2, figsize=(15, 6))

    cax1 = axes[0].imshow(run_times_grid, cmap='viridis', interpolation='nearest')
    cax2 = axes[1].imshow(timesteps_grid, cmap='plasma', interpolation='nearest')

    fig.colorbar(cax1, ax=axes[0], label='Runtime (log(seconds))')
    fig.colorbar(cax2, ax=axes[1], label='Max Timestep')

    # Other code for labels, ticks, and saving remains the same

# }}}

#}}}

# Highlighting the successful attempts {{{
def get_highlight_attempts(name_variable):
    highlight_attempts = []
    base_path = './output'

    # Iterate through the directories in the base path
    for directory in os.listdir(base_path):
        if directory.startswith(name_variable + ":"):
            # Extract the attempt number from the directory name
            attempt_number = int(directory.split(":")[1])
            attempt_path = os.path.join(base_path, directory)

            # Check if the directory contains the specified file
            if os.path.exists(os.path.join(attempt_path, 'snapshot_000.hdf5')):
                highlight_attempts.append(attempt_number)

    return highlight_attempts
#}}}

# Example usage
name_variable = '2023.08.18'
highlight_attempts = get_highlight_attempts(name_variable)
print(highlight_attempts)  # Output: [49, 50, 63, 99]


# Attempts to highlight
#highlight_attempts = [30, 39, 40]

plot_heatmap(parameters, attempt_range, highlight_attempts)

