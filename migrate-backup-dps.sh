#!/bin/sh

#define parameters which are passed in.
NAME=$1

#define the template.
cat  << EOF
apiVersion: datapower.ibm.com/v1beta3
kind: DataPowerService
metadata:
  name: $NAME-migration
spec:
  replicas: 3
  version: 10.0-cd
  license:
    accept: true
    use: nonproduction
    license: L-RJON-CCCP46
  users:
  - name: admin
    accessLevel: privileged
    passwordSecret: admin-credentials
  domains:
    - name: default
      certs:
      - certType: usrcerts
        secret: my-crypto-secret
      dpApp:
        config:
        - $NAME-default-cfg
        local:
        - $NAME-default-local
EOF
