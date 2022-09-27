#!/bin/bash

#define parameters which are passed in.
NAME=$1
PORT=$2

#Bash
read -e -p "Do you need TLS enabled for Port ${Port}? (yes/no)" TLSBOOL
#Zsh
read -q "TLSBOOL?Do you need TLS enabled for Port ${Port} (yes/no)?"

TLSCHECK=$(
  if [ "$TLSBOOL" == "yes" ]; then
    echo "  tls:"
    echo "    termination: passthrough"
    echo "  wildcardPolicy: None"
  fi
)

#define the template.
cat  << EOF
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "370"
  name: $NAME-$PORT-route
  namespace: $NAME
spec:
  to:
    kind: Service
    name: $NAME-service
    weight: 100
  port:
    targetPort: $NAME-$PORT
$TLSCHECK
EOF
