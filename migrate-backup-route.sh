#!/bin/sh

#define parameters which are passed in.
NAME=$1

#define the template.
cat  << EOF
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  name: mpgw
  namespace: $NAME-route
spec:
  to:
    kind: Service
    name: $NAME-service
    weight: 100
  port:
    targetPort: mpgw
EOF
