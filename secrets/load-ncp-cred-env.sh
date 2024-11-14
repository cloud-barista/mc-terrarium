#!/bin/bash

# Find the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/credential-ncp.env"

# Check if .env file exists
if [[ -f "$ENV_FILE" ]]; then
    while IFS= read -r line; do
        if [[ -n "$line" && ! "$line" =~ ^# ]]; then
            eval export "$line"
        fi
    done < "$ENV_FILE"
    echo "successfully loaded the NCP credential environment variables"
else
    echo "error: dose not exist file, $ENV_FILE"
fi