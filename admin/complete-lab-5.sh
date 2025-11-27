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

echo "Applying application-travel-control.yaml to namespaces user1-travel-control-new to user${NUM_USERS}-travel-control-new"
echo "=================================================================="
echo

# Iterate over all users
for i in $(seq 1 ${NUM_USERS}); do
    USERNAME="user${i}"
    NAMESPACE="${USERNAME}-travel-control-new"
    
    echo "Processing ${NAMESPACE}..."
    echo "----------------------------------------"
    
    # Check if namespace exists
    if ! oc get namespace "${NAMESPACE}" &>/dev/null; then
        echo "  Warning: Namespace ${NAMESPACE} does not exist, skipping..."
        echo
        continue
    fi
    
    # Apply the application YAML with namespace and username substitution
    oc apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: travel-control
  namespace: ${NAMESPACE}
spec:
  project: default
  source:
    path: lab-5/travel-control
    repoURL: https://github.com/rhpds/modernize-ocp-virt-workspace.git
    targetRevision: HEAD
    helm:
      parameters:
        - name: username
          value: ${USERNAME}
  destination:
    server: https://kubernetes.default.svc
  syncPolicy:
    automated: {}
EOF
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Successfully applied application to ${NAMESPACE}"
    else
        echo "  ✗ Failed to apply application to ${NAMESPACE}"
    fi
    echo
done

echo "=================================================================="
echo "Completed applying application-travel-control.yaml for users 1 to ${NUM_USERS}"
echo "=================================================================="

