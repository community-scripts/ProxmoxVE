#!/usr/bin/env bash

# Find all .sh files in ./ct directory, sorted alphabetically
find ./ct -type f -name "*.sh" | sort | while read -r script; do
  # Extract the APP name from the APP line
  app_name=$(grep -oP '^APP="\K[^"]+' "$script" 2>/dev/null)

  if [[ -n "$app_name" ]]; then
    # Define the output file name based on the .sh file
    output_file="${script%.sh}.app"

    # Check if the output file already exists
    if [[ ! -f "$output_file" ]]; then
      # Generate figlet output
      figlet_output=$(figlet -f slant "$app_name")

      # Check if figlet output is not empty
      if [[ -n "$figlet_output" ]]; then
        echo "$figlet_output" > "$output_file"
        echo "Generated: $output_file"
      else
        echo "Figlet failed for $app_name in $script"
      fi
    else
      echo "Skipped: $output_file already exists"
    fi
  else
    echo "No APP name found in $script, skipping."
  fi
done

echo "Completed processing .sh files."
