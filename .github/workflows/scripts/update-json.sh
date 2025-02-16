#!/bin/bash

FILE=$1
TODAY=$(date -u +"%Y-%m-%d")

if [[ -z "$FILE" ]]; then
    echo "No file specified. Exiting."
    exit 1
fi

if [[ ! -f "$FILE" ]]; then
    echo "File $FILE not found. Exiting."
    exit 1
fi

DATE_IN_JSON=$(jq -r '.date_created' "$FILE" 2>/dev/null || echo "")

if [[ "$DATE_IN_JSON" != "$TODAY" ]]; then
    jq --arg date "$TODAY" '.date_created = $date' "$FILE" > tmp.json && mv tmp.json "$FILE"
fi
