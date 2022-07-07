#!/bin/bash

#define parameters which are passed in.
NAME=$1

#define the template.
cat  << EOF
apiVersion: datapower.ibm.com/v1beta3
kind: DataPowerService
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "350"
  name: $NAME-instance
spec:
  replicas: 3
  version: 10.5-lts
  license:
    accept: true
    use: nonproduction
    license: L-RJON-CCCP46
  users:
  - name: admin
    accessLevel: privileged
    passwordSecret: datapower-user
  domains:
    - name: default
      certs:
      - certType: usrcerts
        secret: datapower-cert
      dpApp:
        config:
        - $NAME-default-cfg
        local:
        - $NAME-default-local
EOF
