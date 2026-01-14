#!/bin/bash

# Check if number of users is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <number_of_users>"
    echo "Example: $0 50"
    echo "  This will create canary releases for 50 users with 80% traffic to v1 and 20% traffic to v2"
    exit 1
fi

NUM_USERS=$1
TRAFFIC_v1=80
TRAFFIC_v2=20

# Validate that NUM_USERS is a positive integer
if ! [[ "$NUM_USERS" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: Number of users must be a positive integer"
    exit 1
fi

echo "Creating canary releases for users 1 to ${NUM_USERS}"
echo "Traffic distribution: v1=${TRAFFIC_v1}%, v2=${TRAFFIC_v2}%"
echo "=================================================================="
echo

# Iterate over all users
for i in $(seq 1 ${NUM_USERS}); do
    USERNAME="user${i}"
    
    echo "Processing ${USERNAME}..."
    echo "----------------------------------------"
    
    echo "  - Creating cars-vm-v2 VirtualMachine"
    oc apply -f - <<EOF
kind: VirtualMachine
apiVersion: kubevirt.io/v1
metadata:
  name: cars-vm-v2
  namespace: ${USERNAME}-travel-agency
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
              - su - fedora -c 'XDG_RUNTIME_DIR=/run/user/$(id -u) DBUS_SESSION_BUS_ADDRESS="unix:path=\${XDG_RUNTIME_DIR}/bus" systemctl --user daemon-reload'
              - su - fedora -c 'XDG_RUNTIME_DIR=/run/user/$(id -u) DBUS_SESSION_BUS_ADDRESS="unix:path=\${XDG_RUNTIME_DIR}/bus" systemctl --user start control.service'    
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
          name: cloudinitdisk
EOF
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Successfully created cars-vm-v2 VirtualMachine"
    else
        echo "  ✗ Failed to create cars-vm-v2 VirtualMachine"
    fi
    
    echo "  - Waiting 10 seconds for VM to initialize..."
    sleep 10
    
    echo "  - Creating cars DestinationRule"
    oc apply -f - <<EOF
kind: DestinationRule
apiVersion: networking.istio.io/v1
metadata:
  name: cars
  namespace: ${USERNAME}-travel-agency
spec:
  host: cars-vm.${USERNAME}-travel-agency.svc.cluster.local
  subsets:
    - labels:
        version: v1
      name: v1
    - labels:
        version: v2
      name: v2
EOF
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Successfully created cars DestinationRule"
    else
        echo "  ✗ Failed to create cars DestinationRule"
    fi
    
    echo "  - Creating cars VirtualService with traffic weights"
    oc apply -f - <<EOF
kind: VirtualService
apiVersion: networking.istio.io/v1alpha3
metadata:
  name: cars
  namespace: ${USERNAME}-travel-agency
spec:
  hosts:
    - cars-vm.${USERNAME}-travel-agency.svc.cluster.local
  http:
    - route:
        - destination:
            host: cars-vm.${USERNAME}-travel-agency.svc.cluster.local
            subset: v1
          weight: ${TRAFFIC_v1}
        - destination:
            host: cars-vm.${USERNAME}-travel-agency.svc.cluster.local
            subset: v2
          weight: ${TRAFFIC_v2}
EOF
    
    if [ $? -eq 0 ]; then
        echo "  ✓ Successfully created cars VirtualService"
    else
        echo "  ✗ Failed to create cars VirtualService"
    fi
    
    echo "  Completed ${USERNAME}"
    echo
done

echo "=================================================================="
echo "Completed creating canary releases for users 1 to ${NUM_USERS}"
echo "=================================================================="
