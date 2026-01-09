#!/bin/bash

USERNAME=$(oc whoami)

echo
echo
echo "Add a circuit breaker for the cars-vm v2 to the cars DestinationRule"
echo "---------------------------------------------------------------------------------"
echo "kind: DestinationRule
apiVersion: networking.istio.io/v1
metadata:
  name: cars
spec:
  host: cars-vm.${USERNAME}-travel-agency.svc.cluster.local
  subsets:
    - labels:
        version: v1
      name: v1
    - labels:
        version: v2
      name: v2      
      trafficPolicy:
        connectionPool:
          http:
            http1MaxPendingRequests: 1
            maxRequestsPerConnection: 1
          tcp:
            maxConnections: 1
        outlierDetection:
          baseEjectionTime: 3m
          consecutive5xxErrors: 1
          interval: 1s
          maxEjectionPercent: 100" | oc  -n ${USERNAME}-travel-agency apply -f -
