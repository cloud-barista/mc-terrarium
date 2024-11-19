#!/bin/bash

# Find the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/credential-ncp.env"

echo "ENV_FILE: $ENV_FILE"

# Check if .env file exists
if [[ -f "$ENV_FILE" ]]; then
    sed -i 's/\r$//' "$ENV_FILE"  # Remove carriage return characters
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        if [[ -n "$line" && ! "$line" =~ ^# ]]; then
            # echo "Processing line: $line"  # Debugging line
            export "$line"            
        fi
    done < "$ENV_FILE"
    echo "successfully loaded the NCP credential environment variables"
else
    echo "error: does not exist file, $ENV_FILE"
fi