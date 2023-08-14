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


update_zel_params() {
  params_file="./zel.params"
  param_string="$1"

  # Split the parameter string by spaces
  IFS=' ' read -ra parameters <<< "$param_string"

  # Loop through all the parameters
  for parameter in "${parameters[@]}"; do
    # Check if the parameter starts with a dash, indicating deletion
    if [[ "$parameter" == -* ]]; then
      # Extract the key and delete it from the file (ignoring comments)
      key="${parameter#-}"
      sed -i "/^$key[[:space:]]/d" "$params_file"
      continue
    fi

    # Split the parameter into key and value
    key="${parameter%=*}"
    value="${parameter#*=}"

    # Check if the key already exists in the file (ignoring comments)
    if grep -q "^$key[[:space:]]" "$params_file"; then
      # If the key exists, update the line with the new value
      # Preserve comments at the end of the line
      sed -i "s/^\($key[[:space:]]*\).*\(\s*%.*\)*$/\1$value \2/" "$params_file"
    else
      # If the key does not exist, append the parameter to the file
      echo "$key$value" >> "$params_file"
    fi
  done
}

printf "\nExtracted parameters:\n"
printf "%s\n" "${parameters[@]}"
echo "Starting the update..."
for param_string in "${parameters[@]}"; do
  echo "$param_string"
  update_zel_params "$param_string"
done
