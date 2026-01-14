#!/bin/bash

# Script to run all admin scripts in order
# Usage: ./run-all.sh <number_of_users>

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if number of users is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <number_of_users>"
    echo "Example: $0 7"
    exit 1
fi

NUM_USERS=$1

# Validate that NUM_USERS is a positive integer
if ! [[ "$NUM_USERS" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: Number of users must be a positive integer"
    exit 1
fi

# Validate if user is logged in as admin
if ! oc whoami &> /dev/null; then
    echo "Error: Not logged in to the cluster. Please run 'oc login' first."
    exit 1
fi

CURRENT_USER=$(oc whoami)
if [ "${CURRENT_USER}" != "admin" ]; then
    echo "Error: Must be logged in as 'admin'. Current user: ${CURRENT_USER}"
    exit 1
fi

echo "✓ Logged in as: ${CURRENT_USER}"
echo

echo "================================================================"
echo "Running all admin scripts for ${NUM_USERS} users"
echo "================================================================"
echo

# Array of scripts to run in order
SCRIPTS=(
    "01-add-services-to-mesh.sh"
    "02-add-canary-release.sh"
    "03-add-gitops-travel-control.sh"
    "04-validate-travel-service.sh"
)

# Run each script in order
for script in "${SCRIPTS[@]}"; do
    SCRIPT_PATH="${SCRIPT_DIR}/${script}"

    if [ ! -f "${SCRIPT_PATH}" ]; then
        echo "Error: Script ${script} not found!"
        exit 1
    fi

    echo "================================================================"
    echo "Running: ${script}"
    echo "================================================================"
    echo

    # Run the script with the number of users parameter
    "${SCRIPT_PATH}" "${NUM_USERS}"

    # Check exit status
    if [ $? -ne 0 ]; then
        echo
        echo "✗ Script ${script} failed!"
        echo
        echo "Aborting execution."
        exit 1
    else
        echo
        echo "✓ Script ${script} completed successfully"
        echo
    fi
done

echo "================================================================"
echo "All scripts completed successfully!"
echo "================================================================"
