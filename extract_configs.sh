#!/bin/bash

# Declare empty arrays to store the configs and parameters
declare -a configs
declare -a parameters

# Read the configs.txt file line by line
while IFS= read -r line; do
  # Check if the line starts with "Config.sh:"
  if [[ $line == "Config.sh:"* ]]; then
    # Extract the part after "Config.sh:" and add it to the configs array
    configs+=("${line#Config.sh: }")
  # Check if the line starts with "zel.params:"
  elif [[ $line == "zel.params:"* ]]; then
    # Extract the part after "zel.params:" and add it to the parameters array
    parameters+=("${line#zel.params: }")
  fi
done < "configs.txt"

# Print the configs and parameters arrays to verify the result
printf "Extracted configs:\n"
printf "%s\n" "${configs[@]}"
printf "\nExtracted parameters:\n"
printf "%s\n" "${parameters[@]}"

