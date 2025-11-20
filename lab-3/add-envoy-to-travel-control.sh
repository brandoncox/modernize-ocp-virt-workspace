#!/bin/bash

echo 
echo "Update VirtualMachine CRs to include in the mesh by injecting Istio sidecars to components"
echo "------------------------------------------------------------------------------------------"
echo

USERNAME=$(oc whoami)

oc patch VirtualMachine/control-vm --type=merge -p '{"spec":{"template":{"metadata":{"labels":{"sidecar.istio.io/inject": "true"}}}}}' -n ${USERNAME}-travel-control
oc patch VirtualMachine/control-vm --type=merge -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject": "true"}}}}}' -n ${USERNAME}-travel-control
oc delete pods -l vm.kubevirt.io/name=control-vm -n ${USERNAME}-travel-control

echo
echo
echo
sleep 3

oc get pods -n ${USERNAME}-travel-control