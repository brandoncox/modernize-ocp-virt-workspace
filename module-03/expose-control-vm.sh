#!/bin/bash

OCP_DOMAIN=$1
#OCP_DOMAIN=apps.cluster-szndb.dynamic.redhatworkshops.io
ISTIO_INGRESS_ROUTE_URL=istio-ingressgateway-istio-system.$OCP_DOMAIN
USERNAME=$(oc whoami)

echo
echo
echo "Applying initial Istio Configs to expose control to external Traffic via Service Mesh Ingress"
echo "---------------------------------------------------------------------------------------------"

echo "Service Mesh Ingress Gateway Route"
echo "Ingress Route [$ISTIO_INGRESS_ROUTE_URL]"
echo
                
echo
echo                
echo "kind: Gateway
apiVersion: networking.istio.io/v1alpha3
metadata:
  name: control-gateway
  namespace: istio-system
  labels:
    module: m3
spec:
  servers:
    - hosts:
        - $ISTIO_INGRESS_ROUTE_URL
      port:
        name: http
        number: 80
        protocol: HTTP
  selector:
    istio: ingressgateway"|oc -n istio-system apply -f -


          
echo "kind: VirtualService
apiVersion: networking.istio.io/v1alpha3
metadata:
  name: control
  namespace: ${USERNAME}-travel-control
  labels:
    module: m3
spec:
  hosts:
    - $ISTIO_INGRESS_ROUTE_URL
  gateways:
    - istio-system/control-gateway
  http:
    - route:
        - destination:
            host: control-vm.${USERNAME}-travel-control.svc.cluster.local
            subset: v1
          weight: 100"|oc  -n ${USERNAME}-travel-control apply -f -          
          
      
echo "kind: DestinationRule
apiVersion: networking.istio.io/v1alpha3
metadata:
  name: control
  namespace: ${USERNAME}-travel-control
  labels:
    module: m3  
spec:
  host: control-vm.${USERNAME}-travel-control.svc.cluster.local
  subsets:
    - labels:
        version: v1
      name: v1"|oc  -n ${USERNAME}-travel-control apply -f -

echo
echo "Go to http://$ISTIO_INGRESS_ROUTE_URL"
echo
echo
