#!/usr/bin/env bash

# Verzeichnis, das die JSON-Dateien enthält
json_dir="./json/*.json"

current_date=$(date +"%Y-%m-%d")

for json_file in $json_dir; do
  if [[ -f "$json_file" ]]; then
    current_json_date=$(jq -r '.date_created' "$json_file")

    if [[ "$current_json_date" != "$current_date" ]]; then
      echo "Updating $json_file with date $current_date"
      jq --arg date "$current_date" '.date_created = $date' "$json_file" >temp.json && mv temp.json "$json_file"

      git add "$json_file"
      git commit -m "Update date_created to $current_date in $json_file"
    else
      echo "Date in $json_file is already up to date."
    fi
  fi
done
git push origin HEAD
