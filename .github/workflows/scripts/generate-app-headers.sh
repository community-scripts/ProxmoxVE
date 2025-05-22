#!/usr/bin/env bash

# Function for generating Figlet headers
generate_headers() {
  local base_dir=$1
  local target_subdir=$2
  local search_pattern=$3

  local headers_dir="${base_dir}/headers"
  mkdir -p "$headers_dir"
  rm -f "$headers_dir"/*

  # Recursive or non-recursive search
  if [[ "$search_pattern" == "**" ]]; then
    shopt -s globstar nullglob
    file_list=("${base_dir}"/**/*.sh)
    shopt -u globstar
  else
    file_list=("${base_dir}"/*.sh)
  fi

  for script in "${file_list[@]}"; do
    [[ -f "$script" ]] || continue

    app_name=$(grep -oP '^APP="\K[^"]+' "$script" 2>/dev/null)
    if [[ -n "$app_name" ]]; then
      output_file="${headers_dir}/$(basename "${script%.*}")"
      figlet_output=$(figlet -w 500 -f slant "$app_name")
      if [[ -n "$figlet_output" ]]; then
        echo "$figlet_output" >"$output_file"
        echo "Generated: $output_file"
      else
        echo "Figlet failed for $app_name in $script"
      fi
    else
      echo "No APP name found in $script, skipping."
    fi
  done
}

# ct
generate_headers "./ct" "headers" "*"

# tools (addon, pve, ...)
generate_headers "./tools" "headers" "**"

# vm
generate_headers "./vm" "headers" "*"

echo "Completed processing all sections."
