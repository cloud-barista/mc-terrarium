#!/bin/bash

# Check if the script is being sourced
(return 0 2>/dev/null) && SOURCED=1 || SOURCED=0

if [ $SOURCED -eq 0 ]; then
    echo "Error: This script must be sourced to work properly."
    echo "Usage:"
    echo "  source $0"
    echo "  or"
    echo "  . $0"
    exit 1
fi

# Find the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Counter for loaded files
LOADED_COUNT=0
FAILED_COUNT=0

# Process each .env file
for ENV_FILE in "$SCRIPT_DIR"/*.env; do
    # Skip template files
    if [[ $(basename "$ENV_FILE") == template-* ]]; then
        echo "Skipping template file '${ENV_FILE##*/}'"
        continue
    fi

    if [ -f "$ENV_FILE" ]; then
        echo "Loading credential from '${ENV_FILE##*/}'"
        sed -i 's/\r$//' "$ENV_FILE"  # Remove carriage return characters
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Skip empty lines and comments
            if [[ -n "$line" && ! "$line" =~ ^# ]]; then
                # echo "Processing line: $line"  # Debugging line
                export "$line"        
                ((LOADED_COUNT++))    
            fi
        done < "$ENV_FILE"
        echo "Successfully loaded"
    else
        echo "Warning: $ENV_FILE not found"
        ((FAILED_COUNT++))
    fi
done

echo "----------------------------------------"
echo "Environment variables loading complete!"
echo "Successfully processed $LOADED_COUNT variables"
if [ $FAILED_COUNT -gt 0 ]; then
    echo "Failed to process $FAILED_COUNT files"
fi
