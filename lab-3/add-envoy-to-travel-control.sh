echo 
echo "Update VirtualMachine CRs to include in the mesh by injecting Istio sidecars to components"
echo "------------------------------------------------------------------------------------------"
echo

VM_POOL_NAME=$(oc get VirtualMachine -o jsonpath='{.items[0].metadata.name}')
echo $VM_POOL_NAME

oc patch VirtualMachine/$VM_POOL_NAME --type=merge -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject": "true"}}}}}' -n travel-control
oc patch VirtualMachine/$VM_POOL_NAME --type=merge -p '{"spec":{"template":{"metadata":{"labels":{"sidecar.istio.io/inject": "true"}}}}}' -n travel-control
oc delete pods -l vm.kubevirt.io/name=$VM_POOL_NAME -n travel-control

echo
echo
echo
sleep 3

oc get pods -n travel-control