#!/bin/bash

update_config() { #{{{
  config_file="./gizmo/Config.sh"

  # Loop through all arguments given to the function
  for parameter in "$@"; do
    # Check if the parameter starts with a dash, indicating deletion
    if [[ "$parameter" == -* ]]; then
      # Extract the key and delete it from the file
      key="${parameter#-}"
      sed -i "/^$key/d" "$config_file"
      continue
    fi

    # Check if the parameter contains an '=' sign
    if [[ "$parameter" == *"="* ]]; then
      # Split the parameter into key and value
      key="${parameter%=*}"
      value="${parameter#*=}"

      # Check if the key already exists in the file
      if grep -q "^$key=" "$config_file"; then
        # If the key exists, update the line with the new value
        sed -i "s/^$key=.*/$key=$value/" "$config_file"
      else
        # If the key does not exist, append the parameter to the file
        echo "$key=$value" >> "$config_file"
      fi
    else
      # Handle parameters without an '=' sign
      key="$parameter"

      # Check if the key already exists in the file
      if grep -q "^$key" "$config_file"; then
        # If the key exists, do nothing
        continue
      else
        # If the key does not exist, append the parameter to the file
        echo "$key" >> "$config_file"
      fi
    fi
  done
}
#}}}

compile_and_submit() { #{{{
  cd gizmo
  module load intel intelmpi gsl hdf5 fftw
  make clean
  make -j10
  cd ..
  ./autosub.sh
}
#}}}

configs=(
  "MULTIPLEDOMAINS=16"
  "MULTIPLEDOMAINS=32"
  "MULTIPLEDOMAINS=64"
)

# Main run {{{
for config in "${configs[@]}"; do
  update_config $config
  compile_and_submit
  echo "$config"
done
#}}}
