#!/usr/bin/env bash

# Base directory for headers
headers_dir="./ct/headers"

# Ensure the headers directory exists and clear it
mkdir -p "$headers_dir"
rm -f "$headers_dir"/*

# Find all .sh files in ./ct directory, sorted alphabetically
find ./ct -type f -name "*.sh" | sort | while read -r script; do
  # Extract the APP name from the APP line
  app_name=$(grep -oP '^APP="\K[^"]+' "$script" 2>/dev/null)

  if [[ -n "$app_name" ]]; then
    # Define the output file name in the headers directory
    output_file="${headers_dir}/$(basename "${script%.*}")"

    # Generate figlet output
    figlet_output=$(figlet -f -w 500 slant "$app_name")

    # Check if figlet output is not empty
    if [[ -n "$figlet_output" ]]; then
      echo "$figlet_output" > "$output_file"
      echo "Generated: $output_file"
    else
      echo "Figlet failed for $app_name in $script"
    fi
  else
    echo "No APP name found in $script, skipping."
  fi
done

echo "Completed processing .sh files."
