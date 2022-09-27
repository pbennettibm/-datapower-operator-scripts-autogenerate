#!/bin/bash

#define parameters which are passed in.
NAME=$1
PORT=$2

echo $Port
TLSBOOL=$(bash -c 'read -e -p "Do you want TLS enabled for the port above? (yes/no): " tmp; echo $tmp')

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
