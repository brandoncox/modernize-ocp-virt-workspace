#!/bin/bash

# Check if number of users is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <number_of_users>"
    echo "Example: $0 50"
    exit 1
fi

NUM_USERS=$1

# Validate that NUM_USERS is a positive integer
if ! [[ "$NUM_USERS" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: Number of users must be a positive integer"
    exit 1
fi

echo "Executing lab-3 oc patch commands for users 1 to ${NUM_USERS}"
echo "=================================================================="
echo

# Iterate over all users
for i in $(seq 1 ${NUM_USERS}); do
    USERNAME="user${i}"
    
    echo "Processing ${USERNAME}..."
    echo "----------------------------------------"
    
    # Travel Portal Domain - Deployments
    echo "  - Patching deployments in ${USERNAME}-travel-portal"
    oc patch deployment/travels --type=merge -p '{"spec":{"template":{"metadata":{"labels":{"sidecar.istio.io/inject": "true"}}}}}' -n ${USERNAME}-travel-portal 2>/dev/null || echo "    Warning: deployment/travels not found or already patched"
    oc patch deployment/viaggi --type=merge -p '{"spec":{"template":{"metadata":{"labels":{"sidecar.istio.io/inject": "true"}}}}}' -n ${USERNAME}-travel-portal 2>/dev/null || echo "    Warning: deployment/viaggi not found or already patched"
    oc patch deployment/voyages --type=merge -p '{"spec":{"template":{"metadata":{"labels":{"sidecar.istio.io/inject": "true"}}}}}' -n ${USERNAME}-travel-portal 2>/dev/null || echo "    Warning: deployment/voyages not found or already patched"
    
    # Travel Control Domain - VirtualMachine
    echo "  - Patching VirtualMachine in ${USERNAME}-travel-control"
    oc patch VirtualMachine/control-vm --type=merge -p '{"spec":{"template":{"metadata":{"labels":{"sidecar.istio.io/inject": "true"}}}}}' -n ${USERNAME}-travel-control 2>/dev/null || echo "    Warning: VirtualMachine/control-vm not found or already patched"
    oc patch VirtualMachine/control-vm --type=merge -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject": "true"}}}}}' -n ${USERNAME}-travel-control 2>/dev/null || echo "    Warning: VirtualMachine/control-vm annotations not found or already patched"
    
    # Travel Agency Domain - VirtualMachines
    echo "  - Patching VirtualMachines in ${USERNAME}-travel-agency"
    # cars-vm
    oc patch VirtualMachine/cars-vm --type merge -p '{"spec":{"template":{"metadata":{"labels":{"sidecar.istio.io/inject": "true"}}}}}' -n ${USERNAME}-travel-agency 2>/dev/null || echo "    Warning: VirtualMachine/cars-vm not found or already patched"
    oc patch VirtualMachine/cars-vm --type merge -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject": "true"}}}}}' -n ${USERNAME}-travel-agency 2>/dev/null || echo "    Warning: VirtualMachine/cars-vm annotations not found or already patched"
    
    # discounts-vm
    oc patch VirtualMachine/discounts-vm --type merge -p '{"spec":{"template":{"metadata":{"labels":{"sidecar.istio.io/inject": "true"}}}}}' -n ${USERNAME}-travel-agency 2>/dev/null || echo "    Warning: VirtualMachine/discounts-vm not found or already patched"
    oc patch VirtualMachine/discounts-vm --type merge -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject": "true"}}}}}' -n ${USERNAME}-travel-agency 2>/dev/null || echo "    Warning: VirtualMachine/discounts-vm annotations not found or already patched"
    
    # flights-vm
    oc patch VirtualMachine/flights-vm --type merge -p '{"spec":{"template":{"metadata":{"labels":{"sidecar.istio.io/inject": "true"}}}}}' -n ${USERNAME}-travel-agency 2>/dev/null || echo "    Warning: VirtualMachine/flights-vm not found or already patched"
    oc patch VirtualMachine/flights-vm --type merge -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject": "true"}}}}}' -n ${USERNAME}-travel-agency 2>/dev/null || echo "    Warning: VirtualMachine/flights-vm annotations not found or already patched"
    
    # hotels-vm
    oc patch VirtualMachine/hotels-vm --type merge -p '{"spec":{"template":{"metadata":{"labels":{"sidecar.istio.io/inject": "true"}}}}}' -n ${USERNAME}-travel-agency 2>/dev/null || echo "    Warning: VirtualMachine/hotels-vm not found or already patched"
    oc patch VirtualMachine/hotels-vm --type merge -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject": "true"}}}}}' -n ${USERNAME}-travel-agency 2>/dev/null || echo "    Warning: VirtualMachine/hotels-vm annotations not found or already patched"
    
    # insurances-vm
    oc patch VirtualMachine/insurances-vm --type merge -p '{"spec":{"template":{"metadata":{"labels":{"sidecar.istio.io/inject": "true"}}}}}' -n ${USERNAME}-travel-agency 2>/dev/null || echo "    Warning: VirtualMachine/insurances-vm not found or already patched"
    oc patch VirtualMachine/insurances-vm --type merge -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject": "true"}}}}}' -n ${USERNAME}-travel-agency 2>/dev/null || echo "    Warning: VirtualMachine/insurances-vm annotations not found or already patched"
    
    # mysqldb-vm
    oc patch VirtualMachine/mysqldb-vm --type merge -p '{"spec":{"template":{"metadata":{"labels":{"sidecar.istio.io/inject": "true"}}}}}' -n ${USERNAME}-travel-agency 2>/dev/null || echo "    Warning: VirtualMachine/mysqldb-vm not found or already patched"
    oc patch VirtualMachine/mysqldb-vm --type merge -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject": "true"}}}}}' -n ${USERNAME}-travel-agency 2>/dev/null || echo "    Warning: VirtualMachine/mysqldb-vm annotations not found or already patched"
    
    # travels-vm
    oc patch VirtualMachine/travels-vm --type merge -p '{"spec":{"template":{"metadata":{"labels":{"sidecar.istio.io/inject": "true"}}}}}' -n ${USERNAME}-travel-agency 2>/dev/null || echo "    Warning: VirtualMachine/travels-vm not found or already patched"
    oc patch VirtualMachine/travels-vm --type merge -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject": "true"}}}}}' -n ${USERNAME}-travel-agency 2>/dev/null || echo "    Warning: VirtualMachine/travels-vm annotations not found or already patched"
    
    echo "  Completed ${USERNAME}"
    echo
done

echo "=================================================================="
echo "Completed patching all users (user1 to user${NUM_USERS})"
echo "=================================================================="
echo
echo "Deleting all pods in batch..."
echo "=================================================================="

# Delete all VM pods from travel-control and travel-agency namespaces
oc get pods --all-namespaces -l vm.kubevirt.io/name -o jsonpath='{range .items[*]}pod/{.metadata.name} -n {.metadata.namespace}{"\n"}{end}' | grep -E "travel-(control|agency)" | xargs -L1 oc delete --wait=false 2>/dev/null

echo "=================================================================="
echo "Completed deleting all pods for all users"
echo "=================================================================="

# Wait for all pods in travel-agency and travel-control namespaces to have 3 containers ready
echo "Waiting for pods to be ready with 3 containers..."
echo "=================================================================="

TIMEOUT=600  # 10 minutes in seconds
INTERVAL=10  # Check every 10 seconds
ELAPSED=0

while [ $ELAPSED -lt $TIMEOUT ]; do
    # Get all pods in one API call, filtering by namespace pattern
    POD_OUTPUT=$(oc get pods --all-namespaces -o wide 2>/dev/null | grep -E "travel-(control|agency)" | grep -v "travel-control-new" | grep -v "^NAMESPACE")
    
    # Extract READY column (3rd column) and check if all are 3/3
    NOT_READY=$(echo "$POD_OUTPUT" | awk '{if ($3 != "3/3" && $3 != "") print $1 " " $2 " " $3}')
    
    if [ -z "$NOT_READY" ]; then
        echo "All pods are ready with 3 containers!"
        break
    fi
    
    # Show pods that are not ready
    echo "  Pods not ready with 3/3:"
    echo "$NOT_READY" | awk '{print "    " $2 " in " $1 ": " $3}'
    
    echo "  Waiting 10 seconds... (elapsed: ${ELAPSED}s / ${TIMEOUT}s)"
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo "Warning: Timeout reached. Some pods may not be ready with 3 containers."
    echo "Current pod status:"
    oc get pods --all-namespaces -o wide 2>/dev/null | grep -E "travel-(control|agency)" | grep -v "travel-control-new" | grep -v "^NAMESPACE" | awk '{print "  " $2 " in " $1 ": " $3}'
fi

echo "=================================================================="
echo "Completed waiting for pods to be ready with 3 containers"
echo "=================================================================="
