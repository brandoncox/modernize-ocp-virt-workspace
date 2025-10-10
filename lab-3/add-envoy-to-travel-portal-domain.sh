#!/bin/bash



echo 
echo "Add Deployments in the mesh by injecting Service Mesh sidecars to components"
echo "---------------------------------------------------------------------------------"
echo
oc patch deployment/travels --type=merge -p '{"spec":{"template":{"metadata":{"labels":{"sidecar.istio.io/inject": "true"}}}}}' -n travel-portal
oc patch deployment/viaggi --type=merge -p '{"spec":{"template":{"metadata":{"labels":{"sidecar.istio.io/inject": "true"}}}}}' -n travel-portal
oc patch deployment/voyages --type=merge -p '{"spec":{"template":{"metadata":{"labels":{"sidecar.istio.io/inject": "true"}}}}}' -n travel-portal

echo
echo
echo
sleep 3

oc get pods -n travel-portal