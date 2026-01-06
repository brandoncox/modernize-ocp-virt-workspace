#!/bin/bash

TRAFFIC_v1=$1
TRAFFIC_v2=$2
USERNAME=$(oc whoami)

echo
echo
echo "Apply a Second cars-vm instance with v2"
echo "---------------------------------------------------------------------------------"
oc apply -f cars-vm-v2-a.yaml -n ${USERNAME}-travel-agency


sleep 3

echo
echo
echo "Create a cars Destination with multiple possible versions"
echo "---------------------------------------------------------------------------------"


echo "kind: DestinationRule
apiVersion: networking.istio.io/v1alpha3
metadata:
  name: cars
  namespace: ${USERNAME}-travel-agency
  labels:
    module: m4
spec:
  host: cars-vm.${USERNAME}-travel-agency.svc.cluster.local
  subsets:
    - labels:
        version: v1
      name: v1
    - labels:
        version: v2
      name: v2"|oc  -n ${USERNAME}-travel-agency apply -f -


echo "Create a weighted loadbalancer between cars v1 (90%) and v2 (10%) versions"
echo "--------------------------------------------------------------------------"

echo "kind: VirtualService
apiVersion: networking.istio.io/v1alpha3
metadata:
  name: cars
  namespace: ${USERNAME}-travel-agency
  labels:
    module: m4
spec:
  hosts:
    - cars-vm.${USERNAME}-travel-agency.svc.cluster.local
  gateways:
    - mesh
  http:
    - route:
        - destination:
            host: cars-vm.${USERNAME}-travel-agency.svc.cluster.local
            subset: v1
          weight: $TRAFFIC_v1
        - destination:
            host: cars-vm.${USERNAME}-travel-agency.svc.cluster.local
            subset: v2
          weight: $TRAFFIC_v2"


echo "kind: VirtualService
apiVersion: networking.istio.io/v1alpha3
metadata:
  name: cars
  namespace: ${USERNAME}-travel-agency
  labels:
    module: m4
spec:
  hosts:
    - cars-vm.${USERNAME}-travel-agency.svc.cluster.local
  gateways:
    - mesh
  http:
    - route:
        - destination:
            host: cars-vm.${USERNAME}-travel-agency.svc.cluster.local
            subset: v1
          weight: $TRAFFIC_v1
        - destination:
            host: cars-vm.${USERNAME}-travel-agency.svc.cluster.local
            subset: v2
          weight: $TRAFFIC_v2"|oc  -n ${USERNAME}-travel-agency apply -f -          
          
