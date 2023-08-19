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
def plot_heatmap(parameters, attempt_range=None, highlight_attempts=None):
    # Read the data lines from the file
    with open('./results.txt', 'r') as file:
        data_lines = [line.strip() for line in file.readlines()]

    # Filter attempts based on the given range
    if attempt_range:
        data_lines = [line for line in data_lines if attempt_range[0] <= int(line.split("=")[3]) <= attempt_range[1]]

    # Find the minimum attempt number for normalization
    min_attempt = min(int(line.split("=")[3]) for line in data_lines)

    # Normalize the highlight attempts by the minimum attempt number
    if highlight_attempts:
        highlight_attempts = [attempt - min_attempt for attempt in highlight_attempts]

    # Extract the parameter names and values
    param_names = list(parameters.keys())
    param_values = [parameters[name] for name in param_names]
    num_rows, num_cols = [len(values) for values in param_values]

    # Initialize a grid with zeros
    run_times_grid = np.zeros((num_rows, num_cols))

    # Process each data line to extract the runtimes
    for line in data_lines:
        parts = line.split()
        status = parts[0].replace(":", "")
        run_time_str = parts[2].split("=")[1]
        attempt = int(parts[3].split("=")[1]) - min_attempt

        # Skip attempts outside the specified range
        if attempt < 0 or attempt >= num_rows * num_cols:
            continue

        # Convert the run time to seconds
        run_time_seconds = int(run_time_str.split(":")[0]) * 3600 + int(run_time_str.split(":")[1]) * 60 + int(run_time_str.split(":")[2])
        run_time_seconds = np.log(run_time_seconds + zero_runtime_log_addition)

        # Calculate row and column indices
        row_idx = attempt // num_cols
        col_idx = attempt % num_cols

        # Assign the run time to the grid
        run_times_grid[row_idx, col_idx] = run_time_seconds if status == "Succeeded" else 0

        # Highlight the specified attempts
        if highlight_attempts and attempt in highlight_attempts:
            plt.gca().add_patch(plt.Rectangle((col_idx-0.5, row_idx-0.5), 1, 1, fill=False, edgecolor='red'))

    # Plot the heatmap
    plt.imshow(run_times_grid, cmap='viridis', interpolation='nearest')
    plt.colorbar(label='Runtime (log(seconds))')
    plt.xticks(np.arange(num_cols), param_values[1], rotation=45)
    plt.yticks(np.arange(num_rows), param_values[0])
    plt.xlabel(param_names[1])
    plt.ylabel(param_names[0])
    plt.title('Runtime Heatmap')

    # Add attempt numbers as text labels
    for i in range(num_rows):
        for j in range(num_cols):
            plt.text(j, i, str(min_attempt + i * num_cols + j), ha="center", va="center", color="w", fontsize=8)

    # Save the plot as a .png file
    plt.savefig('heatmap.png')

    # Show the plot
    plt.show()

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

