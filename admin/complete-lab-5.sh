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
echo

# check if number of all vms combined in userX-travel-control-new namespaces matches the number of users
# if not, try again after 10 seconds until timeout of 10 minutes.
echo "Waiting for VirtualMachines to be created..."
echo "=================================================================="

TIMEOUT=300  # 10 minutes in seconds
INTERVAL=10  # Check every 10 seconds
ELAPSED=0

while [ $ELAPSED -lt $TIMEOUT ]; do
    # Count all VirtualMachines in userX-travel-control-new namespaces
    VM_OUTPUT=$(oc get VirtualMachine --all-namespaces 2>/dev/null | grep "travel-control-new" | grep -v "^NAMESPACE")
    VM_COUNT=$(echo "$VM_OUTPUT" | grep -v "^$" | wc -l | tr -d ' ')
    
    if [ -z "$VM_COUNT" ] || [ "$VM_COUNT" = "0" ]; then
        VM_COUNT=0
    fi
    
    if [ "$VM_COUNT" -eq "$NUM_USERS" ]; then
        echo "✓ All ${VM_COUNT} VirtualMachines have been created!"
        break
    fi
    
    echo "  Found ${VM_COUNT}/${NUM_USERS} VirtualMachines. Waiting 10 seconds... (elapsed: ${ELAPSED}s / ${TIMEOUT}s)"
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo "Warning: Timeout reached. Expected ${NUM_USERS} VirtualMachines but found ${VM_COUNT}."
    echo "Current VirtualMachine status:"
    oc get VirtualMachine --all-namespaces 2>/dev/null | grep "travel-control-new" || echo "  No VirtualMachines found in travel-control-new namespaces"
fi

echo "=================================================================="
echo "VM verification completed"
echo "=================================================================="
