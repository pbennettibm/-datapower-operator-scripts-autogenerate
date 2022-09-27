#!/bin/bash

#define parameters which are passed in.
NAME=$1
PORT=$2

PORTSPLIT=$(echo $PORT | tr "-" "\n")

echo "$PORTSPLIT - testing"

#define the template.
cat  << EOF
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "370"
  name: $NAME-${PORTSPLIT[1]}-route
  namespace: $NAME
spec:
  to:
    kind: Service
    name: $NAME-service
    weight: 100
  port:
    targetPort: $NAME-${PORTSPLIT[1]}
  # tls:
  #  termination: passthrough
  # wildcardPolicy: None
EOF
