#!/bin/bash

TRAFFIC_v1=$1
TRAFFIC_v2=$2
USERNAME=$(oc whoami)

echo
echo
echo "Create a second cars-vm instance with v2"
echo "---------------------------------------------------------------------------------"
echo "kind: VirtualMachine
apiVersion: kubevirt.io/v1
metadata:
  name: cars-vm-v2
spec:
  dataVolumeTemplates:
    - apiVersion: cdi.kubevirt.io/v1beta1
      kind: DataVolume
      metadata:
        name: fedora-cars-v2
      spec:
        sourceRef:
          kind: DataSource
          name: fedora
          namespace: openshift-virtualization-os-images
        storage:
          resources:
            requests:
              storage: 30Gi
  running: true
  template:
    metadata:
      annotations:
        vm.kubevirt.io/flavor: small
        vm.kubevirt.io/os: fedora
        vm.kubevirt.io/workload: server
        sidecar.istio.io/inject: 'true'
        istio.io/reroute-virtual-interfaces: "k6t-eth0"
      creationTimestamp: null
      labels:
        kubevirt.io/domain: cars-vm
        kubevirt.io/size: small
        app: cars-vm
        version: v2
        sidecar.istio.io/inject: 'true'
    spec:
      architecture: amd64
      domain:
        cpu:
          cores: 1
          sockets: 1
          threads: 1
        devices:
          disks:
            - disk:
                bus: virtio
              name: rootdisk
            - disk:
                bus: virtio
              name: cloudinitdisk
          interfaces:
            - masquerade: {}
              name: default
          rng: {}
        features:
          acpi: {}
          smm:
            enabled: true
        firmware:
          bootloader:
            efi: {}
        machine:
          type: pc-q35-rhel9.4.0
        memory:
          guest: 1Gi
        resources: {}
      networks:
        - name: default
          pod: {}
      terminationGracePeriodSeconds: 180
      volumes:
        - dataVolume:
            name: fedora-cars-v2
          name: rootdisk
        - cloudInitNoCloud:
            userData: |-
              #cloud-config
              user: fedora
              password: ukqo-2vq4-xdjf
              chpasswd: { expire: False }
              ssh_pwauth: true
              runcmd:
              - loginctl enable-linger fedora
              - su - fedora -c 'XDG_RUNTIME_DIR=/run/user/$(id -u) DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus" systemctl --user daemon-reload'
              - su - fedora -c 'XDG_RUNTIME_DIR=/run/user/$(id -u) DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus" systemctl --user start control.service'    
              write_files:
              - content: |
                  [Unit]
                  Description=Fedora Cars Container
                  [Container]
                  Label=app=cars-container
                  ContainerName=cars-container
                  Image=quay.io/kiali/demo_travels_cars:v1
                  Environment=CURRENT_SERVICE='cars'
                  Environment=CURRENT_VERSION='v1
                  Environment=LISTEN_ADDRESS=':8000'
                  Environment=MYSQL_SERVICE='mysqldb-vm.${USERNAME}-travel-agency.svc.cluster.local:3306'
                  Environment=MYSQL_USER='root'
                  Environment=MYSQL_PASSWORD='mysqldbpass'
                  Environment=DISCOUNTS_SERVICE='http://discounts-vm.${USERNAME}-travel-agency.svc.cluster.local:8000'
                  Environment=MYSQL_DATABASE='test'
                  PodmanArgs=-p 8000:8000
                  [Install]
                  WantedBy=multi-user.target default.target
                  [Service]
                  Restart=always
                path: /etc/containers/systemd/users/cars.container
                permissions: '0777'
                owner: root:root
          name: cloudinitdisk" | oc  -n ${USERNAME}-travel-agency apply -f -

sleep 10

echo
echo
echo "Create a cars Destination with multiple possible versions"
echo "---------------------------------------------------------------------------------"

echo "kind: DestinationRule
kind: DestinationRule
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
      name: v2" | oc  -n ${USERNAME}-travel-agency apply -f -


echo "Create a weighted loadbalancer (VirtualService) v1 and v2 versions"
echo "--------------------------------------------------------------------------"

echo "kind: VirtualService
apiVersion: networking.istio.io/v1alpha3
metadata:
  name: cars
spec:
  hosts:
    - cars-vm.${USERNAME}-travel-agency.svc.cluster.local
  http:
    - route:
        - destination:
            host: cars-vm.${USERNAME}-travel-agency.svc.cluster.local
            subset: v1
          weight: $TRAFFIC_v1
        - destination:
            host: cars-vm.${USERNAME}-travel-agency.svc.cluster.local
            subset: v2
          weight: $TRAFFIC_v2" | oc -n ${USERNAME}-travel-agency apply -f -
