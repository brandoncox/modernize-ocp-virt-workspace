#!/bin/bash

sleep 10


echo
echo "Update VirtualMachine CRs to include in the mesh by injecting Istio sidecars to components"
echo "------------------------------------------------------------------------------------------"
echo



oc patch VirtualMachine/cars-vm --type merge -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject": "true"}}}}}' -n travel-agency
oc patch VirtualMachine/cars-vm --type merge -p '{"spec":{"template":{"metadata":{"labels":{"sidecar.istio.io/inject": "true"}}}}}' -n travel-agency
oc delete pods -l vm.kubevirt.io/name=cars-vm -n travel-agency


oc patch VirtualMachine/discounts-vm --type merge -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject": "true"}}}}}' -n travel-agency
oc patch VirtualMachine/discounts-vm --type merge -p '{"spec":{"template":{"metadata":{"labels":{"sidecar.istio.io/inject": "true"}}}}}' -n travel-agency
oc delete pods -l vm.kubevirt.io/name=discounts-vm -n travel-agency


oc patch VirtualMachine/flights-vm --type merge -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject": "true"}}}}}' -n travel-agency
oc patch VirtualMachine/flights-vm --type merge -p '{"spec":{"template":{"metadata":{"labels":{"sidecar.istio.io/inject": "true"}}}}}' -n travel-agency
oc delete pods -l vm.kubevirt.io/name=flights-vm -n travel-agency


oc patch VirtualMachine/hotels-vm --type merge -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject": "true"}}}}}' -n travel-agency
oc patch VirtualMachine/hotels-vm --type merge -p '{"spec":{"template":{"metadata":{"labels":{"sidecar.istio.io/inject": "true"}}}}}' -n travel-agency
oc delete pods -l vm.kubevirt.io/name=hotels-vm -n travel-agency


oc patch VirtualMachine/insurances-vm --type merge -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject": "true"}}}}}' -n travel-agency
oc patch VirtualMachine/insurances-vm --type merge -p '{"spec":{"template":{"metadata":{"labels":{"sidecar.istio.io/inject": "true"}}}}}' -n travel-agency
oc delete pods -l vm.kubevirt.io/name=insurances-vm -n travel-agency


oc patch VirtualMachine/mysqldb-vm --type merge -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject": "true"}}}}}' -n travel-agency
oc patch VirtualMachine/mysqldb-vm --type merge -p '{"spec":{"template":{"metadata":{"labels":{"sidecar.istio.io/inject": "true"}}}}}' -n travel-agency
oc delete pods -l vm.kubevirt.io/name=mysqldb-vm -n travel-agency


oc patch VirtualMachine/travels-vm --type merge -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/inject": "true"}}}}}' -n travel-agency
oc patch VirtualMachine/travels-vm --type merge -p '{"spec":{"template":{"metadata":{"labels":{"sidecar.istio.io/inject": "true"}}}}}' -n travel-agency
oc delete pods -l vm.kubevirt.io/name=travels-vm -n travel-agency

echo
echo
echo
sleep 5

oc get pods -n travel-agency
