#!/bin/bash

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

echo "Validating travel service for users 1 to ${NUM_USERS}"
echo "=================================================================="
echo

SUCCESS_COUNT=0
FAIL_COUNT=0

# Iterate over all users
for i in $(seq 1 ${NUM_USERS}); do
    USERNAME="user${i}"
    
    echo "Processing ${USERNAME}..."
    echo "----------------------------------------"
    
    # Get the pod name
    POD_NAME=$(oc -n ${USERNAME}-travel-portal get po -l app=travels 2>/dev/null | awk '{print $1}' | tail -n 1)
    
    if [ -z "$POD_NAME" ]; then
        echo "  ✗ Failed: No pod found with label app=travels in ${USERNAME}-travel-portal"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo
        continue
    fi
    
    echo "  - Using pod: ${POD_NAME}"
    
    # Execute curl command and capture response
    RESPONSE=$(oc -n ${USERNAME}-travel-portal exec ${POD_NAME} -- curl -s travels-vm.${USERNAME}-travel-agency.svc.cluster.local:8000/travels/London 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$RESPONSE" ]; then
        echo "  ✗ Failed: curl command failed or returned empty response"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo
        continue
    fi
    
    # Extract status field from JSON response
    # Try using jq if available, otherwise fall back to grep/sed
    if command -v jq &> /dev/null; then
        STATUS=$(echo "$RESPONSE" | jq -r '.status' 2>/dev/null)
    else
        STATUS=$(echo "$RESPONSE" | grep -o '"status"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"status"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    fi
    
    if [ -z "$STATUS" ]; then
        echo "  ✗ Failed: Could not extract status field from response"
        echo "  Response: ${RESPONSE}"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo
        continue
    fi
    
    echo "  - Status found: ${STATUS}"
    
    # Validate that status equals "Valid"
    if [ "$STATUS" = "Valid" ]; then
        echo "  ✓ Success: Status is 'Valid'"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "  ✗ Failed: Status is '${STATUS}' but expected 'Valid'"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
    
    echo "  Completed ${USERNAME}"
    echo
done

echo "=================================================================="
echo "Validation Summary:"
echo "  Successful: ${SUCCESS_COUNT}/${NUM_USERS}"
echo "  Failed: ${FAIL_COUNT}/${NUM_USERS}"
echo "=================================================================="

# Exit with error if any validations failed
if [ $FAIL_COUNT -gt 0 ]; then
    exit 1
fi
